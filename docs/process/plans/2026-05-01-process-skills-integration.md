# Process Skills Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Embed obra/superpowers methodology into agentic-playbook as native skills under `skills/shared/process/` and ship the repo as a Claude Code plugin alongside the existing `git clone` workflow.

**Architecture:** Vendor 13 process skills (brainstorm → ship lifecycle), wire them via `AGENTS.md §10` and `docs/process/SKILL_INDEX.md`, normalize all skill files to YAML frontmatter, add `.claude-plugin/plugin.json` + `commands/` + own marketplace repo. Two distribution channels (clone, plugin) from one source tree.

**Tech Stack:** Markdown w/ YAML frontmatter, JSON manifest, git, gh CLI. No code changes.

**Spec:** [docs/process/specs/2026-05-01-process-skills-integration-design.md](../specs/2026-05-01-process-skills-integration-design.md)

**Upstream snapshot:** obra/superpowers commit `e7a2d16476bf042e9add4699c9d018a90f86e4a6` (2026-05-01).

---

## File Structure

### New files

```
.claude-plugin/
└── plugin.json                                   plugin manifest
commands/
├── brainstorm.md                                 wrapper → process/brainstorming
├── write-plan.md                                 wrapper → process/writing-plans
├── execute-plan.md                               wrapper → process/executing-plans
└── ship.md                                       wrapper → process/finishing-a-development-branch
docs/process/
├── CREDITS.md                                    obra MIT attribution + SHA
├── SKILL_INDEX.md                                phase ↔ skill mapping
├── USAGE.md                                      manual invocation guide
├── specs/2026-05-01-process-skills-integration-design.md   (already exists)
└── plans/2026-05-01-process-skills-integration.md          (this file)
skills/shared/process/
├── brainstorming/SKILL.md
├── writing-plans/SKILL.md
├── executing-plans/SKILL.md
├── subagent-driven-development/SKILL.md
├── test-driven-development/SKILL.md
├── systematic-debugging/SKILL.md
├── verification-before-completion/SKILL.md
├── using-git-worktrees/SKILL.md
├── requesting-code-review/SKILL.md
├── receiving-code-review/SKILL.md
├── finishing-a-development-branch/SKILL.md
├── dispatching-parallel-agents/SKILL.md
└── using-process-skills/SKILL.md                 (renamed from upstream using-superpowers)
RELEASE-NOTES.md                                  v0.1.0 entry
```

### Modified files

- `AGENTS.md` — append `§10 Process Gates`
- `agents/<role>/<role>.md` (10 files) — append Process Gates stanza
- `skills/<role>/**/*.md` (29 flat domain files) — add YAML frontmatter
- `README.md` — add plugin install section

### Single-responsibility note

Each `SKILL.md` owns one phase of the lifecycle. Each role-agent file declares which phases it rides. Manifest knows nothing about phases. Index file is the only place phase↔skill mapping lives.

---

## Task 1: Capture upstream attribution

**Files:**
- Create: `docs/process/CREDITS.md`

- [ ] **Step 1: Write CREDITS.md**

```markdown
# Credits

The process skills under `skills/shared/process/` are adapted from
[obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent
(MIT License).

**Upstream snapshot:** commit `e7a2d16476bf042e9add4699c9d018a90f86e4a6`
**Snapshot date:** 2026-05-01
**License:** MIT — see https://github.com/obra/superpowers/blob/main/LICENSE

## Adaptations

- Frontmatter rewritten to match agentic-playbook conventions
- File-path references rewritten (`docs/superpowers/` → `docs/process/`,
  plans → `context/tasks/plans/`)
- Cross-references rewritten to playbook skill paths
- Self-correction hook added (`context/tasks/self-correction.md`, see AGENTS.md §3)
- `using-superpowers` renamed to `using-process-skills`
- `writing-skills` skill not vendored (playbook has its own
  `docs/skill-template.md` + `docs/CONTRIBUTING.md`)

## Original MIT License

```
MIT License

