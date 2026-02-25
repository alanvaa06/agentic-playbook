# Agentic Standards

**A curated knowledge base of AI agent patterns, framework skills, and engineering standards for financial analysis and robust Python development.**

Building AI agents often leads to messy, inconsistent code — each developer reinventing patterns, hardcoding API keys, and defaulting to whatever LLM the tutorial used. This repository solves that by providing a **three-layered AI orchestration system** (Skills, Agents, and Rules) that any team member can reference, and that integrates seamlessly with AI-powered editors like Cursor.

---

## Quick Start

```bash
git clone https://github.com/<your-org>/agentic-standards.git
cd agentic-standards
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
| **Reviewers** | `code-reviewer.md` | Static analysis, architecture audits, consistency enforcement |
| **Reviewers** | `test-reporter.md` | Runs pytest + mypy, diagnoses failures, produces QA dashboards |
| **Architects** | `agentic_rag_architect.md` | Guides RAG system design through a discovery questionnaire |
| **Orchestrators** | `prompt_chainer.md` | Decomposes complex tasks into sequential, user-approved steps |
| **Orchestrators** | `llm_judge.md` | Evaluates code against a strict 10-point rubric |

### Skills (Vocabulary)

Skills are passive documentation files that teach the AI the syntax, patterns, and pitfalls of specific frameworks. When you mention a framework, the AI reads the corresponding skill and generates tailored code.

| Category | Skills |
|----------|--------|
| **Multi-Agent Frameworks** | `autogen`, `crewai`, `smolagents`, `langchain`, `anthropic`, `openai` |
| **RAG & Retrieval** | `crag` (Corrective RAG), `llamaindex`, `financial-rag` |
| **Multimodal & Data** | `multimodal-parsing`, `vision-api-syntax`, `synthetic-data` |
| **Prompt Engineering** | `cove` (Chain-of-Verification), `self-refine` |
| **Product** | `prd` (Product Requirements Documents) |

---

## How the Layers Work Together

The three layers complement each other in a continuous quality loop:

1. **`agentic_rag_architect`** asks discovery questions and proposes a CRAG architecture.
2. The AI reads **`skills/rag_and_retrieval/crag/SKILL.md`** to generate the implementation.
3. **`llm_judge`** evaluates the generated code against the skill's patterns and scores it.
4. If the Judge finds issues, **`prompt_chainer`** breaks the fix into sequential steps.
5. Throughout the process, **Rules** silently enforce security, model selection, and evaluation standards.

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
agentic-standards/
├── resources/                           The AI knowledge base
│   ├── rules/                              Project-wide guardrails
│   │   ├── code_quality/                   Type safety, agent behavior
│   │   ├── security/                       API key management
│   │   ├── llm_standards/                  Model selection, multimodal routing
│   │   └── evaluation/                     RAG eval, eval-driven development
│   ├── agents/                             Workflow personas
│   │   ├── reviewers/                      Code reviewer, test reporter
│   │   ├── architects/                     RAG architect
│   │   └── orchestrators/                  Prompt chainer, LLM judge
│   └── skills/                             Framework templates
│       ├── multi_agent_frameworks/         AutoGen, CrewAI, LangChain, etc.
│       ├── rag_and_retrieval/              CRAG, LlamaIndex, Financial RAG
│       ├── multimodal_and_data/            PDF parsing, Vision APIs, Synthetic data
│       ├── prompt_engineering/             CoVe, Self-Refine
│       └── product/                        PRD templates
├── docs/                                   Project documentation
│   ├── AGENTS.md                           Behavioral orchestration protocol
│   └── CONTRIBUTING.md                     How to add skills, agents, and rules
├── tasks/                                  AI working memory
│   ├── todo.md                             Canonical task tracker
│   └── self-correction.md                  Learning database
├── scripts/                                Tooling
│   ├── setup_cursor.sh                     Cursor integration (macOS/Linux)
│   └── setup_cursor.ps1                    Cursor integration (Windows)
├── src/                                    Production code
├── tests/                                  Test suite
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
