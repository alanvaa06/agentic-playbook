# Release Notes

## v0.1.1 — 2026-05-08

Synced vendored process skills with obra/superpowers @ f2cbfbe.

### Changed

- **`using-git-worktrees`** — Major rewrite: added Step 0 detect-and-defer (skip creation if already in an isolated workspace, with submodule guard); native tool detection Step 1a (prefer platform-provided worktree tools over `git worktree add`); git worktree fallback Step 1b with sandbox fallback; removed the interactive "where should I put worktrees?" prompt — now defaults to `.worktrees/` when no preference is declared.
- **`finishing-a-development-branch`** — Added Step 2 environment detection (normal repo vs. named-branch worktree vs. detached HEAD); detached HEAD shows a reduced 3-option menu (no local merge); provenance-based worktree cleanup (only remove worktrees the playbook created, i.e., under `.worktrees/`, `worktrees/`, or `~/.config/worktrees/`); CWD safety (`cd` to main repo root before `git worktree remove`); `git worktree prune` self-healing after removal.
- **`subagent-driven-development/code-quality-reviewer-prompt.md`** — Dispatch tool updated from skill-typed reference to `general-purpose`; `WHAT_WAS_IMPLEMENTED` parameter merged into `DESCRIPTION`.

### Internal

- Upstream snapshot SHA bumped: `e7a2d164` → `f2cbfbe` (obra/superpowers v5.1.0).
- Plugin version: `0.1.0` → `0.1.1`.

---

## v0.1.0 — 2026-05-01

First plugin-distributable release.

### Added

- Process skills under `skills/shared/process/` (13 skills) — vendored and adapted from
  [obra/superpowers](https://github.com/obra/superpowers) commit `e7a2d16476bf042e9add4699c9d018a90f86e4a6`.
- `AGENTS.md §10 Process Gates` lifecycle.
- `docs/process/SKILL_INDEX.md` phase ↔ skill mapping.
- `docs/process/USAGE.md` manual invocation guide.
- `docs/process/CREDITS.md` upstream attribution + MIT notice.
- `commands/` folder with 4 phase-wrapper slash commands (`/brainstorm`, `/write-plan`, `/execute-plan`, `/ship`).
- `.claude-plugin/plugin.json` manifest enabling marketplace distribution.
- YAML frontmatter on all 45 skill files (16 already had it; added to remaining 29).
- Process Gates stanza on every role-agent definition.

### Notes

- Repo remains usable via `git clone` without installing the plugin.
- Plugin install adds auto-trigger and the 4 slash commands above.
- Marketplace registration (own marketplace repo + listing) is a follow-up task.