Copyright (c) 2025 Jesse Vincent

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
```

- [ ] **Step 2: Verify file written**

Run: `ls docs/process/CREDITS.md && head -5 docs/process/CREDITS.md`
Expected: file shown, header line printed.

- [ ] **Step 3: Commit**

```bash
git add docs/process/CREDITS.md
git commit -m "docs(process): add upstream attribution and MIT credits"
```

---

## Task 2: Vendor `brainstorming` skill

**Files:**
- Create: `skills/shared/process/brainstorming/SKILL.md`
- Reference source: `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/brainstorming/SKILL.md`

- [ ] **Step 1: Read upstream skill**

Run: `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/brainstorming/SKILL.md`
Expected: full skill body.

- [ ] **Step 2: Write adapted copy**

Copy upstream body. Apply adaptations from spec §7:

1. **Frontmatter:** keep `name: brainstorming` and `description:`. Description must include trigger phrase ("Use this before any creative work — creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.").
2. **Path rewrites:**
   - `docs/specs/` → `docs/process/specs/`
   - `docs/superpowers/specs/` → `docs/process/specs/`
3. **Cross-reference rewrites:**
   - `writing-plans skill` → `[skills/shared/process/writing-plans/SKILL.md]`
   - any `frontend-design`/`mcp-builder` references → leave as-is (still external suggestions)
4. **Self-correction hook:** add a paragraph near the bottom: "If clarifying questions surface a recurring confusion (e.g., the user has corrected the same misconception twice), log it in `context/tasks/self-correction.md` per AGENTS.md §3."
5. **Editor-agnostic phrasing:** replace `Skill tool` mentions with `the relevant process skill`. Keep YAML frontmatter — it still drives auto-trigger in Claude Code/Cursor/Codex.

Save adapted body to `skills/shared/process/brainstorming/SKILL.md`.

- [ ] **Step 3: Verify frontmatter present**

Run:
```bash
head -1 skills/shared/process/brainstorming/SKILL.md
```
Expected: `---`

Run:
```bash
grep -c "^name: brainstorming$" skills/shared/process/brainstorming/SKILL.md
grep -c "^description:" skills/shared/process/brainstorming/SKILL.md
```
Expected: both `1`.

- [ ] **Step 4: Verify path rewrites applied**

Run: `grep -n "docs/superpowers" skills/shared/process/brainstorming/SKILL.md || echo "OK no leaks"`
Expected: `OK no leaks`.

- [ ] **Step 5: Commit**

```bash
git add skills/shared/process/brainstorming/SKILL.md
git commit -m "feat(process): vendor brainstorming skill from obra/superpowers"
```

---

## Task 3: Vendor `writing-plans` skill

**Files:**
- Create: `skills/shared/process/writing-plans/SKILL.md`
- Reference source: `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/writing-plans/SKILL.md`

- [ ] **Step 1: Read upstream skill**

Run: `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/writing-plans/SKILL.md`

- [ ] **Step 2: Write adapted copy**

Same adaptation rules as Task 2. Specific path rewrites:
- `docs/superpowers/plans/` → `docs/process/plans/` (plan output dir)
- `docs/superpowers/specs/` → `docs/process/specs/`
- References to `subagent-driven-development` and `executing-plans` → playbook paths under `skills/shared/process/`

Save to `skills/shared/process/writing-plans/SKILL.md`.

- [ ] **Step 3: Verify frontmatter + paths**

```bash
head -1 skills/shared/process/writing-plans/SKILL.md
grep -n "docs/superpowers" skills/shared/process/writing-plans/SKILL.md || echo "OK no leaks"
```
Expected: `---`, then `OK no leaks`.

- [ ] **Step 4: Commit**

```bash
git add skills/shared/process/writing-plans/SKILL.md
git commit -m "feat(process): vendor writing-plans skill from obra/superpowers"
```

---

## Task 4: Vendor `executing-plans` skill

**Files:** Create `skills/shared/process/executing-plans/SKILL.md`

- [ ] **Step 1: Read upstream**

Run: `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/executing-plans/SKILL.md`

- [ ] **Step 2: Adapt + write**

Apply spec §7 rules. Path rewrites: plan dir → `docs/process/plans/`. Cross-refs to other process skills → `skills/shared/process/<name>/SKILL.md`.

- [ ] **Step 3: Verify**

```bash
head -1 skills/shared/process/executing-plans/SKILL.md
grep -n "docs/superpowers" skills/shared/process/executing-plans/SKILL.md || echo "OK no leaks"
```

- [ ] **Step 4: Commit**

```bash
git add skills/shared/process/executing-plans/SKILL.md
git commit -m "feat(process): vendor executing-plans skill from obra/superpowers"
```

---

## Task 5: Vendor `subagent-driven-development` skill

**Files:** Create `skills/shared/process/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/subagent-driven-development/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules. Cross-link to `AGENTS.md §2 Subagent Strategy` (already mandates self-contained prompts) and to `agents/fullstack_architect/fullstack_architect.md` for delegation patterns.
- [ ] **Step 3: Verify.** `head -1 skills/shared/process/subagent-driven-development/SKILL.md` → `---`. `grep -n "docs/superpowers" skills/shared/process/subagent-driven-development/SKILL.md || echo "OK no leaks"`.
- [ ] **Step 4: Commit.** `git add skills/shared/process/subagent-driven-development/SKILL.md && git commit -m "feat(process): vendor subagent-driven-development skill from obra/superpowers"`

