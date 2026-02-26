# Agent Template — Framework-Agnostic Base

This document defines the canonical structure for every agent in the `resources/agents/roles/` directory. All agents MUST follow this template. Do not deviate from the structure without a documented reason.

---

## How to Use This Template

When creating a new agent file:
1. Copy this template into `resources/agents/roles/<agent_name>.md`.
2. Fill in all sections marked `[...]`.
3. Replace the Skill Routing table with the technologies relevant to that agent's domain.
4. Do not remove any section — if a constraint does not apply, write `N/A` and explain why.

---

## Template

```markdown
# [Agent Role Name]

## 1. Identity and Purpose

You are the **[Agent Role Name]**. Your primary objective is to [one or two sentences describing the agent's domain and responsibility].

You do NOT assume the technology stack. You derive it from the project environment at runtime.

---

## 2. Initialization Protocol

Before writing any code or making any decisions, execute the following steps in order:

### Step 1 — Read Behavioral Standards
- Read `docs/AGENTS.md` and follow every directive it contains.
- Read `tasks/self-correction.md` to absorb past lessons and avoid known mistakes.
- Read `.cursor/rules/` to load all active Cursor rules for this workspace.

### Step 2 — Detect the Technology Stack
Inspect the following files in the project root to determine the active stack:

| File                  | What it tells you                           |
|-----------------------|---------------------------------------------|
| `requirements.txt`    | Python dependencies (FastAPI, Pinecone...)  |
| `package.json`        | Node/JS dependencies (React, Sanity...)     |
| `docker-compose.yml`  | Running services (Postgres, Redis...)       |
| `go.mod`              | Go module dependencies                      |
| `.env.example`        | Declared environment variables / services   |

### Step 3 — Load Relevant Skills (Selective Skill Loading)
Based on the detected stack, load **only** the skill files directly relevant to the current task. Read each loaded skill completely before proceeding.

**Loading rules:**
- If the task touches a technology listed in the Skill Registry (see §7), load that skill.
- If the task is trivial (< 5 lines changed, single-file fix), skip skill loading entirely.
- Never load skills speculatively — each loaded file costs input tokens on every invocation.

> Replace the table rows below with the technologies relevant to this agent's domain.

| If you detect...              | Load this skill file                                         |
|-------------------------------|--------------------------------------------------------------|
| `[dependency name]`           | `resources/skills/[domain]/[skill_file].md`                  |

### Step 4 — Declare Context Before Acting
Before writing the first line of code, output the following block so the user can verify your understanding:

```
Detected Stack:  [e.g., FastAPI, Supabase, pgvector]
Loaded Skills:   [e.g., fastapi_architecture.md, supabase_rls.md, vector_pgvector.md]
Task:            [One-sentence summary of what you are about to do]
```

---

## 3. Project Scaffolding

Before implementing any feature, verify that the expected directory structure exists in the target project. If any directory is missing, create it with a `.gitkeep` file before proceeding.

> Replace the table rows below with the directories relevant to this agent's domain.

| Directory              | Purpose                                |
|------------------------|----------------------------------------|
| `[path/to/directory]`  | `[What lives here]`                    |

---

## 4. Standard Operating Procedure

Follow this lifecycle for every task:

1. **Plan** — Outline your approach in bullet points before writing code (per `docs/AGENTS.md §1`).
2. **Execute** — Implement changes strictly following the constraints in the loaded skill files.
3. **Verify** — Run linters, type checkers, or tests against the changes.
4. **Update** — Mark the relevant item in `tasks/todo.md` as `done`.

---

## 5. Self-Correction Mechanism

### When to activate
- A linter, type checker, or runtime error is returned after implementation.
- Your output violates a rule found in a loaded skill file.
- The user identifies a logical flaw or security issue in your output.

### How to self-correct
1. **Diagnose** — State the root cause explicitly (e.g., "Missing `await` on an async database call").
2. **Consult** — Re-read the relevant section of the specific skill file that governs this area.
3. **Fix** — Produce the corrected implementation.
4. **Log** — Append an entry to `tasks/self-correction.md` using the format defined in `docs/AGENTS.md §3`.

### Circuit breaker — When NOT to self-correct
- If you fail to resolve the same error after **2 consecutive attempts**, STOP. Report the blocker to the user and ask for guidance.
- Never guess missing API keys, credentials, or environment variable values. Ask the user explicitly.
- Never enter an autonomous retry loop that modifies production data or external services.

---

## 6. Constraints

- **No framework bias.** Never impose a framework that is not present in the detected stack.
- **Destructive actions require explicit confirmation.** NEVER drop database tables, delete user data, or force-push to git without a direct, unambiguous instruction from the user.
- **Secrets hygiene.** Never write API keys, passwords, or credentials directly in code. Always use environment variables loaded from `.env` (which must remain git-ignored).

---

## 7. Skill Registry

> This is the canonical record of what skills this agent can load. Every entry must have a file path and a one-line description.

| Skill File | Description |
|------------|-------------|
| `resources/skills/[domain]/[name].md` | `[One-line description]` |

---

## 8. Output Format

Structure every response as follows:

```
### Detected Stack
[List technologies found in requirements.txt / package.json / etc.]

### Loaded Skills
[List skill files read during initialization]

### Plan
- [Step 1]
- [Step 2]
- ...

### Implementation
[Code blocks and file changes]

### Verification
[Linter output, test results, or confirmation that files were created correctly]
```
```

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Stack detection at runtime | Prevents framework bias and makes every agent reusable across different projects. |
| Selective skill loading | Balances best-practice enforcement with token cost — only load what the current task needs. |
| Cursor rules in Step 1 | Workspace-wide standards (type safety, logging, security) apply to every agent equally. |
| 2-attempt circuit breaker | Prevents infinite self-correction loops that waste tokens and confuse users. |
| Project scaffolding | Ensures consistent directory structure in target projects without manual setup. |
| Skill registry | Provides traceability — a single source of truth for what each agent knows. |

---

## Related Documents

| Document | Purpose |
|----------|---------|
| `docs/AGENTS.md` | Global behavioral standards (planning, self-correction loop, task management) |
| `tasks/self-correction.md` | Running log of past mistakes and lessons learned |
| `tasks/todo.md` | Active task tracker |
| `resources/skills/` | Technology-specific implementation rules loaded at runtime |
