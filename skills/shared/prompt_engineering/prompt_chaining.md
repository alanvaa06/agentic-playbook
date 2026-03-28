# Prompt Chaining

**Domain:** Prompt Engineering
**Loaded when:** The task involves a complex, multi-part request that requires sequential LLM steps with structured intermediate outputs.

---

## When to Use

- The user's request has 3+ distinct sub-tasks that must be solved in sequence (e.g., "extract data, then analyze, then summarize").
- Each step produces structured output that feeds into the next step.
- Quality gates between steps are needed to catch errors early.

## When NOT to Use

- The task is a single-step operation (e.g., "summarize this text").
- The sub-tasks are independent and can run in parallel — use subagents instead.
- The task requires real-time interaction or streaming output at every stage.

---

## Core Rules

1. **Decompose before executing.** Analyze the user's request and break it into 3–5 numbered steps before producing any output. Each step must specify its Input, Output, and Model/Tool.
2. **One step at a time.** Execute only one step per cycle. Present the result and wait for approval before proceeding. Never batch multiple steps into a single response.
3. **Structured intermediate outputs.** Every step must produce machine-parseable output (preferably JSON). This makes results auditable and allows downstream steps to consume data reliably.
4. **Clean LLM artifacts between steps.** Strip markdown code fences, trailing whitespace, and formatting artifacts from JSON outputs before passing data to the next step. Malformed JSON propagates errors through the entire chain.
5. **Label everything explicitly.** Every step output must include: step number, step title, what was fed in, what was produced, and a status indicator.
6. **Gate each transition.** Ask the user to approve before advancing to the next step. This prevents wasted work when the decomposition is wrong.
7. **Consolidate at the end.** After all steps complete, present a final assembly showing the original request, each step's output, and the combined result.
8. **Retry failed steps in place.** If a step produces malformed output or an error, re-execute that specific step (up to 2 retries) before asking the user for guidance. Never skip a failed step.

---

## Code Patterns

### Step decomposition plan

Present this to the user before executing anything.

```text
I will break this into a 3-step chain:

- **Step 1:** [Description]
  - Input: [What this step receives]
  - Output: [Structured data this step produces]
  - Model/Tool: [Which LLM or API]

- **Step 2:** [Description]
  - Input: Output from Step 1
  - Output: [Structured data]
  - Model/Tool: [Which LLM or API]

- **Step 3:** [Description]
  - Input: Output from Step 2
  - Output: [Final result]
  - Model/Tool: [Which LLM or API]

Do you approve this plan? (Y/N)
```

### Step execution template

Use this exact format for each step's output.

```text
## Step [N]: [Step Title]

**Input:** [What was fed into this step]

**Processing:** [Brief description of what the LLM/tool did]

**Output:**
```json
{
  "key": "structured result here"
}
```

**Status:** Complete

---

Proceed to Step [N+1]? (Y/N)
```

### Final assembly template

```text
## Chain Complete

**Original Request:** [User's original prompt]

**Step 1 Output:** [Summary or key data]
**Step 2 Output:** [Summary or key data]
**Step 3 Output:** [Summary or key data]

**Final Result:**
[Consolidated answer combining all step outputs]
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Solve a multi-part task in a single response | Decompose into 3–5 sequential steps | Single-response attempts hallucinate more on complex tasks; chaining isolates errors |
| Pass raw LLM text between steps | Clean and parse to JSON first | Markdown fences and trailing whitespace cause JSON parse failures in downstream steps |
| Proceed without user approval | Stop and wait after each step | Wrong decomposition wastes all subsequent steps; early approval catches mistakes |
| Skip a failed step and continue | Retry the failed step up to 2 times | Downstream steps depend on upstream output; skipping propagates garbage data |
| Use vague step descriptions like "Process the data" | Specify exact input/output/tool per step | Vague steps give the LLM too much freedom; precise specs constrain hallucination |
| Batch all steps into one execution | One step per cycle, then wait | Batching removes the quality gate that makes chaining valuable |

---

## Verification Checklist

Before marking a chained task as done, confirm:

- [ ] The decomposition plan was presented and approved before any execution
- [ ] Each step produced structured (JSON) output, not free-form prose
- [ ] LLM artifacts (code fences, trailing whitespace) were stripped between steps
- [ ] Each step was approved before advancing to the next
- [ ] Failed steps were retried (up to 2 times) before escalating
- [ ] A final consolidated summary was presented after all steps completed
