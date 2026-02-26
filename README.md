# Agentic Playbook

**A curated knowledge base of AI agent patterns, framework skills, and engineering standards for building robust full-stack and AI-powered applications.**

Building AI agents and full-stack applications often leads to messy, inconsistent code — each developer reinventing patterns, hardcoding API keys, and defaulting to whatever LLM the tutorial used. This repository solves that by providing a **three-layered AI orchestration system** (Skills, Agents, and Rules) that any team member can reference, and that integrates seamlessly with AI-powered editors like Cursor.

---

## Quick Start

```bash
git clone https://github.com/<your-org>/agentic-playbook.git
cd agentic-playbook
```

The `resources/` directory is immediately browsable — open any `SKILL.md` to learn a framework, or reference an agent persona in your AI chat.

**Optional — Cursor IDE integration:**

```bash
# macOS / Linux
bash scripts/setup_cursor.sh

# Windows (PowerShell as Admin or with Developer Mode enabled)
powershell -ExecutionPolicy Bypass -File scripts\setup_cursor.ps1
```

This creates symlinks so Cursor auto-applies rules and discovers agents/skills via `@` mentions.

---

## Architecture: The Three Layers of AI

This repository is built on three complementary systems, each operating at a different level of abstraction:

```
resources/
├── rules/         Guardrails — project-wide standards and constraints
├── agents/        Discipline — personas that enforce specific workflows
└── skills/        Vocabulary — framework templates for code generation
```

### Rules (Guardrails)

Rules define project-wide standards. When integrated with a compatible editor, they are enforced **automatically** without requiring any developer action.

| Category | Rules | What They Enforce |
|----------|-------|-------------------|
| **Code Quality** | `agent-behavior`, `robust-python-*` | Planning before coding, type annotations, clean architecture |
| **Security** | `api-security` | API keys from environment variables, never hardcoded |
| **LLM Standards** | `default-models`, `multimodal-parsing` | Use Anthropic/Gemini by default; Claude for chart-heavy PDFs |
| **Evaluation** | `rag-evaluation`, `edd-evaluation` | Every RAG pipeline and agent must include evaluation metrics |

### Agents (Discipline)

Agents are active personas that change how the AI *behaves*. Instead of just writing code, the AI adopts a specific workflow: breaking tasks into steps, evaluating code against a rubric, or guiding architectural decisions.

| Category | Agent | What It Does |
|----------|-------|-------------|
| **Roles** | `qa_agent.md` | Static analysis, test execution, coverage reporting |
| **Roles** | `frontend_agent.md` | React/UI component development and styling |
| **Roles** | `backend_agent.md` | API development and dependency injection |
| **Roles** | `database_agent.md` | Schema design and migrations |
| **Roles** | `devops_agent.md` | Infrastructure, CI/CD, and containers |
| **Roles** | `payment_agent.md` | Webhooks and transaction handling |
| **Roles** | `security_agent.md` | Vulnerability scanning and secrets |
| **Architects** | `agentic_ai_architect.md` | Designs AI systems (RAG, multi-agent, multimodal, financial, synthetic data) |
| **Architects** | `fullstack_architect.md` | Blueprints full-stack web apps and delegates to role agents |
| **Reviewers** | `llm_judge.md` | Evaluates code against a strict 10-point rubric |
| **Reviewers** | `feature-tracker.md` | Maps codebase architecture and tracks PRD gaps |

### Skills (Vocabulary)

Skills are passive documentation files that teach the AI the syntax, patterns, and pitfalls of specific frameworks. When you mention a framework, the AI reads the corresponding skill and generates tailored code.

| Category | Path | Skills |
|----------|------|--------|
| **AI Frameworks** | `skills/ai/frameworks/` | `langchain`, `autogen`, `crewai`, `smolagents`, `anthropic`, `openai` |
| **RAG & Retrieval** | `skills/ai/retrieval/` | `crag` (Corrective RAG), `llamaindex`, `financial-rag` |
| **Multimodal & Data** | `skills/ai/data/` | `multimodal-parsing`, `vision-api-syntax`, `synthetic-data` |
| **Prompt Engineering** | `skills/prompt_engineering/` | `cove` (Chain-of-Verification), `self-refine`, `prompt_chaining` |
| **Product** | `skills/product/` | `PRD` (Product Requirements Documents), `PEAS` (Agent Design Documents) |
| **Backend** | `skills/backend/` | `fastapi_architecture`, `sql_postgres`, `supabase_rls` |
| **Frontend** | `skills/frontend/` | `react_best_practices`, `tailwind_design_system`, `forms_validation`, `sanity_cms`, `framer_motion`, `react_three_fiber` |
| **Database** | `skills/database/` | `migrations`, `vector_dbs` |
| **DevOps** | `skills/devops/` | `docker_best_practices`, `github_actions` |
| **Payments** | `skills/payments/` | `stripe`, `mercadopago`, `paypal` |
| **Security** | `skills/security/` | `sast`, `secrets_scanning`, `dependency_audit` |
| **QA** | `skills/qa/` | `testing_pytest`, `testing_jest`, `static_analysis_mypy`, `linting_ruff` |

---

## How the Layers Work Together

The three layers complement each other in a continuous quality loop:

