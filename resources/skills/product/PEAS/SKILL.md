---
name: peas
description: "Generate an Agent Design Document using the PEAS framework (Performance, Environment, Actuators, Sensors). Use when designing a new AI agent, specifying agent behavior, or planning an agentic system. Triggers on: design an agent, create agent spec, peas analysis, agent design document, specify agent behavior."
user-invocable: true
---

# PEAS Agent Design — Agentic Specification Framework

Produce a structured Agent Design Document that fully specifies an AI agent's behavior, constraints, and evaluation criteria before any architecture or code is written. The output feeds directly into the Agentic AI Architect (`resources/agents/architects/agentic_ai_architect.md`) for pattern selection and implementation.

---

## The Job

1. **Read `tasks/todo.md`** to understand what has already been built
2. **Read `tasks/self-correction.md`** to absorb past lessons about agent design mistakes
3. Receive an agent description or problem statement from the user
4. Ask 4 rounds of discovery questions (one per PEAS dimension), **STOP AND WAIT** after each round
5. Generate the Agent Design Document from the answers
6. Save to `tasks/agent-design-[agent-name].md`

**Important:** Do NOT start implementing. Do NOT select frameworks or write code. Just produce the specification. Architecture decisions belong to the Agentic AI Architect.

---

## Step 1: Discovery Questions — Performance

Ask these questions and **STOP AND WAIT** for answers before proceeding to Step 2.

```
## Performance — How do we measure success?

1. What does a single successful agent run look like?
   A. A task is completed (e.g., code written, file created, data processed)
   B. A question is answered with a grounded, cited response
   C. A decision is made and a recommended action is produced
   D. An evaluation or score is generated for existing work
   E. Other: [please specify]

2. How should output quality be measured?
   A. Automated evaluation (LLM judge scoring against a rubric)
   B. Human review (analyst or developer verifies output)
   C. Programmatic validation (tests pass, API returns 200, schema validates)
   D. Comparison against a gold-standard dataset
   E. Other: [please specify]

3. What are the hard performance limits?
   A. Latency: must respond within seconds (interactive)
   B. Latency: minutes are acceptable (batch processing)
   C. Cost: must minimize LLM API calls (budget-constrained)
   D. Cost: quality over cost (accuracy is paramount)
   E. Other: [please specify]

4. Must the agent explain its reasoning?
   A. Yes — chain-of-thought or citations are required in every response
   B. Partially — reasoning for key decisions only
   C. No — only the final output matters
```

---

## Step 2: Discovery Questions — Environment

Ask these questions and **STOP AND WAIT** for answers before proceeding to Step 3.

```
## Environment — What world does this agent operate in?

5. How much of the relevant information can the agent see?
   A. Fully observable — the agent has access to all data it needs
   B. Partially observable — some information is missing, uncertain, or must be retrieved
   C. Depends on the query — sometimes full, sometimes partial

6. Does the environment change while the agent is working?
   A. Static — data does not change during a single run
   B. Dynamic — external state can change (new messages, updated records, live APIs)
   C. Semi-dynamic — data is stable per run but changes between runs

7. How are tasks structured?
   A. Episodic — each task is independent; no memory of prior tasks needed
   B. Sequential — prior task outcomes affect future decisions
   C. Mixed — mostly episodic, but some tasks build on earlier context

8. Does this agent work alone or with others?
   A. Single agent — operates independently
   B. Multi-agent coordinator — delegates subtasks to other agents
   C. Multi-agent participant — receives tasks from a coordinator agent
   D. Peer-to-peer — collaborates with agents at the same level
```

---

## Step 3: Discovery Questions — Actuators

Ask these questions and **STOP AND WAIT** for answers before proceeding to Step 4.

```
## Actuators — What can this agent do?

9. What actions can the agent perform? (select all that apply)
   A. Read and analyze documents (PDFs, markdown, code files)
   B. Call external APIs (search, databases, third-party services)
   C. Write or modify files (code, configs, documentation)
   D. Execute code or run commands (shell, tests, linters)
   E. Send messages or notifications (email, Slack, webhooks)
   F. Spawn or delegate to sub-agents
   G. Other: [please specify]

10. Are any actions irreversible or high-risk?
    A. No — all actions can be undone (read-only, or creates new files only)
    B. Yes — some actions modify existing data (database writes, file overwrites)
    C. Yes — some actions have external side effects (API calls, payments, emails)
    D. Yes — destructive actions are possible (delete records, drop tables)

11. Should the agent require human confirmation before acting?
    A. Never — fully autonomous
    B. Only for irreversible or high-risk actions (from Q10)
    C. At key checkpoints (e.g., after planning, before executing)
    D. Always — every action requires approval
```

