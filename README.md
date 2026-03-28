# Agentic Playbook

**A curated knowledge base of AI agent patterns, framework skills, and engineering standards for building robust full-stack and AI-powered applications.**

Building AI agents and full-stack applications often leads to messy, inconsistent code â€” each developer reinventing patterns, hardcoding API keys, and defaulting to whatever LLM the tutorial used. This repository solves that by providing a **colocated agent architecture** where each agent owns its skills, plus project-wide rules â€” all in plain Markdown that integrates seamlessly with AI-powered editors like Cursor.

---

## Quick Start

```bash

git clone https://github.com/<your-org>/agentic-playbook.git

cd agentic-playbook

```

Browse `agents/` for role definitions, `skills/` for skill sets, or `resources/rules/` for project-wide standards.

**Optional â€” Cursor IDE integration:**

```bash

# macOS / Linux

bash scripts/setup_cursor.sh

# Windows (PowerShell as Admin or with Developer Mode enabled)

powershell -ExecutionPolicy Bypass -File scripts\setup_cursor.ps1

```

This creates symlinks so Cursor auto-applies rules and discovers agents/skills via `@` mentions.

---

## Architecture

The repository is organized around two top-level concerns:

```

agents/              Agent role definitions

skills/              Skill sets grouped by agent (including shared)

resources/rules/     Project-wide guardrails (editor-enforced)

```

### Agents + Skills

Every agent lives in its own folder alongside the skills it uses. This makes it trivial to see what an agent knows, add skills, or onboard new team members.

```

agents/

â”œâ”€â”€ frontend_agent/

â”‚   â”œâ”€â”€ frontend_agent.md          Role definition

â”‚   â””â”€â”€ skills/                    8 colocated skills

â”‚       â”œâ”€â”€ react_best_practices.md

â”‚       â”œâ”€â”€ tailwind_design_system.md

â”‚       â”œâ”€â”€ framer_motion.md

â”‚       â”œâ”€â”€ gsap-animations.md

â”‚       â”œâ”€â”€ smooth-scroll.md

â”‚       â”œâ”€â”€ react_three_fiber.md

â”‚       â”œâ”€â”€ forms_validation.md

â”‚       â””â”€â”€ sanity_cms.md

â”œâ”€â”€ backend_agent/                 3 skills

â”œâ”€â”€ database_agent/                4 skills

â”œâ”€â”€ ...

â””â”€â”€ shared/                        Skills not owned by any single agent

    â””â”€â”€ skills/

        â”œâ”€â”€ prompt_engineering/

        â””â”€â”€ product/

```

| Agent | Type | Skills | Specialty |

|-------|------|--------|-----------|

| **frontend_agent** | Role | 8 | React 19, Tailwind v4, Framer Motion, GSAP, Lenis, R3F, forms, Sanity CMS |

| **backend_agent** | Role | 3 | FastAPI, SQL/Postgres, Supabase RLS |

| **database_agent** | Role | 4 | Migrations, vector DBs, SQL/Postgres, Supabase RLS |

| **devops_agent** | Role | 2 | Docker, GitHub Actions |

| **qa_agent** | Role | 4 | Pytest, Jest, Mypy, Ruff |

| **security_agent** | Role | 3 | SAST, secrets scanning, dependency audit |

| **payment_agent** | Role | 3 | Stripe, PayPal, MercadoPago |

| **agentic_ai_architect** | Architect | 14 | LangChain, CrewAI, AutoGen, SmolAgents, OpenAI, Anthropic, LlamaIndex, CRAG, Financial RAG, multimodal parsing, vision APIs, synthetic data, vector DBs |

| **fullstack_architect** | Architect | 0 | Blueprints apps and delegates to role agents (references their skills) |

| **llm_judge** | Reviewer | 0 | Scores code against a 10-point rubric (dynamically loads relevant skills) |

| **shared** | â€” | 5 | Prompt engineering (CoVe, Self-Refine, chaining), Product (PRD, PEAS) |

### Rules (Guardrails)