---

## Task 6: Vendor `test-driven-development` skill

**Files:** Create `skills/shared/process/test-driven-development/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/test-driven-development/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules. Add cross-links section: "Framework specifics: see [skills/qa_agent/testing_pytest.md], [skills/qa_agent/testing_jest.md], [skills/qa_agent/static_analysis_mypy.md], [skills/qa_agent/linting_ruff.md]."
- [ ] **Step 3: Verify.** Frontmatter + no path leaks (same pattern as Task 5).
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor test-driven-development skill from obra/superpowers"`

---

## Task 7: Vendor `systematic-debugging` skill

**Files:** Create `skills/shared/process/systematic-debugging/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/systematic-debugging/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules. Add explicit step: "Before diagnosis, read `context/tasks/self-correction.md` for prior similar failures (AGENTS.md §3). After resolution, append the lesson per AGENTS.md §3 schema."
- [ ] **Step 3: Verify.** Frontmatter + no path leaks. Run: `grep -c "self-correction" skills/shared/process/systematic-debugging/SKILL.md` → ≥1.
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor systematic-debugging skill from obra/superpowers"`

---

## Task 8: Vendor `verification-before-completion` skill

**Files:** Create `skills/shared/process/verification-before-completion/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/verification-before-completion/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules. Add cross-link: "Mirrors AGENTS.md §4 — never claim done without evidence." Reference `resources/rules/evaluation/*` as the playbook's existing always-on guardrails.
- [ ] **Step 3: Verify.** Frontmatter + no path leaks.
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor verification-before-completion skill from obra/superpowers"`

---

## Task 9: Vendor `using-git-worktrees` skill

**Files:** Create `skills/shared/process/using-git-worktrees/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/using-git-worktrees/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules. Note Windows quirk: worktree paths must use forward slashes when invoked from bash (since playbook author uses Windows + bash per CLAUDE setup). Add a short subsection: "On Windows: use `git worktree add ../<branch>` from a bash shell to avoid backslash escaping; PowerShell works with native paths."
- [ ] **Step 3: Verify.** Frontmatter + no path leaks. `grep -c "Windows" skills/shared/process/using-git-worktrees/SKILL.md` → ≥1.
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor using-git-worktrees skill from obra/superpowers"`

---

## Task 10: Vendor `requesting-code-review` skill

**Files:** Create `skills/shared/process/requesting-code-review/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/requesting-code-review/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules. Add cross-link: "Output of this skill feeds [agents/llm_judge/llm_judge.md] for 10-point rubric scoring."
- [ ] **Step 3: Verify.** Frontmatter + no path leaks.
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor requesting-code-review skill from obra/superpowers"`

---

## Task 11: Vendor `receiving-code-review` skill

**Files:** Create `skills/shared/process/receiving-code-review/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/receiving-code-review/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules.
- [ ] **Step 3: Verify.** Frontmatter + no path leaks.
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor receiving-code-review skill from obra/superpowers"`

---

## Task 12: Vendor `finishing-a-development-branch` skill

**Files:** Create `skills/shared/process/finishing-a-development-branch/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/finishing-a-development-branch/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules.
- [ ] **Step 3: Verify.** Frontmatter + no path leaks.
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor finishing-a-development-branch skill from obra/superpowers"`

---

## Task 13: Vendor `dispatching-parallel-agents` skill

**Files:** Create `skills/shared/process/dispatching-parallel-agents/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/dispatching-parallel-agents/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules. Add cross-link: "Used by [agents/fullstack_architect/fullstack_architect.md] for delegation maps and by [agents/agentic_ai_architect/agentic_ai_architect.md] for parallel analysis tasks."
- [ ] **Step 3: Verify.** Frontmatter + no path leaks.
- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor dispatching-parallel-agents skill from obra/superpowers"`

---

## Task 14: Vendor + rename `using-superpowers` → `using-process-skills`

**Files:** Create `skills/shared/process/using-process-skills/SKILL.md`

- [ ] **Step 1: Read upstream** — `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/using-superpowers/SKILL.md`
- [ ] **Step 2: Adapt + write.** Apply §7 rules + rename:
  - Frontmatter `name: using-process-skills`
  - Description: "Use when starting any conversation — establishes how to find and use the process skills under `skills/shared/process/`. Required reading before any task."
  - Replace every "Superpowers" / "superpowers" mention with "process skills" or the specific skill path
  - Replace `obra/superpowers` references with `skills/shared/process/`
- [ ] **Step 3: Verify rename + cleanup.**

```bash
head -3 skills/shared/process/using-process-skills/SKILL.md
grep -ic "superpowers" skills/shared/process/using-process-skills/SKILL.md
```
Expected: frontmatter w/ `name: using-process-skills`, then count of `superpowers` mentions = `0` (or 1 if intentionally kept in attribution line — note the exact count below).

- [ ] **Step 4: Commit.** `git commit -m "feat(process): vendor and rename using-superpowers → using-process-skills"`

---

## Task 15: Write `docs/process/SKILL_INDEX.md`

**Files:** Create `docs/process/SKILL_INDEX.md`

- [ ] **Step 1: Write index file**

```markdown
# Process Skill Index

Two tables. No prose.

## Lifecycle phase → process skill

| # | Phase | Process skill |
|---|---|---|
| 1 | Define problem | [brainstorming](../../skills/shared/process/brainstorming/SKILL.md) |
| 2 | Blueprint | [brainstorming](../../skills/shared/process/brainstorming/SKILL.md) (continued) |
| 3 | Plan | [writing-plans](../../skills/shared/process/writing-plans/SKILL.md) |
| 4 | Isolate workspace | [using-git-worktrees](../../skills/shared/process/using-git-worktrees/SKILL.md) |
| 5 | Execute | [subagent-driven-development](../../skills/shared/process/subagent-driven-development/SKILL.md) or [executing-plans](../../skills/shared/process/executing-plans/SKILL.md) |
| 6 | Test discipline | [test-driven-development](../../skills/shared/process/test-driven-development/SKILL.md) |
| 7 | Debug | [systematic-debugging](../../skills/shared/process/systematic-debugging/SKILL.md) |
| 8 | Verify | [verification-before-completion](../../skills/shared/process/verification-before-completion/SKILL.md) |
| 9 | Review | [requesting-code-review](../../skills/shared/process/requesting-code-review/SKILL.md) → [receiving-code-review](../../skills/shared/process/receiving-code-review/SKILL.md) |
| 10 | Ship | [finishing-a-development-branch](../../skills/shared/process/finishing-a-development-branch/SKILL.md) |
| — | Parallel work (any phase) | [dispatching-parallel-agents](../../skills/shared/process/dispatching-parallel-agents/SKILL.md) |
| — | Entry point | [using-process-skills](../../skills/shared/process/using-process-skills/SKILL.md) |

## Process skill → role agent + domain skills it triggers

| Process skill | Role agents | Domain skills loaded |
|---|---|---|
| brainstorming | fullstack_architect, agentic_ai_architect | shared/product/PRD, shared/product/PEAS |
| writing-plans | fullstack_architect | role skills referenced by blueprint |
| executing-plans | all role agents | colocated `skills/<role>/` |
| subagent-driven-development | fullstack_architect, agentic_ai_architect | colocated `skills/<role>/` |
| test-driven-development | qa_agent, all builder roles | qa_agent/testing_pytest, testing_jest, static_analysis_mypy, linting_ruff |
| systematic-debugging | all roles | context/tasks/self-correction.md |
| verification-before-completion | qa_agent, security_agent | resources/rules/evaluation/* |
| using-git-worktrees | all roles | — |
| requesting-code-review | all roles | agents/llm_judge |
| receiving-code-review | all roles | — |
| finishing-a-development-branch | all roles | — |
| dispatching-parallel-agents | fullstack_architect, agentic_ai_architect | — |
| using-process-skills | all roles | — |
```

- [ ] **Step 2: Verify links resolve**

```bash
for f in $(grep -oE "skills/shared/process/[^)]+\.md" docs/process/SKILL_INDEX.md | sort -u); do
  test -f "$f" || echo "MISSING: $f"
done
```
Expected: no output (all linked files exist).

- [ ] **Step 3: Commit**

```bash
git add docs/process/SKILL_INDEX.md
git commit -m "docs(process): add lifecycle phase ↔ skill mapping index"
```

---

## Task 16: Write `docs/process/USAGE.md`

**Files:** Create `docs/process/USAGE.md`

- [ ] **Step 1: Write usage guide**

```markdown
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
```

- [ ] **Step 2: Verify**

`ls docs/process/USAGE.md && head -10 docs/process/USAGE.md`

- [ ] **Step 3: Commit**

```bash
git add docs/process/USAGE.md
git commit -m "docs(process): add manual phase invocation usage guide"
```

---

## Task 17: Append `§10 Process Gates` to AGENTS.md

**Files:** Modify `AGENTS.md` (append at end)

- [ ] **Step 1: Append section**

Append to `AGENTS.md`:

```markdown

## 10. Process Gates

Every non-trivial task flows through the 10-phase lifecycle defined in
[docs/process/SKILL_INDEX.md](docs/process/SKILL_INDEX.md):

1. **Define problem** — `skills/shared/process/brainstorming/SKILL.md`
2. **Blueprint** — continues brainstorming with the architect agent
3. **Plan** — `skills/shared/process/writing-plans/SKILL.md`
4. **Isolate workspace** — `skills/shared/process/using-git-worktrees/SKILL.md`
5. **Execute** — `skills/shared/process/subagent-driven-development/SKILL.md` or `executing-plans`
6. **Test discipline** — `skills/shared/process/test-driven-development/SKILL.md`
7. **Debug** — `skills/shared/process/systematic-debugging/SKILL.md`
8. **Verify** — `skills/shared/process/verification-before-completion/SKILL.md` (mirrors §4)
9. **Review** — `requesting-code-review` → `receiving-code-review`
10. **Ship** — `skills/shared/process/finishing-a-development-branch/SKILL.md`

Skip a phase only when the task is genuinely trivial (single-file, < 5 lines —
same threshold as §1). When in doubt, run the gate.

For parallel work, see `skills/shared/process/dispatching-parallel-agents/SKILL.md`.
For an introduction to the process skill system, read
`skills/shared/process/using-process-skills/SKILL.md` at session start.
```

- [ ] **Step 2: Verify**

```bash
grep -n "^## 10. Process Gates$" AGENTS.md
```
Expected: one match.

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs(agents): add §10 Process Gates lifecycle"
```

---

## Task 18: Append Process Gates stanza to all 10 role-agent files

**Files:**
- Modify: `agents/agentic_ai_architect/agentic_ai_architect.md`
- Modify: `agents/backend_agent/backend_agent.md`
- Modify: `agents/database_agent/database_agent.md`
- Modify: `agents/devops_agent/devops_agent.md`
- Modify: `agents/frontend_agent/frontend_agent.md`
- Modify: `agents/fullstack_architect/fullstack_architect.md`
- Modify: `agents/llm_judge/llm_judge.md`
- Modify: `agents/payment_agent/payment_agent.md`
- Modify: `agents/qa_agent/qa_agent.md`
- Modify: `agents/security_agent/security_agent.md`

- [ ] **Step 1: Append stanza to each role file**

Append the following to every role-agent file, customizing the **Phases ridden** line per role per the table below:

```markdown

## Process Gates

This agent operates inside the lifecycle defined in
[docs/process/SKILL_INDEX.md](../../docs/process/SKILL_INDEX.md) and
[AGENTS.md §10](../../AGENTS.md).

**Phases ridden:** <FILL_PER_ROLE>

Lifecycle order is enforced by AGENTS.md, not by this file. This stanza is
informational — it tells humans which gates this role most often participates in.
```

Per-role values:

| Role | Phases ridden |
|---|---|
| agentic_ai_architect | 1, 2, 3, plus `dispatching-parallel-agents` |
| backend_agent | 5, 6, 7, 8 |
| database_agent | 5, 6, 7, 8 |
| devops_agent | 4, 8, 10 |
| frontend_agent | 5, 6, 7, 8 |
| fullstack_architect | 1, 2, 3, plus `dispatching-parallel-agents` |
| llm_judge | 9 (consumes `requesting-code-review` output) |
| payment_agent | 5, 6, 7, 8 |
| qa_agent | 6, 8 |
| security_agent | 8, 9, plus always-on `resources/rules/security/*` |

- [ ] **Step 2: Verify all 10 files updated**

```bash
grep -L "^## Process Gates$" agents/*/*.md
```
Expected: no output (every role file contains the heading).

- [ ] **Step 3: Commit**

```bash
git add agents/*/*.md
git commit -m "docs(agents): declare process gate participation per role"
```

---

## Task 19: Add YAML frontmatter to 29 flat domain skill files

**Files:** Modify each of the 29 flat `.md` files identified by the audit query.

- [ ] **Step 1: Identify the 29 files**

```bash
find skills -name "*.md" -not -name "SKILL.md" -not -name "reference.md" | while read f; do
  head -1 "$f" | grep -q "^---$" || echo "$f"
done > /tmp/flat-skills.txt
wc -l /tmp/flat-skills.txt
```
Expected: 29.

- [ ] **Step 2: For each file, prepend frontmatter**

For each file in `/tmp/flat-skills.txt`:

1. Derive `name` from filename: `react_best_practices.md` → `name: react-best-practices` (lowercase, hyphens).
2. Derive `description` from the first heading + first paragraph (already present in body) — write a one-sentence trigger description that says when to use the skill and what it covers.
3. Prepend this block to the file:

```yaml
---
name: <derived-name>
description: <one-sentence trigger>
---

```

(blank line after closing `---`)

Body unchanged.

Worked example for `skills/frontend_agent/react_best_practices.md`:

```yaml
---
name: react-best-practices
description: Use when building or refactoring React 19 components. Covers functional-only components, typed props, useEffect cleanup rules, and the lint/style invariants enforced project-wide.
---
```

- [ ] **Step 3: Verify all skill files have frontmatter**

```bash
find skills -name "*.md" | while read f; do
  head -1 "$f" | grep -q "^---$" || echo "MISSING: $f"
done
```
Expected: no output.

- [ ] **Step 4: Verify body unchanged (line count delta = 4 per file)**

```bash
git diff --stat skills/ | tail -5
```
Expected: each modified file shows ~4 insertions, 0 deletions.

- [ ] **Step 5: Commit**

```bash
git add skills/
git commit -m "feat(skills): add YAML frontmatter to 29 flat domain skill files"
```

---

## Task 20: Create `commands/` folder with phase wrappers

**Files:**
- Create: `commands/brainstorm.md`
- Create: `commands/write-plan.md`
- Create: `commands/execute-plan.md`
- Create: `commands/ship.md`

- [ ] **Step 1: Write `commands/brainstorm.md`**

```markdown
---
description: Start a brainstorming session — refine an idea into a spec via the brainstorming process skill.
---

Read and follow `skills/shared/process/brainstorming/SKILL.md`.
Save the resulting spec to `docs/process/specs/YYYY-MM-DD-<topic>-design.md`.
```

- [ ] **Step 2: Write `commands/write-plan.md`**

```markdown
---
description: Turn an approved spec into a bite-sized implementation plan.
---

Read and follow `skills/shared/process/writing-plans/SKILL.md`.
Save the plan to `docs/process/plans/YYYY-MM-DD-<feature>.md`.
```

- [ ] **Step 3: Write `commands/execute-plan.md`**

```markdown
---
description: Execute an implementation plan task-by-task with checkpoints.
---

Read and follow `skills/shared/process/executing-plans/SKILL.md`.
For subagent-per-task execution, prefer `skills/shared/process/subagent-driven-development/SKILL.md`.
```

- [ ] **Step 4: Write `commands/ship.md`**

```markdown
---
description: Wrap up a development branch — verify, choose merge/PR/discard, clean up worktree.
---

Read and follow `skills/shared/process/finishing-a-development-branch/SKILL.md`.
```

- [ ] **Step 5: Verify**

```bash
ls commands/
```
Expected: `brainstorm.md  execute-plan.md  ship.md  write-plan.md`

```bash
for f in commands/*.md; do head -1 "$f" | grep -q "^---$" || echo "MISSING FRONTMATTER: $f"; done
```
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add commands/
git commit -m "feat(commands): add slash-command wrappers for the 4 main process phases"
```

---

## Task 21: Add plugin manifest at `.claude-plugin/plugin.json`

**Files:** Create `.claude-plugin/plugin.json`

- [ ] **Step 1: Create directory and manifest**

```bash
mkdir -p .claude-plugin
```

Write `.claude-plugin/plugin.json`:

```json
{
  "name": "agentic-playbook",
  "description": "Role-based agent skills + embedded process discipline (brainstorm, plan, TDD, verify, review, ship). Adapted from obra/superpowers.",
  "version": "0.1.0",
  "author": {
    "name": "alanvaa06",
    "email": "alanvaa.06@gmail.com"
  },
  "homepage": "https://github.com/alanvaa06/agentic-playbook",
  "repository": "https://github.com/alanvaa06/agentic-playbook",
  "license": "MIT",
  "keywords": [
    "skills",
    "agents",
    "tdd",
    "process",
    "playbook",
    "fullstack",
    "ai-agents"
  ]
}
```

Note: Claude plugin spec discovers `agents/`, `skills/`, `commands/` by convention from the repo root — no explicit path fields required (verified against the upstream `superpowers/.claude-plugin/plugin.json` schema). If the spec evolves, update fields here.

- [ ] **Step 2: Validate JSON**

```bash
python -c "import json; json.load(open('.claude-plugin/plugin.json'))" && echo "valid JSON"
```
Expected: `valid JSON`.

- [ ] **Step 3: Verify discoverable folders exist**

```bash
for d in agents skills commands; do test -d "$d" || echo "MISSING: $d"; done
```
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat(plugin): add Claude Code plugin manifest"
```

---

## Task 22: Add `RELEASE-NOTES.md` and update `README.md`

**Files:**
- Create: `RELEASE-NOTES.md`
- Modify: `README.md` (add plugin install section)

- [ ] **Step 1: Create RELEASE-NOTES.md**

```markdown
# Release Notes

## v0.1.0 — 2026-05-01

First plugin-distributable release.

### Added

- Process skills under `skills/shared/process/` (13 skills) — vendored and adapted from
  [obra/superpowers](https://github.com/obra/superpowers) commit `e7a2d164`.
- `AGENTS.md §10 Process Gates` lifecycle.
- `docs/process/SKILL_INDEX.md` phase ↔ skill mapping.
- `docs/process/USAGE.md` manual invocation guide.
- `docs/process/CREDITS.md` upstream attribution + MIT notice.
- `commands/` folder with 4 phase-wrapper slash commands.
- `.claude-plugin/plugin.json` manifest enabling marketplace distribution.
- YAML frontmatter on all 45 skill files (16 already had it; added to remaining 29).
- Process Gates stanza on every role-agent definition.

### Changed

- `docs/superpowers/` (transient first draft) renamed to `docs/process/`.

### Notes

- Repo remains usable via `git clone` without installing the plugin.
- Plugin install adds auto-trigger and `/brainstorm` /`/write-plan` /`/execute-plan` /`/ship` commands.
```

- [ ] **Step 2: Add plugin install section to README**

Insert new subsection under the existing **Quick Start** section in `README.md`:

```markdown
### Plugin install (Claude Code, Codex, Gemini, Copilot, Cursor)

```bash
/plugin marketplace add <your-org>/agentic-playbook-marketplace
/plugin install agentic-playbook
```

This registers all role agents, skills, and `/brainstorm` /`/write-plan` /`/execute-plan` /`/ship` commands. The repo also still works via plain `git clone` — see [docs/process/USAGE.md](docs/process/USAGE.md).
```

- [ ] **Step 3: Verify**

```bash
ls RELEASE-NOTES.md
grep -c "^### Plugin install" README.md
```
Expected: file exists; count `1`.

- [ ] **Step 4: Commit**

```bash
git add RELEASE-NOTES.md README.md
git commit -m "docs: announce v0.1.0 with plugin install instructions"
```

---

## Task 23: Final acceptance verification

**Files:** No new files. Run checks against acceptance criteria from spec §13.

- [ ] **Step 1: Run all acceptance criteria checks**

```bash
echo "=== AC1: 13 process skills ==="
ls skills/shared/process/ | wc -l
# Expected: 13

echo "=== AC2: SKILL_INDEX.md exists ==="
test -f docs/process/SKILL_INDEX.md && echo "OK"

echo "=== AC3: CREDITS.md present ==="
grep -q "e7a2d164" docs/process/CREDITS.md && grep -qi "MIT" docs/process/CREDITS.md && echo "OK"

echo "=== AC4: AGENTS.md §10 ==="
grep -q "^## 10. Process Gates$" AGENTS.md && echo "OK"

echo "=== AC5: every role file has Process Gates stanza ==="
grep -L "^## Process Gates$" agents/*/*.md
# Expected: no output

