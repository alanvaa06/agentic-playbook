# Process Skills Integration — Embed superpowers methodology into the Agentic Playbook

**Date:** 2026-05-01
**Status:** Draft (awaiting user review)
**Author:** Claude (brainstorming session)
**Supersedes:** none — replaces an earlier "install plugin and wire" draft that was discarded.

---

## 1. Purpose

Absorb the methodology of [obra/superpowers](https://github.com/obra/superpowers) directly into agentic-playbook so the repo ships with full lifecycle discipline (brainstorming → plan → TDD → verify → review → ship) **without any external plugin dependency**.

After this work, `git clone agentic-playbook` is enough. No marketplace install, no version pin, no per-editor setup beyond the existing optional Cursor symlink script.

---

## 2. Problem Statement

agentic-playbook today defines **what** an agent should know (frontend, backend, AI frameworks, payments). It does not define **how** the agent should work (write a plan first, write a failing test first, verify before claiming done, request a review).

obra/superpowers solves the *how* but only when installed as a plugin in a supported editor. That couples the playbook to:

- the user installing the plugin in every editor they use
- upstream skill renames silently breaking lifecycle wiring
- two different skill formats and namespaces coexisting in memory

**Goal:** make the playbook standalone. The methodology lives in the repo as first-class skills under `skills/shared/process/`, owned and versioned by the playbook itself.

---

## 3. Non-Goals

- Forking obra/superpowers as a maintained downstream. We vendor a snapshot, then own it.
- Re-implementing every superpowers skill. Pick the ones that belong in a *general* engineering playbook; skip ones that are too Claude-Code-specific.
- Touching role-agent skill content (frontend, backend, etc.). Domain knowledge is unchanged.
- Editing scripts or CI in this spec. Pure docs + new skill files.

---

## 4. Architecture

Single-repo, two skill buckets — both colocated under `skills/`.

```
agentic-playbook/
├── AGENTS.md                         lifecycle gates live here
├── agents/<role>/<role>.md           role definitions reference process gates
├── skills/
│   ├── <role>/                       domain knowledge (unchanged)
│   └── shared/
│       ├── product/                  PRD, PEAS  (already exists)
│       ├── prompt_engineering/       CoVe, Self-Refine  (already exists)
│       └── process/                  NEW — vendored + adapted process skills
│           ├── brainstorming/SKILL.md
│           ├── writing-plans/SKILL.md
│           ├── executing-plans/SKILL.md
│           ├── subagent-driven-development/SKILL.md
│           ├── test-driven-development/SKILL.md
│           ├── systematic-debugging/SKILL.md
│           ├── verification-before-completion/SKILL.md
│           ├── using-git-worktrees/SKILL.md
│           ├── requesting-code-review/SKILL.md
│           ├── receiving-code-review/SKILL.md
│           ├── finishing-a-development-branch/SKILL.md
│           ├── dispatching-parallel-agents/SKILL.md
│           └── using-process-skills/SKILL.md     (renamed from using-superpowers)
└── docs/
    └── process/
        ├── specs/                    this spec lives here
        ├── SKILL_INDEX.md            phase → skill mapping
        ├── USAGE.md                  how to invoke a phase manually
        └── CREDITS.md                attribution + upstream snapshot version
```

No second source of truth. No external lookup. The repo is the system.

---

## 5. Skills to Vendor

13 skills picked from obra/superpowers. Each gets a fresh `SKILL.md` rewritten to match playbook conventions (YAML frontmatter, role-agent cross-references, link to `context/tasks/self-correction.md`).

| # | Source skill (obra) | Vendored as | Notes |
|---|---|---|---|
| 1 | `brainstorming` | `skills/shared/process/brainstorming/` | Spec output path adjusted to `docs/process/specs/` |
| 2 | `writing-plans` | `skills/shared/process/writing-plans/` | Plans saved under `context/tasks/plans/` |
| 3 | `executing-plans` | `skills/shared/process/executing-plans/` | — |
| 4 | `subagent-driven-development` | `skills/shared/process/subagent-driven-development/` | References AGENTS.md §2 subagent strategy |
| 5 | `test-driven-development` | `skills/shared/process/test-driven-development/` | Cross-links `qa_agent` skills (pytest/jest/mypy/ruff) |
| 6 | `systematic-debugging` | `skills/shared/process/systematic-debugging/` | Reads/writes `context/tasks/self-correction.md` (AGENTS.md §3) |
| 7 | `verification-before-completion` | `skills/shared/process/verification-before-completion/` | Mirrors AGENTS.md §4 |
| 8 | `using-git-worktrees` | `skills/shared/process/using-git-worktrees/` | — |
| 9 | `requesting-code-review` | `skills/shared/process/requesting-code-review/` | Cross-links `llm_judge` rubric |
| 10 | `receiving-code-review` | `skills/shared/process/receiving-code-review/` | — |
| 11 | `finishing-a-development-branch` | `skills/shared/process/finishing-a-development-branch/` | — |
| 12 | `dispatching-parallel-agents` | `skills/shared/process/dispatching-parallel-agents/` | Used by `fullstack_architect` delegation map |
| 13 | `using-superpowers` | `skills/shared/process/using-process-skills/` | **Renamed.** Becomes the entry-point skill that introduces the process bucket. |

Skills **not** vendored: `writing-skills` (playbook already has `docs/skill-template.md` + CONTRIBUTING.md guide).

---

## 6. Lifecycle Wiring

| # | Phase | Process skill | Knowledge loaded |
|---|---|---|---|
| 1 | Define problem | `brainstorming` | `shared/product/PRD`, `shared/product/PEAS` |
| 2 | Blueprint | (continues `brainstorming`) | `agents/fullstack_architect`, optionally `agentic_ai_architect` |
| 3 | Plan | `writing-plans` | role skills referenced by blueprint |
| 4 | Isolate workspace | `using-git-worktrees` | — |
| 5 | Execute | `subagent-driven-development` *or* `executing-plans` | colocated `skills/<role>/` |
| 6 | Test discipline | `test-driven-development` | `qa_agent/*` |
| 7 | Debug | `systematic-debugging` | `context/tasks/self-correction.md` |
| 8 | Verify | `verification-before-completion` | `resources/rules/evaluation/*` |
| 9 | Review | `requesting-code-review` → `receiving-code-review` | `agents/llm_judge` |
| 10 | Ship | `finishing-a-development-branch` | — |

Phases 1–3 run once per feature. Phases 5–9 loop per task in the plan.

---

## 7. Adaptation Rules (when rewriting each vendored skill)

When the vendored copy is written, change the following from the upstream version:

1. **Frontmatter** — match playbook's existing `SKILL.md` style (see `skills/agentic_ai_architect/frameworks/anthropic/SKILL.md` as template).
2. **File-path references** — rewrite paths to playbook layout (e.g., upstream `docs/specs/` → `docs/process/specs/`; plans → `context/tasks/plans/`).
3. **Cross-references** — replace upstream skill names with playbook paths (e.g., "see writing-plans skill" → "see [skills/shared/process/writing-plans/SKILL.md]").
4. **Self-correction hook** — every vendored skill that touches errors/debugging/verification must point at `context/tasks/self-correction.md` per AGENTS.md §3.
5. **Editor-agnostic phrasing** — drop Claude-Code-specific tool names (e.g., "Skill tool", "TodoWrite") in favor of generic language. Keep YAML frontmatter so editors that *do* support auto-trigger still work.
6. **Length** — preserve substance; shorten ceremony.

---

## 8. AGENTS.md Updates

Append a single new section:

> **§10 Process Gates**
>
> Every non-trivial task flows through the 10-phase lifecycle defined in [docs/process/SKILL_INDEX.md](docs/process/SKILL_INDEX.md). Skip a phase only when the task is genuinely trivial (single-file, < 5 lines — same threshold as §1). When in doubt, run the gate.

No edits to existing §1–§9. The new §10 references the index file; the index file references the skills. Single arrow of indirection.

---

## 9. Role Agent Updates

Each of the 10 role-agent definitions (`agents/<role>/<role>.md`) gets a small **Process Gates** stanza appended, listing which lifecycle phases that role most often participates in. Examples:

- `qa_agent` → phases 6, 8 (TDD + verification)
- `security_agent` → phase 9 (review) + always-on `resources/rules/security/*`
- `fullstack_architect` → phases 1–3, plus `dispatching-parallel-agents` for delegation
- `llm_judge` → phase 9 (consumes `requesting-code-review` output)

The stanza is informational. Lifecycle is enforced by AGENTS.md §10, not by the role file.

---

## 10. New Documentation

- `docs/process/SKILL_INDEX.md` — two tables: phase→skill, skill→phase. No prose.
- `docs/process/USAGE.md` — short guide: how to manually invoke a phase, how phases chain, how to skip.
- `docs/process/CREDITS.md` — attribution to obra/superpowers (MIT). Lists upstream commit SHA and version snapshot date so future syncs have a baseline.

---

## 11. Boundaries & Interfaces

- **AGENTS.md** — single source of truth for lifecycle order. Knows phase names, not skill internals.
- **SKILL_INDEX.md** — pure mapping. Two tables.
- **Process skill** — self-contained `SKILL.md`, frontmatter + body. No imports, no runtime deps.
- **Role agent definitions** — declare which phases they ride. Don't redocument phases.
- **Domain skills** — implementation knowledge only. Don't reference process internals (process skills can reference domain, not vice versa).

If a process skill needs revision, only its own `SKILL.md` changes. If the lifecycle order changes, only `AGENTS.md §10` + `SKILL_INDEX.md` change.

---

## 12. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Vendored skills drift from upstream over time | `CREDITS.md` records upstream snapshot SHA. A future optional sync script (out of scope here) can diff. Most process skills are stable. |
| 13 new skills bloat the repo | Each is a single `SKILL.md` of a few hundred lines. Total < 5k LOC of markdown. Trivial. |
| User already has obra/superpowers plugin installed → name shadowing | Different namespace (`skills/shared/process/<name>/SKILL.md` vs plugin path). Plugin still wins for auto-trigger if both present. Document in `USAGE.md`: prefer playbook copy in editors that read both. |
| Adaptation introduces bugs vs upstream | Each vendored skill is a self-contained markdown doc — no executable code. Worst case is wording drift, easy to patch. |
| MIT attribution missed | `CREDITS.md` is part of acceptance criteria. |

---

## 13. Acceptance Criteria

1. `skills/shared/process/` contains 13 `SKILL.md` files matching §5.
2. `docs/process/SKILL_INDEX.md` lists every process skill mapped to ≥1 lifecycle phase.
3. `docs/process/CREDITS.md` records upstream commit SHA + MIT notice.
4. `AGENTS.md §10` exists.
5. Every role-agent `.md` has a Process Gates stanza.
6. `git grep -i "obra/superpowers"` returns hits only inside `docs/process/CREDITS.md` and this spec — no live wiring.
7. Repo functions identically with or without obra/superpowers plugin installed.
8. **All skills carry YAML frontmatter** (`name` + `description`). 16/45 already do; the remaining 29 flat `.md` files get headers added. Frontmatter audit verified by a one-liner: `find skills -name "*.md" | while read f; do head -1 "$f" | grep -q "^---$" || echo "MISSING: $f"; done` returns nothing.
9. **Plugin manifest exists** at `.claude-plugin/plugin.json` (or vendor-correct path) declaring name, version, agents, skills, commands paths — see §15.
10. **Marketplace entry exists** so `/plugin install agentic-playbook@<marketplace>` works in Claude Code; verified by a fresh install in a clean profile.

---

## 14. Out of Scope (deferred)

- Auto-sync script that diffs vendored copies vs upstream.
- Migrating existing `context/tasks/` layout (todo.md, self-correction.md) into a richer plan/spec structure.
- Per-editor (Cursor, Claude Code, Codex, Gemini) auto-trigger validation matrix beyond a smoke test.
- Hooks (`.claude-plugin/hooks/`) — events that fire on tool use. Adds value (e.g., auto-log to self-correction on test failure) but expands scope. Defer to follow-up.

---

## 15. Distribution as Plugin

The repo serves two distribution channels from a single source tree:

### 15.1 Channels

| Channel | Audience | How they consume |
|---|---|---|
| `git clone` | Editor-agnostic users, Cursor with symlink script, web LLM paste, plain markdown readers | Read `agents/`, `skills/`, `resources/` directly |
| Plugin install | Claude Code, Codex, Gemini CLI, Copilot CLI, Cursor (via `/add-plugin`) users | `/plugin install agentic-playbook@<marketplace>` registers same files for auto-discovery + auto-trigger |

Same files, two front doors.

### 15.2 Manifest

Add `.claude-plugin/plugin.json` at repo root:

```json
{
  "name": "agentic-playbook",
  "version": "0.1.0",
  "description": "Role-based agent skills + embedded process discipline (brainstorm, plan, TDD, verify, review, ship).",
  "author": "alanvaa06",
  "license": "MIT",
  "agents": "agents/",
  "skills": "skills/",
  "commands": "commands/",
  "rules": "resources/rules/"
}
```

Exact field names follow whatever the Claude plugin spec requires at the time of writing; this spec records intent, not the literal schema. Resolve schema during implementation by inspecting `~/.claude/plugins/cache/claude-plugins-official/superpowers/` as reference.

### 15.3 Commands folder

New top-level `commands/` directory mirroring obra/superpowers' pattern. Each command is a thin markdown wrapper that dispatches to a process skill:

```
commands/
├── brainstorm.md         → invokes skills/shared/process/brainstorming
├── write-plan.md         → invokes skills/shared/process/writing-plans
├── execute-plan.md       → invokes skills/shared/process/executing-plans
└── ship.md               → invokes skills/shared/process/finishing-a-development-branch
```

Lets users type `/brainstorm` instead of relying on auto-trigger.

### 15.4 Frontmatter audit (promoted from deferred)

Every `.md` skill file gets YAML frontmatter:

```yaml
---
name: <slug-matching-folder-or-filename>
description: <one sentence: when to use, what it covers — drives auto-trigger>
---
```

29 files identified earlier need headers added. Body unchanged. Existing 16 `SKILL.md` files already compliant.

### 15.5 Marketplace

Two paths:

- **Own marketplace** — create `agentic-playbook-marketplace` repo following obra/superpowers-marketplace pattern. Users register: `/plugin marketplace add alanvaa06/agentic-playbook-marketplace` then `/plugin install agentic-playbook`.
- **Submit to existing** — apply to Anthropic's official marketplace once skill set + tests stabilize.

Start with own marketplace. Submit upstream after 0.2.0.

### 15.6 Versioning + release

- Semver in `plugin.json`.
- Tagged releases (`v0.1.0`) on git for marketplace consumers.
- `RELEASE-NOTES.md` at repo root listing user-visible changes per version.
- README install section gets a code block per channel.

### 15.7 Backwards compatibility

Pre-plugin users (cloners, Cursor symlink users) keep working. The manifest is additive — its absence is the current state, its presence enables a new channel without breaking the old one.