Rules define project-wide standards. When integrated with a compatible editor, they are enforced **automatically** without requiring any developer action.

| Category | Rules | What They Enforce |

|----------|-------|-------------------|

| **Code Quality** | `agent-behavior`, `robust-python-*` | Planning before coding, type annotations, clean architecture |

| **Security** | `api-security` | API keys from environment variables, never hardcoded |

| **LLM Standards** | `default-models`, `multimodal-parsing` | Use Anthropic/Gemini by default; Claude for chart-heavy PDFs |

| **Evaluation** | `rag-evaluation`, `edd-evaluation` | Every RAG pipeline and agent must include evaluation metrics |

---

## How the Layers Work Together

The agents and rules complement each other in a continuous quality loop:

1. A **PRD** or **PEAS Agent Design Document** defines what to build (`skills/shared/product/`).

2. The **`fullstack_architect`** blueprints the web application and produces a delegation map for role agents.

3. If the app includes an AI subsystem, **`agentic_ai_architect`** selects the right pattern (RAG, multi-agent, multimodal) and loads its colocated skills.

4. **Role agents** (backend, frontend, database, devops, qa) implement their portions using their own colocated skills.

5. **`llm_judge`** evaluates the generated code against the skill's patterns and scores it.

6. Throughout the process, **Rules** silently enforce security, model selection, and evaluation standards.

---

## The Self-Correction Loop

Our AI doesn't just write code â€” it learns. Every agent in this repository is mandated to:

1. **Read** [`context/tasks/self-correction.md`](context/tasks/self-correction.md) at the start of every session.

2. **Log** any unexpected errors, deprecations, or hallucinations with a structured entry.

3. **Apply** past lessons proactively, avoiding known pitfalls before they happen.

This creates a **compound learning effect**: every mistake one developer's AI encounters becomes institutional knowledge for the entire team.

---

## Project Structure

```

agentic-playbook/

â”œâ”€â”€ agents/                                 Colocated agent definitions + skills

â”‚   â”œâ”€â”€ frontend_agent/

â”‚   â”‚   â”œâ”€â”€ frontend_agent.md               Role definition

â”‚   â”‚   â””â”€â”€ skills/                         React, Tailwind, Framer Motion, GSAP, Lenis, R3F, forms, Sanity

â”‚   â”œâ”€â”€ backend_agent/

â”‚   â”‚   â”œâ”€â”€ backend_agent.md

â”‚   â”‚   â””â”€â”€ skills/                         FastAPI, SQL/Postgres, Supabase RLS

â”‚   â”œâ”€â”€ database_agent/

â”‚   â”‚   â”œâ”€â”€ database_agent.md

â”‚   â”‚   â””â”€â”€ skills/                         Migrations, Vector DBs, SQL/Postgres, Supabase RLS

â”‚   â”œâ”€â”€ devops_agent/

â”‚   â”‚   â”œâ”€â”€ devops_agent.md

â”‚   â”‚   â””â”€â”€ skills/                         Docker, GitHub Actions

â”‚   â”œâ”€â”€ qa_agent/

â”‚   â”‚   â”œâ”€â”€ qa_agent.md

â”‚   â”‚   â””â”€â”€ skills/                         Pytest, Jest, Mypy, Ruff

â”‚   â”œâ”€â”€ security_agent/

â”‚   â”‚   â”œâ”€â”€ security_agent.md

â”‚   â”‚   â””â”€â”€ skills/                         SAST, Secrets scanning, Dependency audit

â”‚   â”œâ”€â”€ payment_agent/

â”‚   â”‚   â”œâ”€â”€ payment_agent.md

â”‚   â”‚   â””â”€â”€ skills/                         Stripe, PayPal, MercadoPago

â”‚   â”œâ”€â”€ agentic_ai_architect/

â”‚   â”‚   â”œâ”€â”€ agentic_ai_architect.md

â”‚   â”‚   â””â”€â”€ skills/                         14 AI skills (frameworks, retrieval, data, vector DBs)

â”‚   â”œâ”€â”€ fullstack_architect/

â”‚   â”‚   â””â”€â”€ fullstack_architect.md          References other agents' skills for blueprint decisions

â”‚   â”œâ”€â”€ llm_judge/

â”‚   â”‚   â””â”€â”€ llm_judge.md                   Strict code evaluator (10-point rubric)

â”‚   â””â”€â”€ shared/

â”‚       â””â”€â”€ skills/                         Prompt engineering (CoVe, Self-Refine, chaining), Product (PRD, PEAS)

â”œâ”€â”€ resources/

â”‚   â””â”€â”€ rules/                              Project-wide guardrails

â”‚       â”œâ”€â”€ code_quality/                   Type safety, agent behavior

â”‚       â”œâ”€â”€ security/                       API key management

â”‚       â”œâ”€â”€ llm_standards/                  Model selection, multimodal routing

â”‚       â””â”€â”€ evaluation/                     RAG eval, eval-driven development

â”œâ”€â”€ AGENTS.md                               Behavioral orchestration protocol (root-level)

â”œâ”€â”€ context/

â”‚   â””â”€â”€ tasks/                              AI working memory

â”‚       â”œâ”€â”€ todo.md                         Canonical task tracker

â”‚       â””â”€â”€ self-correction.md              Learning database

â”œâ”€â”€ docs/                                   Project documentation

â”‚   â”œâ”€â”€ BUILD_PLAYBOOK.md                   Step-by-step guide: what to build first and in what order

â”‚   â””â”€â”€ CONTRIBUTING.md                     How to add skills, agents, and rules

â”œâ”€â”€ scripts/                                Tooling

â”‚   â”œâ”€â”€ setup_cursor.sh                     Cursor integration (macOS/Linux)

â”‚   â””â”€â”€ setup_cursor.ps1                    Cursor integration (Windows)

â”œâ”€â”€ .gitignore                              Security-first ignore patterns

â””â”€â”€ README.md                               You are here

```

