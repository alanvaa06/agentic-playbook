# Release Notes

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
