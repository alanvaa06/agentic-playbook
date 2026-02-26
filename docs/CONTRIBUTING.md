# Contributing to Agentic Playbook

Thank you for investing your time in making our team's AI smarter. When you add a skill, every developer instantly gains access to a new framework — with consistent, high-quality patterns from day one.

This guide covers everything you need to contribute a **Skill**, an **Agent**, or a **Rule**.

> **Building something with this playbook?** Start with **[BUILD_PLAYBOOK.md](BUILD_PLAYBOOK.md)** — the step-by-step guide that tells you which agent to invoke, in what order, for any type of application.

---

## Table of Contents

- [Adding a New Skill](#adding-a-new-skill)
  - [AI & Architecture Skills](#adding-a-new-skill)
  - [Technology-Specific Skills](#technology-specific-skills)
- [Adding a New Agent](#adding-a-new-agent)
- [Adding a New Rule](#adding-a-new-rule)
- [Pull Request Checklist](#pull-request-checklist)
- [Style Guidelines](#style-guidelines)

---

## Adding a New Skill

Skills are passive Markdown files that teach AI assistants the syntax, best practices, and common pitfalls of a specific framework or architectural pattern.

### Step 1 — Choose the Right Category

Skills are organized by domain inside `resources/skills/`. Pick the category that best fits your framework:

**AI & Architecture Skills** — Abstract patterns and AI-framework orchestration:

| Category | Path | Examples |
|----------|------|----------|
| AI Frameworks | `skills/ai/frameworks/` | LangChain, CrewAI, AutoGen |
| RAG & Retrieval | `skills/ai/retrieval/` | CRAG, LlamaIndex |
| Multimodal & Data | `skills/ai/data/` | PDF parsing, Vision APIs |
| Prompt Engineering | `skills/prompt_engineering/` | CoVe, Self-Refine |
| Product | `skills/product/` | PRD templates, PEAS agent design |

**Technology-Specific Skills** — Concrete tech-stack implementation rules (see [dedicated section below](#technology-specific-skills)):

| Category | Path | Examples |
|----------|------|----------|
| Backend | `skills/backend/` | FastAPI, SQL Postgres, Supabase RLS |
| Frontend | `skills/frontend/` | React, Tailwind, Sanity CMS, Framer Motion |
| Database | `skills/database/` | Migrations, Vector DBs |
| DevOps | `skills/devops/` | Docker, GitHub Actions |
| Payments | `skills/payments/` | Stripe, MercadoPago, PayPal |
| Security | `skills/security/` | SAST, Secrets scanning, Dependency audit |
| QA | `skills/qa/` | Pytest, Jest, Mypy, Ruff |

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

## Technology-Specific Skills

Technology-Specific Skills are different from AI-framework skills. They encode **code architecture standards, file conventions, and integration patterns** for the concrete tools in your stack (React components, FastAPI endpoints, Docker configurations). Agents load these at runtime by inspecting `package.json` / `requirements.txt` and loading the matching skill from their own **Skill Registry (§7)**.

### How They Differ from AI & Architecture Skills

| Dimension | AI & Architecture Skill | Technology-Specific Skill |
|-----------|------------------------|--------------------------|
| **Focus** | How to use an AI library (LangChain, CRAG) | How to write production code for a tech stack (FastAPI, React) |
| **Consumer** | Agents and LLMs reasoning about AI pipelines | Agents writing application code |
| **`globs` frontmatter** | Rarely scoped | Always scoped to the relevant file extensions |
| **Code examples** | LLM orchestration code | Real application code (routes, components, schemas) |
| **Loaded by** | Manual or always-on | Skill Registry (§7) in each relevant agent |

### Step 1 — Choose the Category

Use the Technology-Specific category table from [Adding a New Skill → Step 1](#step-1--choose-the-right-category). Create a new directory inside the appropriate category using the technology name in lowercase with hyphens.

```
resources/skills/<category>/your-technology/
```

### Step 2 — Create `SKILL.md`

Create a `SKILL.md` inside your new folder using the template below. Every section is required. The `globs` frontmatter is mandatory — it tells the AI editor which files this skill applies to automatically.

> **Tip:** You can open an AI chat and say:
> *"Read `docs/CONTRIBUTING.md` and create a Technology-Specific Skill for FastAPI."*
> The AI will draft it for you using the template below.

### Step 3 — Fill Out the Template

Copy the following structure into your `SKILL.md`:

````markdown
---
name: [technology-name]
description: >
  A 1-2 sentence description of what this skill enforces.
  Example: "Implements FastAPI endpoints with Pydantic v2 validation,
  async dependency injection, and structured error handling."
globs: "**/*.py"
---

# [Technology Name]

## Core Philosophy

[1-2 sentences on the architectural paradigm this technology enforces and
why the team chose it. Be specific — mention the concrete property that
makes it the right tool (e.g., "automatic OpenAPI generation", "row-level
security built into the database layer").]

## Trigger Scenarios

✅ **WHEN to use it:**
- [Scenario 1 — e.g., Building a new REST API endpoint with typed request/response bodies]
- [Scenario 2 — e.g., Defining database schemas that must be version-controlled via migrations]
- [Scenario 3]

❌ **WHEN NOT to use it:**
- [Scenario 1 — e.g., Internal CLI tools with no HTTP layer (use Typer)]
- [Scenario 2 — e.g., One-off scripts with no shared business logic]

## Pros vs Cons

| Pros | Cons |
|------|------|
| [Pro 1] | [Con 1] |
| [Pro 2] | [Con 2] |
| [Pro 3] | [Con 3] |

## Project Structure

[Show the canonical folder/file layout for this technology within the
project. Use a directory tree. Only include the directories this skill
owns — not the entire repo.]

```
src/
├── [module]/
│   ├── [file].py        # [what it contains]
│   ├── [schemas].py     # Pydantic models / TypeScript types
│   └── [tests]/
│       └── test_[module].py
```

## Implementation Template

[Provide a single, complete, copy-pasteable example that demonstrates the
canonical pattern for this technology. Requirements:
- Type annotations on ALL parameters and return values
- Proper error handling (no bare excepts, no silent failures)
- Environment-based configuration (no hardcoded strings or keys)
- Follows the project structure defined above]

```python
# Input:  [describe the expected input — e.g., "POST /items with a JSON body"]
# Output: [describe the expected output — e.g., "201 Created with the persisted item"]

# Your implementation here
```

## Integration Points

[Describe how this technology connects to other parts of the stack.
Use a table if there are multiple integration points.]

| Integrates With | How |
|-----------------|-----|
| [e.g., Supabase] | [e.g., Client initialized via `SUPABASE_URL` + `SUPABASE_KEY` env vars] |
| [e.g., Pydantic] | [e.g., All request/response bodies are Pydantic v2 `BaseModel` subclasses] |

## Common Pitfalls

[List 3+ pitfalls that come from real experience — not guesswork. Focus on
mistakes an AI assistant is likely to repeat.]

- **[Pitfall 1]:** [Concrete mistake and how to avoid it. e.g., "Returning
  a raw `dict` instead of the Pydantic response model bypasses validation
  and breaks the OpenAPI schema."]
- **[Pitfall 2]:** [e.g., "Using synchronous `requests` inside an `async`
  endpoint blocks the event loop. Always use `httpx.AsyncClient`."]
- **[Pitfall 3]:** [e.g., "Omitting `response_model=` on the route decorator
  means sensitive fields are never filtered from responses."]

## 🚨 Self-Correction Mandate

If you encounter an unexpected error, a deprecation warning, or a pattern
that required more than one attempt to get right while using this skill,
you MUST log the failure to `tasks/self-correction.md` before marking the
task complete. Use the format defined in `docs/AGENTS.md §3`.

Pay special attention to:
- [Common failure mode 1 for this technology]
- [Common failure mode 2 for this technology]
````

### Step 4 — Register in the Agent Skill Registry

Add a row to the **Skill Registry (§7)** of each agent that should load this new skill. Do not modify `docs/agent-template.md` — each agent maintains its own registry. For example:

- A new backend skill belongs in `resources/agents/roles/backend_agent.md` §7
- A new payment skill belongs in `resources/agents/roles/payment_agent.md` §7
- A new security skill belongs in `resources/agents/roles/security_agent.md` §7

```markdown
| `resources/skills/[category]/[your-technology].md` | [One-line description of what this skill teaches] |
```

### Step 5 — Open a Pull Request

Submit a PR following the [Pull Request Checklist](#pull-request-checklist) below.

---

## Adding a New Agent

Agents are active personas that change how AI assistants *behave*. They enforce workflow discipline — step-by-step protocols, evaluation rubrics, or architectural decision processes.

### Where to Create It

Agents are organized by role inside `resources/agents/`. Pick the right sub-category:

| Category | Path | Examples |
|----------|------|----------|
| Roles | `agents/roles/` | QA agent, Backend agent, Frontend agent |
| Reviewers | `agents/reviewers/` | LLM judge, Feature tracker |
| Architects | `agents/architects/` | Agentic AI architect, Full Stack architect |

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

**All contributions:**
- [ ] **Template compliance:** Your skill/agent/rule follows the required structure exactly.
- [ ] **Correct category:** The file is placed in the right sub-folder within `resources/`.
- [ ] **No hardcoded keys:** No API keys, tokens, or credentials appear anywhere in the file.
- [ ] **Common Pitfalls are genuine:** Each pitfall comes from real experience, not speculation.
- [ ] **Self-Correction Mandate is present:** The file includes the mandate to log errors to `tasks/self-correction.md`.
- [ ] **Descriptive PR title:** Use the format `feat(skills): add <framework-name> skill` or `feat(agents): add <agent-name> agent`.

**AI & Architecture Skills (additional):**
- [ ] **Implementation template works:** The code example is copy-pasteable and exercises the AI framework correctly.

**Technology-Specific Skills (additional):**
- [ ] **`globs` frontmatter is set:** The frontmatter scopes the skill to the correct file extensions.
- [ ] **Project Structure section present:** The canonical folder layout for the technology is documented.
- [ ] **Integration Points section present:** How this technology connects to the rest of the stack is described.
- [ ] **Skill Registry updated:** A row has been added to the relevant agent(s) in `resources/agents/roles/` or `resources/agents/architects/` so they load this skill automatically.
- [ ] **Implementation template is production-ready:** Includes type annotations, error handling, and environment-based configuration.

---

## Style Guidelines

- **File naming:** Use lowercase with hyphens for skill folders (`multi-modal`), underscores for agent files (`llm_judge.md`).
- **Code examples:** Must include type annotations, error handling, and environment-based configuration.
- **Tone:** Write as if you are teaching a competent colleague, not a beginner. Be precise, not verbose.
- **Markdown:** Use ATX-style headers (`#`, `##`). Use tables for structured comparisons. Use fenced code blocks with language tags.
