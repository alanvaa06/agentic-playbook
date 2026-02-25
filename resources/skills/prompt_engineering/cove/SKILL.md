---
name: cove
description: Implements Chain-of-Verification (CoVe) to reduce hallucinations in LLM outputs by generating verification questions and answering them independently. Use when the user requests fact-checking, hallucination reduction, verified content generation, or explicitly mentions CoVe or Chain of Verification.
---

# Chain-of-Verification (CoVe)

## Core Philosophy
CoVe reduces hallucinations by forcing the LLM to **verify its own claims before presenting them**. After generating an initial response, the model plans verification questions, answers them *independently* (without seeing the original response), and revises the output based on verified facts. It uses a single LLM with no fine-tuning required.

## Trigger Scenarios
✅ **WHEN to use it:**
- Generating factual lists, biographies, financial summaries, or historical timelines where accuracy is critical
- Closed-book Q&A where the LLM has no external retrieval and must rely on parametric knowledge
- Post-processing RAG outputs to verify that the generated answer is consistent with itself
- Any task where the user explicitly requests reduced hallucination without adding external search

❌ **WHEN NOT to use it:**
- Creative writing or brainstorming tasks where factual accuracy is irrelevant
- Low-latency real-time applications (CoVe requires 4 sequential LLM calls minimum)
- When external retrieval (RAG/CRAG) already provides trusted context — use `.cursor/skills/crag/SKILL.md` instead
- Simple code generation tasks (use `.cursor/skills/self-refine/SKILL.md` instead)

## Pros vs Cons
- **Pros:** Significantly reduces hallucinated facts, prevents the model from copying its own mistakes (by hiding the baseline during verification), requires only prompt engineering (no fine-tuning), works with any LLM
- **Cons:** High token usage and latency (4+ LLM calls per query), requires structured output parsing for the verification plan, the "Factored" approach multiplies calls by the number of verification questions

## The 4-Step Process

```
UserQuery
    │
    ▼
┌──────────────────┐
│ 1. Generate      │ ← Produce initial baseline response
│    Baseline      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 2. Plan          │ ← Generate verification questions
│    Verifications │   about the baseline
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 3. Execute       │ ← Answer each question INDEPENDENTLY
│    Verifications │   (baseline is NOT provided here)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 4. Revise        │ ← Cross-check baseline against verified
│    Response      │   answers, correct inconsistencies
└──────────────────┘
```

## Verification Execution Approaches

| Approach | Description | Quality | Cost |
|----------|-------------|---------|------|
| **Joint** | Steps 2+3 in a single prompt with the baseline visible | Low — repeats original hallucinations | Lowest |
| **Two-Step** | Separate prompts, but all questions answered at once without baseline | Medium | Medium |
| **Factored** (recommended) | Each question answered as a separate prompt without baseline | High — prevents cross-contamination | Higher |
| **Factor+Revise** | Factored + explicit inconsistency detection step before final revision | Highest | Highest |

Default to the **Factored** approach unless the user explicitly requests otherwise.

## Implementation Template

```python
# Input: "Who are some politicians who were born in Boston?"
# Expected Output: A fact-checked list with hallucinated entries removed

from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import PromptTemplate

llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0)

# --- Step 1: Generate Baseline ---
baseline_prompt = PromptTemplate.from_template(
    "Answer the following query thoroughly:\n{query}"
)
baseline_chain = baseline_prompt | llm

query = "Who are some politicians who were born in Boston?"
baseline = baseline_chain.invoke({"query": query}).content

# --- Step 2: Plan Verifications ---
plan_prompt = PromptTemplate.from_template(
    "Given this query and response, generate a numbered list of specific, "
    "factual verification questions that would help detect any errors.\n\n"
    "Query: {query}\n"
    "Response: {baseline}\n\n"
    "Verification questions (one per line, numbered):"
)
plan_chain = plan_prompt | llm
plan_output = plan_chain.invoke({"query": query, "baseline": baseline}).content

import re
questions = [
    re.sub(r"^\d+[).\s]+", "", q).strip()
    for q in plan_output.strip().split("\n")
    if q.strip()
]

# --- Step 3: Execute Verifications (Factored — no baseline provided) ---
verify_prompt = PromptTemplate.from_template(
    "Answer the following question factually and concisely:\n{question}"
)
verify_chain = verify_prompt | llm

verified_facts = []
for question in questions:
    answer = verify_chain.invoke({"question": question}).content
    verified_facts.append({"question": question, "answer": answer})

# --- Step 4: Generate Final Verified Response ---
facts_str = "\n".join(
    [f"Q: {f['question']}\nA: {f['answer']}" for f in verified_facts]
)

revise_prompt = PromptTemplate.from_template(
    "You previously answered a query. We have independently verified some facts.\n"
    "Revise your original response to correct any inconsistencies.\n"
    "Remove any claims that contradict the verified facts.\n\n"
    "Query: {query}\n"
    "Original Response: {baseline}\n\n"
    "Verified Facts:\n{facts}\n\n"
    "Final Verified Response:"
)
revise_chain = revise_prompt | llm
final = revise_chain.invoke({
    "query": query,
    "baseline": baseline,
    "facts": facts_str
}).content

print(final)
```

## Common Pitfalls
- **Using the Joint approach instead of Factored:** If you include the baseline response in Step 3, the LLM will agree with its own hallucination. Always hide the baseline during verification execution.
- **Too many verification questions:** Generating 10+ questions causes latency and cost to explode. Guide the model in Step 2 to produce 3-5 critical questions maximum.
- **Parsing failures in Step 2:** The model may return questions in inconsistent formats. Use regex cleanup (as shown above) or structured output with Pydantic for robustness.
- **Skipping Step 4:** Simply listing verified facts is not enough. The revision step must explicitly cross-check the baseline against the verified answers to detect and remove inconsistencies.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this pattern, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- The LLM failing to generate parseable verification questions in Step 2
- The final response still containing a hallucination that was flagged in Step 3
- Token usage exceeding expectations due to an excessive number of verification questions