echo "=== AC6: no live wiring to obra/superpowers outside CREDITS + spec ==="
git grep -i "obra/superpowers" -- ':!docs/process/CREDITS.md' ':!docs/process/specs/*' ':!RELEASE-NOTES.md'
# Expected: no output

echo "=== AC7: works without plugin installed ==="
# Manual smoke test: open the repo in Cursor or VS Code w/o plugin → README + AGENTS.md readable, skills resolvable by path.

echo "=== AC8: every skill has frontmatter ==="
find skills -name "*.md" | while read f; do
  head -1 "$f" | grep -q "^---$" || echo "MISSING: $f"
done
# Expected: no output

echo "=== AC9: plugin manifest exists + valid JSON ==="
test -f .claude-plugin/plugin.json && python -c "import json; json.load(open('.claude-plugin/plugin.json'))" && echo "OK"

echo "=== AC10: marketplace install dry-run ==="
# Out of scope for this plan — covered by separate marketplace-repo task. Note in RELEASE-NOTES.md.
echo "deferred to marketplace-repo task"
```

- [ ] **Step 2: Print summary, no commit needed.** All previous task commits already merged. If any AC fails, return to the failing task and fix.

- [ ] **Step 3: Optional — tag v0.1.0**

Only if all ACs pass:

```bash
git tag -a v0.1.0 -m "v0.1.0: vendor process skills + plugin manifest"
```

(Do NOT push the tag without user approval.)

---

## Execution notes

- Tasks 2–14 (vendoring 13 skills) are independent and can be parallelized via subagent dispatch. Tasks 15+ depend on the vendored files existing.
- Task 18 (role-agent stanzas) is independent of the vendored skill content — can run in parallel with vendoring.
- Task 19 (frontmatter audit) is independent of vendoring — can run in parallel.
- Task 21 (plugin manifest) is independent.
- Task 23 must run last.

Suggested parallel batches:
- **Batch A (independent docs):** Tasks 1, 17, 18, 19, 21
- **Batch B (vendoring, ordered after A):** Tasks 2–14
- **Batch C (depends on B):** Tasks 15, 16, 20
- **Batch D (last):** Tasks 22, 23
