# Agentic Playbook

**A standalone, plugin-distributable knowledge base of role-based AI agents, framework skills, and engineering process discipline — for building robust full-stack and AI-powered applications.**

Two halves of the same problem in one repo:

| | What it answers | Lives in |
|---|---|---|
| **Knowledge layer** | *What* to know — frameworks, libraries, domain patterns | `skills/<role>/` (React, FastAPI, Stripe, RAG, ...) |
| **Process layer** | *How* to work — brainstorm, plan, TDD, verify, review, ship | `skills/shared/process/` (vendored from [obra/superpowers](https://github.com/obra/superpowers), MIT) |

Plain Markdown. No runtime dependencies. Works in Cursor, Claude Code, Codex, Gemini CLI, Copilot CLI, or as a `git clone` reference.

---

## Quick Start

### A. Clone and read

```bash
git clone https://github.com/alanvaa06/agentic-playbook.git
cd agentic-playbook
```

Browse `agents/` for role definitions, `skills/` for skill sets, `resources/rules/` for guardrails, `docs/process/` for lifecycle docs.

### B. Install as a plugin (Claude Code, Codex, Gemini, Copilot, Cursor)

```bash
/plugin marketplace add alanvaa06/agentic-playbook-marketplace
/plugin install agentic-playbook
```

Registers all role agents, every skill, and the `/brainstorm` `/write-plan` `/execute-plan` `/ship` slash commands. (Marketplace listing is in flight — see [RELEASE-NOTES.md](RELEASE-NOTES.md).)

### C. Cursor symlink integration

```bash
# macOS / Linux
bash scripts/setup_cursor.sh

# Windows (PowerShell as Admin or with Developer Mode enabled)
powershell -ExecutionPolicy Bypass -File scripts\setup_cursor.ps1
```

Symlinks `agents/`, `skills/`, `commands/`, and the rules under `resources/rules/` into `.cursor/` so Cursor auto-applies guardrails and discovers content via `@` mentions.

---

## Architecture

Three top-level concerns:

```
agents/             role definitions (one .md per role)
skills/             knowledge + process skills
resources/rules/    project-wide editor-enforced guardrails
```

### Agents (10 roles)

| Agent | Type | Skills | Specialty |
|---|---|---|---|
| `frontend_agent` | Role | 8 | React 19, Tailwind v4, Framer Motion, GSAP, Lenis, R3F, forms, Sanity CMS |
| `backend_agent` | Role | 3 | FastAPI, SQL/Postgres, Supabase RLS |
| `database_agent` | Role | 4 | Migrations, vector DBs, SQL/Postgres, Supabase RLS |
| `devops_agent` | Role | 2 | Docker, GitHub Actions |
| `qa_agent` | Role | 4 | Pytest, Jest, Mypy, Ruff |
| `security_agent` | Role | 3 | SAST, secrets scanning, dependency audit |
| `payment_agent` | Role | 3 | Stripe, PayPal, MercadoPago |
| `agentic_ai_architect` | Architect | 13 | LangChain, CrewAI, AutoGen, SmolAgents, OpenAI, Anthropic, LlamaIndex, CRAG, Financial RAG, multimodal parsing, vision APIs, synthetic data, vector DBs |
| `fullstack_architect` | Architect | 0 | Blueprints apps; delegates to role agents |
| `llm_judge` | Reviewer | 0 | Scores code against a 10-point rubric |

Each role file (`agents/<role>/<role>.md`) declares its skill registry and the lifecycle phases it participates in (Process Gates).

### Skills (two buckets)

```
skills/
  <role>/                  domain knowledge (e.g. skills/frontend_agent/react_best_practices.md)
  shared/
    product/               PRD, PEAS agent design framework
    prompt_engineering/    CoVe, Self-Refine, prompt chaining
    process/               13 process skills (the lifecycle)
```

Every skill carries YAML frontmatter (`name` + `description`) so it auto-triggers in Claude Code / Cursor / Codex when its description matches the task. Companion files (sub-skill docs, prompt templates, references) intentionally omit frontmatter — they're loaded via their parent `SKILL.md`.

### Process skills (the lifecycle)

13 skills under `skills/shared/process/`, vendored and adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, see [docs/process/CREDITS.md](docs/process/CREDITS.md)). They define the 10-phase lifecycle every non-trivial task flows through:

| # | Phase | Skill |
|---|---|---|
| 1 | Define problem | `brainstorming` |
| 2 | Blueprint | `brainstorming` (continued, with the architect) |
| 3 | Plan | `writing-plans` |
| 4 | Isolate workspace | `using-git-worktrees` |
| 5 | Execute | `subagent-driven-development` or `executing-plans` |
| 6 | Test discipline | `test-driven-development` |
| 7 | Debug | `systematic-debugging` |
| 8 | Verify | `verification-before-completion` |
| 9 | Review | `requesting-code-review` then `receiving-code-review` |
| 10 | Ship | `finishing-a-development-branch` |

Plus `dispatching-parallel-agents` (any phase) and `using-process-skills` (entry point). Full mapping: [docs/process/SKILL_INDEX.md](docs/process/SKILL_INDEX.md). Lifecycle is enforced in [AGENTS.md §10](AGENTS.md).

### Rules (guardrails)

Always-on standards under `resources/rules/`. When an editor with rule support reads them (Cursor's `.mdc`, others by similar mechanisms), they apply automatically.

| Category | Rules | What they enforce |
|---|---|---|
| **Code Quality** | `agent-behavior`, `robust-python-*` | Plan before code, type annotations, clean architecture |
| **Security** | `api-security` | API keys from environment variables, never hardcoded |
| **LLM Standards** | `default-models`, `multimodal-parsing` | Anthropic/Gemini by default; Claude for chart-heavy PDFs |
| **Evaluation** | `rag-evaluation`, `edd-evaluation` | Every RAG pipeline and agent ships with eval metrics |

---

## How the Layers Compose

1. A **PRD** or **PEAS Agent Design Document** captures *what* to build (`skills/shared/product/`).
2. `fullstack_architect` runs `brainstorming` → `writing-plans` and produces a delegation map.
3. If an AI subsystem is involved, `agentic_ai_architect` picks the pattern (RAG, multi-agent, multimodal) and loads its colocated skills.
4. Role agents (`backend`, `frontend`, `database`, `devops`, `qa`, `security`, `payment`) implement their slices using their colocated skills, gated by `test-driven-development` + `verification-before-completion`.
5. `requesting-code-review` runs; `llm_judge` scores against its 10-point rubric.
6. `finishing-a-development-branch` ships the work.
7. **Rules** silently enforce security, model selection, and evaluation throughout.

---

## The Self-Correction Loop

The agent doesn't just write code — it learns. Every agent in this repo is mandated to:

1. **Read** [`Context/tasks/self-correction.md`](Context/tasks/self-correction.md) at the start of every session.
2. **Log** any unexpected error, deprecation, or hallucination with a structured entry (Date, Context, Mistake, Fix, Lesson — schema in [AGENTS.md §3](AGENTS.md)).
3. **Apply** past lessons proactively to avoid repeating known pitfalls.

Compound learning effect: every mistake one developer's AI hits becomes institutional knowledge for the team.

---

## Project Structure

```
agentic-playbook/
  .claude-plugin/
    plugin.json                       Claude Code plugin manifest
  AGENTS.md                           Behavioral orchestration policy (§1-§10)
  README.md                           This file
  RELEASE-NOTES.md                    Versioned changelog
  agents/                             Role definitions (10 .md files)
    <role>/<role>.md
  skills/
    <role>/                           Domain knowledge per role
    shared/
      product/                        PRD, PEAS
      prompt_engineering/             CoVe, Self-Refine, chaining
      process/                        13 vendored process skills
  commands/
    brainstorm.md                     /brainstorm  -> process/brainstorming
    write-plan.md                     /write-plan  -> process/writing-plans
    execute-plan.md                   /execute-plan -> process/executing-plans
    ship.md                           /ship        -> process/finishing-a-development-branch
  resources/
    rules/                            Project-wide guardrails (.mdc)
      code_quality/  evaluation/  llm_standards/  security/
  Context/
    tasks/
      todo.md                         Canonical task tracker
      self-correction.md              Learning database
  docs/
    BUILD_PLAYBOOK.md                 Step-by-step playbook usage guide
    CONTRIBUTING.md                   How to add skills, agents, rules
    agent-template.md                 Template for new role agents
    skill-template.md                 Template for new skills
    process/
      CREDITS.md                      obra/superpowers MIT attribution
      SKILL_INDEX.md                  Phase <-> skill mapping
      USAGE.md                        Manual phase invocation guide
      specs/                          Design specs
      plans/                          Implementation plans
  scripts/
    setup_cursor.sh                   Cursor integration (macOS/Linux)
    setup_cursor.ps1                  Cursor integration (Windows)
  .gitignore                          Security-first ignore patterns
```

---

## Where to Start

New to this playbook on a real project? Read **[docs/BUILD_PLAYBOOK.md](docs/BUILD_PLAYBOOK.md)** — the step-by-step guide for which agent to invoke, in what order, and why. Then consult [docs/process/USAGE.md](docs/process/USAGE.md) for how the 10 lifecycle phases hang together.

---

## Contributing

New skills, agents, and rules are welcome.

**Adding a skill takes about 10 minutes.** The template ([docs/skill-template.md](docs/skill-template.md)) enforces consistency: YAML frontmatter, philosophy, trigger scenarios, implementation, pitfalls, self-correction mandate.

Full guide: **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)**

### Quick version

1. Find the role that owns the skill domain in `agents/`.
2. Add your skill at `skills/<role>/<topic>.md` (or `skills/<role>/<topic>/SKILL.md` for skills with companion files).
3. Add YAML frontmatter (`name`, `description`).
4. Register the skill in the role agent's Skill Registry table.
5. Open a PR with prefix `feat(skills):`.

---

## Design Philosophy

| Principle | Implementation |
|---|---|
| **Colocation** | Each role owns its domain skills; the process bucket sits under `skills/shared/process/` |
| **Autonomy** | Agents complete work without intervention; ask only when genuinely blocked |
| **Correctness over speed** | A slower, correct solution beats a fast, broken one |
| **Continuous learning** | Every mistake is logged; lessons applied proactively |
| **Security hygiene** | No secrets in code; `.env` files git-ignored by default |
| **Minimal blast radius** | Change only what needs changing; no unnecessary refactors |
| **Editor agnostic** | Knowledge lives in plain Markdown; editor integration is optional |
| **Standalone** | No runtime deps; the methodology lives in the repo, not a plugin |

---

## License

MIT. See [LICENSE](LICENSE).

Process skills under `skills/shared/process/` are adapted from [obra/superpowers](https://github.com/obra/superpowers) (also MIT) — full attribution and upstream commit SHA in [docs/process/CREDITS.md](docs/process/CREDITS.md).
