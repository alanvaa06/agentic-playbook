# Process Skills — Usage Guide

## Two ways to consume this repo

### A. `git clone` (editor-agnostic)

```bash
git clone https://github.com/<your-org>/agentic-playbook.git
cd agentic-playbook
```

Open in any editor. Skills are markdown — readable by Cursor, plain VS Code, web LLM paste, etc.

For Cursor auto-rules:

```bash
bash scripts/setup_cursor.sh           # macOS / Linux
powershell -ExecutionPolicy Bypass -File scripts\setup_cursor.ps1   # Windows
```

### B. Plugin install (Claude Code, Codex, Gemini, Copilot, Cursor)

```bash
/plugin marketplace add <your-org>/agentic-playbook-marketplace
/plugin install agentic-playbook
```

Skills now auto-trigger when their `description` matches your task.

## Manually invoking a phase

Even with auto-trigger, you can pin a phase explicitly:

| Want to… | Run |
|---|---|
| Brainstorm a new feature | `/brainstorm` |
| Write the implementation plan | `/write-plan` |
| Execute the plan | `/execute-plan` |
| Wrap up and merge | `/ship` |

Or invoke any process skill by reading its file: `skills/shared/process/<name>/SKILL.md`.

## Phase order

See [SKILL_INDEX.md](SKILL_INDEX.md). Phases 1–3 once per feature; phases 5–9 loop per task in the plan.

## Skipping a phase

Permitted only when the task is genuinely trivial (single file, < 5 lines). When in doubt, run the gate. AGENTS.md §1 + §10 are authoritative.

## Coexistence with obra/superpowers

If the user has the upstream `obra/superpowers` plugin installed alongside this repo, both sets of process skills load. They have the same shape and intent. Prefer the playbook copy under `skills/shared/process/` because it carries the playbook-specific cross-references (qa_agent, llm_judge, self-correction.md). The upstream version still works as a fallback.