1. A **PRD** or **PEAS Agent Design Document** defines what to build (product or AI specification).
2. The **`fullstack_architect`** blueprints the web application and produces a delegation map for role agents.
3. If the app includes an AI subsystem, **`agentic_ai_architect`** selects the right pattern (RAG, multi-agent, multimodal) and loads the matching skills.
4. **Role agents** (backend, frontend, database, devops, qa) implement their portions following loaded skills.
5. **`llm_judge`** evaluates the generated code against the skill's patterns and scores it.
6. Throughout the process, **Rules** silently enforce security, model selection, and evaluation standards.

---

## The Self-Correction Loop

Our AI doesn't just write code — it learns. Every agent in this repository is mandated to:

1. **Read** [`tasks/self-correction.md`](tasks/self-correction.md) at the start of every session.
2. **Log** any unexpected errors, deprecations, or hallucinations with a structured entry.
3. **Apply** past lessons proactively, avoiding known pitfalls before they happen.

This creates a **compound learning effect**: every mistake one developer's AI encounters becomes institutional knowledge for the entire team.

---

## Project Structure

```
agentic-playbook/
├── resources/                           The AI knowledge base
│   ├── rules/                              Project-wide guardrails
│   │   ├── code_quality/                   Type safety, agent behavior
│   │   ├── security/                       API key management
│   │   ├── llm_standards/                  Model selection, multimodal routing
│   │   └── evaluation/                     RAG eval, eval-driven development
│   ├── agents/                             Workflow personas
│   │   ├── roles/                          Role-based agents (backend, frontend, qa, devops, etc.)
│   │   ├── reviewers/                      LLM judge, feature tracker
│   │   └── architects/                     Agentic AI architect, Full Stack architect
│   └── skills/                             Framework templates
│       ├── ai/                             AI-domain skills
│       │   ├── frameworks/                 AutoGen, CrewAI, LangChain, OpenAI, Anthropic, SmolAgents
│       │   ├── retrieval/                  CRAG, LlamaIndex, Financial RAG
│       │   └── data/                       PDF parsing, Vision APIs, Synthetic data
│       ├── prompt_engineering/             CoVe, Self-Refine, Prompt Chaining
│       ├── product/                        PRD templates, PEAS agent design
│       ├── backend/                        FastAPI, SQL/Postgres, Supabase RLS
│       ├── frontend/                       React, Tailwind, Sanity CMS, Framer Motion
│       ├── database/                       Migrations, Vector DBs
│       ├── devops/                         Docker, GitHub Actions
│       ├── payments/                       Stripe, MercadoPago, PayPal
│       ├── security/                       SAST, Secrets scanning, Dependency audit
│       └── qa/                             Pytest, Jest, Mypy, Ruff
├── docs/                                   Project documentation
│   ├── BUILD_PLAYBOOK.md                   Step-by-step guide: what to build first and in what order
│   ├── AGENTS.md                           Behavioral orchestration protocol
│   └── CONTRIBUTING.md                     How to add skills, agents, and rules
├── tasks/                                  AI working memory
│   ├── todo.md                             Canonical task tracker
│   └── self-correction.md                  Learning database
├── scripts/                                Tooling
│   ├── setup_cursor.sh                     Cursor integration (macOS/Linux)
│   └── setup_cursor.ps1                    Cursor integration (Windows)
├── .gitignore                              Security-first ignore patterns
└── README.md                               You are here
```

---

## Editor Integration

This repository is **editor-agnostic**. The `resources/` folder is plain Markdown — usable in any AI-powered editor, or even copy-pasted into web-based LLM interfaces.

### Cursor IDE

We provide setup scripts that symlink `resources/` into Cursor's expected `.cursor/` directory:

| Platform | Command |
|----------|---------|
| macOS / Linux | `bash scripts/setup_cursor.sh` |
| Windows | `powershell -ExecutionPolicy Bypass -File scripts\setup_cursor.ps1` |

This enables automatic rule enforcement and `@` mention discovery.

---

## Where to Start

Not sure how to use this playbook on a real project? Read **[docs/BUILD_PLAYBOOK.md](docs/BUILD_PLAYBOOK.md)** — the step-by-step guide that tells you which agent to invoke, in what order, and why.

---

## Contributing

We actively encourage the team to contribute new skills, agents, and rules.

**Adding a skill takes about 10 minutes.** Every skill follows a strict template (frontmatter, philosophy, trigger scenarios, implementation code, pitfalls, and self-correction mandate) to ensure consistency.

Read the full guide: **[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)**

### Quick Version

1. Pick the right category in `resources/skills/`.
2. Create a folder: `resources/skills/<category>/your-framework/`
3. Add a `SKILL.md` following the [template](docs/CONTRIBUTING.md#step-4--fill-out-the-template).
4. Open a PR with the prefix `feat(skills):`.

---

## Design Philosophy

| Principle | Implementation |
|-----------|---------------|
| **Autonomy** | Agents complete work without user intervention; ask only when genuinely blocked |
| **Correctness over speed** | A slower, correct solution beats a fast, broken one |
| **Continuous learning** | Every mistake is logged and never repeated |
| **Security hygiene** | No secrets in code; `.env` files are git-ignored by default |
| **Minimal blast radius** | Change only what needs to change; no unnecessary refactors |
| **Editor agnostic** | Knowledge lives in plain Markdown; editor integration is optional |

---

## License

This project is for internal use. See [LICENSE](LICENSE) for details.