---

## Editor Integration

This repository is **editor-agnostic**. The `agents/` and `resources/` folders are plain Markdown â€” usable in any AI-powered editor, or even copy-pasted into web-based LLM interfaces.

### Cursor IDE

We provide setup scripts that symlink into Cursor's expected `.cursor/` directory:

| Platform | Command |

|----------|---------|

| macOS / Linux | `bash scripts/setup_cursor.sh` |

| Windows | `powershell -ExecutionPolicy Bypass -File scripts\setup_cursor.ps1` |

This enables automatic rule enforcement and `@` mention discovery.

---

## Where to Start

Not sure how to use this playbook on a real project? Read **[docs/BUILD_PLAYBOOK.md](docs/BUILD_PLAYBOOK.md)** â€” the step-by-step guide that tells you which agent to invoke, in what order, and why.

---

## Contributing

We actively encourage the team to contribute new skills, agents, and rules.

**Adding a skill takes about 10 minutes.** Every skill follows a strict template (frontmatter, philosophy, trigger scenarios, implementation code, pitfalls, and self-correction mandate) to ensure consistency.

Read the full guide: **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)**

### Quick Version

1. Find the agent that owns the skill domain in `agents/`.

2. Add your skill file to `skills/<agent_name>/`.

3. Register the skill in the agent's Skill Registry table.

4. Open a PR with the prefix `feat(skills):`.

---

## Design Philosophy

| Principle | Implementation |

|-----------|---------------|

| **Colocation** | Each agent owns its skills â€” everything it needs lives in one folder |

| **Autonomy** | Agents complete work without user intervention; ask only when genuinely blocked |

| **Correctness over speed** | A slower, correct solution beats a fast, broken one |

| **Continuous learning** | Every mistake is logged and never repeated |

| **Security hygiene** | No secrets in code; `.env` files are git-ignored by default |

| **Minimal blast radius** | Change only what needs to change; no unnecessary refactors |

| **Editor agnostic** | Knowledge lives in plain Markdown; editor integration is optional |

---

## License

This project is for internal use. See [LICENSE](LICENSE) for details.

