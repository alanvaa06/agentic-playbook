---
name: self-refine
description: Implements the Self-Refine algorithm for iterative output improvement through self-feedback. Use when the user requests iterative code refinement, self-correcting generation, output polishing, or explicitly mentions Self-Refine.
---

# Self-Refine

## Core Philosophy
Self-Refine uses a **single LLM** to iteratively improve its own output through a FEEDBACK-REFINE loop. The model generates an initial output, critiques it with specific, actionable feedback, then refines the output based on that critique. This cycle repeats until a stopping condition is met (quality threshold or max iterations). No additional training, fine-tuning, or external tools are required.

## Trigger Scenarios
✅ **WHEN to use it:**
- Code generation tasks where the first draft may contain logic errors, missing edge cases, or style issues
- Trading strategy scripts that need iterative validation of signal correctness and return computation
- Text generation tasks (summaries, reports) where quality improves with structured self-critique
- Any single-output task where "generate once" is insufficient and iterative polish adds value

❌ **WHEN NOT to use it:**
- Tasks requiring factual verification against external sources (use `.cursor/skills/cove/SKILL.md` instead)
- Multi-agent collaborative workflows (use CrewAI or AutoGen)
- RAG pipelines where the problem is retrieval quality, not generation quality (use CRAG)
- Tasks where the first output is already high quality and iteration adds no value (simple lookups, data formatting)

## Pros vs Cons
- **Pros:** 5-40% improvement over single-shot generation (per the original paper), no fine-tuning needed, works with any LLM, transparent feedback is visible and debuggable, lightweight (no graph frameworks required)
- **Cons:** Feedback quality is the bottleneck (vague feedback leads to no improvement), each iteration adds latency and token cost, may converge to a local optimum if the feedback prompt is too narrow, risk of infinite loops without a max iteration guard

## The FEEDBACK-REFINE Loop

```
UserRequest
    │
    ▼
┌──────────────────┐
│ GENERATE         │ ← Produce initial output
│ (iteration 0)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ FEEDBACK         │ ← Critique the output with specific,
│                  │   actionable observations
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
  "STOP"   Issues Found
    │         │
    ▼         ▼
  Return   ┌──────────────────┐
  Output   │ REFINE           │ ← Improve output based on feedback
           │ (iteration n+1)  │
           └────────┬─────────┘
                    │
                    ▼
              Back to FEEDBACK
              (until STOP or max_iterations)
```

## Implementation Template

```python
# Input: "Implement a momentum trading strategy for NVIDIA using 20-day and 50-day moving averages"
# Expected Output: Refined Python code after 3 iterations of generate-feedback-refine

from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import AIMessage, HumanMessage

llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0.2)

generate_prompt = ChatPromptTemplate.from_messages([
    ("system",
     "You are a Python code generator specialized in quantitative finance. "
     "Produce clean, executable code only. No explanations outside the code."),
    MessagesPlaceholder(variable_name="messages"),
])
generate = generate_prompt | llm

feedback_prompt = ChatPromptTemplate.from_messages([
    ("system",
     "You are a code reviewer. Evaluate the code for:\n"
     "1. Executability: Will it run without errors? Are all imports valid?\n"
     "2. Correctness: Are moving averages, signals, and returns computed correctly?\n"
     "3. Edge cases: Does it handle missing data, empty DataFrames, or date issues?\n"
     "4. Style: Is it clean and PEP 8 compliant?\n\n"
     "If ALL criteria pass, respond with exactly: STOP\n"
     "Otherwise, provide specific, actionable feedback with line references."),
    MessagesPlaceholder(variable_name="messages"),
])
feedback = feedback_prompt | llm

MAX_ITERATIONS = 3

request = HumanMessage(
    content="Implement a momentum trading strategy for NVIDIA using "
            "20-day and 50-day moving averages. Use yfinance for data. "
            "Compute buy/sell signals and cumulative return."
)

# Step 1: Initial generation
code = generate.invoke({"messages": [request]}).content

for i in range(MAX_ITERATIONS):
    print(f"--- Iteration {i + 1} ---")

    # Step 2: Get feedback
    critique = feedback.invoke({
        "messages": [request, HumanMessage(content=code)]
    }).content

    if "STOP" in critique.upper():
        print("Feedback says STOP — code approved.")
        break

    print(f"Feedback: {critique[:200]}...")

    # Step 3: Refine based on feedback
    code = generate.invoke({
        "messages": [
            request,
            AIMessage(content=code),
            HumanMessage(content=critique),
        ]
    }).content

print("--- FINAL CODE ---")
print(code)
```

### Pure Python Variant (No LangChain)

```python
# Minimal implementation using the Anthropic client directly

import anthropic

client = anthropic.Anthropic()
MODEL = "claude-3-5-sonnet-20241022"
MAX_ITERATIONS = 3

def llm_call(system: str, user: str) -> str:
    response = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        temperature=0.2,
        system=system,
        messages=[{"role": "user", "content": user}],
    )
    return response.content[0].text

task = "Implement a momentum trading strategy for NVIDIA with moving averages."

code = llm_call(
    system="You are a Python code generator. Output only executable code.",
    user=task,
)

for i in range(MAX_ITERATIONS):
    critique = llm_call(
        system=(
            "You are a code reviewer. If the code is correct, respond STOP. "
            "Otherwise give specific, actionable feedback."
        ),
        user=f"Task: {task}\n\nCode:\n{code}",
    )

    if "STOP" in critique.upper():
        break

    code = llm_call(
        system="You are a Python code generator. Improve the code based on the feedback.",
        user=f"Task: {task}\n\nPrevious code:\n{code}\n\nFeedback:\n{critique}",
    )

print(code)
```

## Common Pitfalls
- **Vague feedback prompts:** If the feedback prompt says "review this code" without specific criteria, the model returns generic praise and no actual improvement occurs. Always list explicit evaluation axes (executability, correctness, edge cases).
- **Missing STOP condition:** Without a clear stopping signal, the loop runs for all `MAX_ITERATIONS` even when the code is already correct. Instruct the feedback model to output "STOP" when all criteria pass.
- **Feedback quality is the bottleneck:** The paper shows that most Self-Refine failures come from inaccurate feedback, not from the refinement step. Invest more prompt engineering effort in the FEEDBACK prompt than in the REFINE prompt.
- **Hallucinated methods:** Explicitly instruct the generator to avoid non-existent methods like `np.rolling()` or `pd.rolling()` (these do not exist; the correct call is `df['col'].rolling()`).
- **No iteration cap:** Always set `MAX_ITERATIONS` to prevent runaway loops. 3 iterations is a good default; diminishing returns are typical after 2-3 rounds.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this pattern, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- The feedback model returning "STOP" prematurely on broken code
- Refinement producing worse code than the previous iteration (regression)
- The loop exhausting `MAX_ITERATIONS` without converging on correct code
