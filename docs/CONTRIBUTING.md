# Contributing to Agentic Standards

Thank you for investing your time in making our team's AI smarter. When you add a skill, every developer instantly gains access to a new framework — with consistent, high-quality patterns from day one.

This guide covers everything you need to contribute a **Skill**, an **Agent**, or a **Rule**.

---

## Table of Contents

- [Adding a New Skill](#adding-a-new-skill)
- [Adding a New Agent](#adding-a-new-agent)
- [Adding a New Rule](#adding-a-new-rule)
- [Pull Request Checklist](#pull-request-checklist)
- [Style Guidelines](#style-guidelines)

---

## Adding a New Skill

Skills are passive Markdown files that teach AI assistants the syntax, best practices, and common pitfalls of a specific framework or architectural pattern.

### Step 1 — Choose the Right Category

Skills are organized by domain inside `resources/skills/`. Pick the category that best fits your framework:

| Category | Path | Examples |
|----------|------|----------|
| Multi-Agent Frameworks | `skills/multi_agent_frameworks/` | LangChain, CrewAI, AutoGen |
| RAG & Retrieval | `skills/rag_and_retrieval/` | CRAG, LlamaIndex |
| Multimodal & Data | `skills/multimodal_and_data/` | PDF parsing, Vision APIs |
| Prompt Engineering | `skills/prompt_engineering/` | CoVe, Self-Refine |
| Product | `skills/product/` | PRD templates |

If none of these categories fit, create a new one and explain why in your PR description.

### Step 2 — Create the Folder

Create a new directory inside the appropriate category, named after the framework. Use lowercase with hyphens.

```
resources/skills/<category>/your-framework/
```

### Step 3 — Create `SKILL.md`

Create a file called `SKILL.md` inside your new folder. You **must** use the template below — every section is required.

> **Tip:** You can open an AI chat and say:
> *"Read `docs/CONTRIBUTING.md` and create a new skill for FastAPI."*
> The AI will draft it for you using the template.

### Step 4 — Fill Out the Template

Copy the following structure into your `SKILL.md` and fill in every section:

````markdown
---
description: >
  A 1-2 sentence description of what this skill teaches the AI to do.
  Example: "Implements FastAPI endpoints with strict Pydantic validation
  and async dependency injection."
globs: "*.py"
---

# Core Philosophy

[1-2 sentences on what makes this framework unique and why we use it.
Example: "FastAPI is our standard for all sync/async REST APIs due to
its automatic OpenAPI generation and native Pydantic integration."]

# Trigger Scenarios

**USE THIS SKILL WHEN:**
- [Scenario 1, e.g., Building a new REST API endpoint]
- [Scenario 2, e.g., Defining strict request/response schemas]

**DO NOT USE THIS SKILL WHEN:**
- [Scenario 1, e.g., Building internal CLI tools (use Typer instead)]
- [Scenario 2, e.g., Simple scripting tasks with no HTTP layer]

# Pros vs Cons

| Pros | Cons |
|------|------|
| [Pro 1] | [Con 1] |
| [Pro 2] | [Con 2] |
| [Pro 3] | [Con 3] |

# Implementation Template

[Provide a concrete, copy-pasteable, production-ready code example.
This is what the AI will use as its primary reference. It MUST include:
- Type annotations on all parameters and return values
- Proper error handling
- Environment-based configuration (no hardcoded keys)]

```python
# Input:  [describe the expected input]
# Output: [describe the expected output]

# Your implementation here
```

# Common Pitfalls

[What mistakes did YOU make when first learning this? What does the AI
usually get wrong? List at least 2-3 pitfalls.]

- **Pitfall 1:** [e.g., "Forgetting to `await` async database calls
  inside FastAPI dependency injection."]
- **Pitfall 2:** [e.g., "Returning raw dicts instead of Pydantic models,
  bypassing automatic validation."]
- **Pitfall 3:** [e.g., "Using synchronous `requests` inside an async
  endpoint, blocking the event loop."]

# Self-Correction Mandate

**MANDATE:** If you encounter an unexpected error, a deprecation warning,
or a hallucination while using this skill, you MUST log the error, the
context, and the fix to `tasks/self-correction.md` before marking the
task as complete.
````

### Step 5 — Open a Pull Request

Submit a PR following the [Pull Request Checklist](#pull-request-checklist) below.

---

## Adding a New Agent

Agents are active personas that change how AI assistants *behave*. They enforce workflow discipline — step-by-step protocols, evaluation rubrics, or architectural decision processes.

### Where to Create It

Agents are organized by role inside `resources/agents/`. Pick the right sub-category:

| Category | Path | Examples |
|----------|------|----------|
| Reviewers | `agents/reviewers/` | Code reviewer, Test reporter |
| Architects | `agents/architects/` | RAG architect |
| Orchestrators | `agents/orchestrators/` | Prompt chainer, LLM judge |

Place your agent file in the appropriate category:

```
resources/agents/<category>/your_agent_name.md
```

### Required Structure

Every agent must follow this template:

| Section | Purpose |
|---------|---------|
| **Persona** | Who the agent is and how it behaves |
| **Operational Constraints** | What the agent is forbidden from doing |
| **Protocol** | The exact step-by-step workflow with `[STOP AND WAIT]` gates |
| **Output Format** | Strict template the agent must use for responses |
| **Escape Hatch** | Override command to bypass strict protocol when needed |
| **Self-Correction Mandate** | Instruction to read and update `tasks/self-correction.md` |

### Key Requirements

- Agents must read `tasks/self-correction.md` before starting work.
- Agents must append to `tasks/self-correction.md` when they encounter non-obvious issues.
- Agents must follow the behavioral rules in [`docs/AGENTS.md`](AGENTS.md).

---

## Adding a New Rule

Rules are standard documents that define project-wide guardrails. They enforce standards automatically when integrated with a compatible AI editor (e.g., via the setup scripts in `scripts/`).

### Where to Create It

Rules are organized by concern inside `resources/rules/`:

| Category | Path | Examples |
|----------|------|----------|
| Code Quality | `rules/code_quality/` | Type annotations, agent behavior |
| Security | `rules/security/` | API key management |
| LLM Standards | `rules/llm_standards/` | Default model selection |
| Evaluation | `rules/evaluation/` | RAG evaluation, EDD |

Place your rule file in the appropriate category:

```
resources/rules/<category>/your-rule-name.mdc
```

### Required Frontmatter

Every rule must start with YAML frontmatter specifying when it activates:

```yaml
---
alwaysApply: true
---
```

Or, for file-pattern-scoped rules:

```yaml
---
globs: "**/*.py"
---
```

### Guidelines

- Rules should enforce a single, clear standard (not a mix of concerns).
- Rules must be enforceable — vague aspirational guidance belongs in skills, not rules.
- After adding a rule, run `scripts/setup_cursor.ps1` (or `.sh`) to verify it symlinks correctly.

---

## Pull Request Checklist

Before submitting your PR, verify the following:

- [ ] **Template compliance:** Your skill/agent/rule follows the required structure exactly.
- [ ] **Correct category:** The file is placed in the right sub-folder within `resources/`.
- [ ] **No hardcoded keys:** No API keys, tokens, or credentials appear anywhere in the file.
- [ ] **Implementation template works:** The code example in your skill is copy-pasteable and runs correctly.
- [ ] **Common Pitfalls are genuine:** Each pitfall comes from real experience, not speculation.
- [ ] **Self-Correction Mandate is present:** The file includes the mandate to log errors to `tasks/self-correction.md`.
- [ ] **Descriptive PR title:** Use the format `feat(skills): add <framework-name> skill` or `feat(agents): add <agent-name> agent`.

---

## Style Guidelines

- **File naming:** Use lowercase with hyphens for skill folders (`multi-modal`), underscores for agent files (`prompt_chainer.md`).
- **Code examples:** Must include type annotations, error handling, and environment-based configuration.
- **Tone:** Write as if you are teaching a competent colleague, not a beginner. Be precise, not verbose.
- **Markdown:** Use ATX-style headers (`#`, `##`). Use tables for structured comparisons. Use fenced code blocks with language tags.