---

## Step 4: Discovery Questions — Sensors

Ask these questions and **STOP AND WAIT** for answers before proceeding to output generation.

```
## Sensors — What inputs does this agent receive?

12. What are the primary input types? (select all that apply)
    A. Natural language text (user messages, queries)
    B. Structured data (JSON, CSV, database records)
    C. Documents (PDFs, images, charts, spreadsheets)
    D. Code files (source code, configs, test output)
    E. Events (webhooks, system triggers, cron schedules)
    F. Other agent outputs (delegated task results)
    G. Other: [please specify]

13. How reliable are the inputs?
    A. Trusted — validated by upstream systems, well-formatted
    B. Semi-trusted — generally correct but may contain errors or ambiguity
    C. Untrusted — raw user input, third-party API responses, noisy data
    D. Mixed — depends on the source

14. How does the agent receive inputs?
    A. On-demand — user triggers the agent explicitly
    B. Event-driven — agent reacts to incoming events or webhooks
    C. Scheduled — agent runs on a cron or periodic schedule
    D. Streaming — continuous real-time data flow
```

---

## Step 5: Generate Agent Design Document

After collecting all answers, generate the document using the template below. Save to `tasks/agent-design-[agent-name].md`.

### Output Template

````markdown
# Agent Design Document — [Agent Name]

## PEAS Specification

| Dimension | Specification |
|-----------|---------------|
| **Performance** | [KPIs from Q1. Evaluation method from Q2. Hard limits from Q3. Reasoning: Q4.] |
| **Environment** | [Observability: Q5. Dynamism: Q6. Task structure: Q7. Agent topology: Q8.] |
| **Actuators** | [Actions: Q9. Irreversibility: Q10. Confirmation policy: Q11.] |
| **Sensors** | [Input types: Q12. Reliability: Q13. Trigger model: Q14.] |

---

## Derived Recommendations

Based on the PEAS analysis:

| Property | Recommendation | Rationale |
|----------|---------------|-----------|
| **Agent Type** | [ReAct / Tool-calling / Multi-agent crew / Pipeline / Evaluator] | [Why, based on environment + actuators] |
| **Framework** | [LangGraph / CrewAI / AutoGen / SmolAgents / OpenAI / Anthropic] | [Why, based on agent type + task structure] |
| **Memory Model** | [None / Short-term context window / Long-term vector store / Episodic log] | [Why, based on task structure Q7] |
| **Confirmation Gates** | [None / High-risk only / Checkpoints / All actions] | [Why, based on Q10 + Q11] |

---

## Evaluation Plan

| Metric | Threshold | Evaluator | Frequency |
|--------|-----------|-----------|-----------|
| [Task completion rate] | [>X%] | [`llm_judge.md`] | [Per run / Per sprint] |
| [Output accuracy] | [>X%] | [Human review / Automated test] | [Per run / Sampled] |
| [Latency] | [<Xs] | [Programmatic timer] | [Per run] |
| [Cost per run] | [<$X] | [API usage tracking] | [Per sprint] |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Agent loops without converging] | [Low/Med/High] | [High] | Circuit breaker: stop after 2 failed attempts |
| [Tool returns empty or irrelevant results] | [Med] | [High] | CRAG fallback or graceful "I don't know" |
| [Stale or incorrect input data] | [Med] | [Med] | Validate input freshness; log to self-correction.md |
| [Irreversible action executed incorrectly] | [Low] | [Critical] | Confirmation gate before destructive actions |

---

## Skill Dependencies

| Skill File | Why Needed |
|------------|------------|
| `resources/skills/ai/frameworks/[framework]/SKILL.md` | [Framework-specific agent patterns] |
| `resources/skills/ai/retrieval/[retrieval]/SKILL.md` | [If retrieval is an actuator — RAG patterns] |
| `resources/skills/ai/data/[data]/SKILL.md` | [If multimodal input is a sensor] |

---

## Handoff

→ Pass this document to `resources/agents/architects/agentic_ai_architect.md` to begin architecture and implementation.
````

---

## Checklist

Before saving the Agent Design Document:

- [ ] All 4 PEAS dimensions answered (Performance, Environment, Actuators, Sensors)
- [ ] Derived Recommendations table is consistent with the PEAS answers
- [ ] Evaluation Plan includes at least 2 metrics with concrete thresholds
- [ ] Risk Register identifies at least 2 risks with mitigations
- [ ] Skill Dependencies reference real paths under `resources/skills/`
- [ ] Handoff line points to `agentic_ai_architect.md`
- [ ] Saved to `tasks/agent-design-[agent-name].md`
