# Skill Template — Technology-Specific Base

This document defines the canonical structure for every skill file in the `resources/skills/` directory. All skills MUST follow this template.

---

## How to Use This Template

When creating a new skill file:
1. Create the file at `resources/skills/<domain>/<skill_name>.md`.
2. Fill in all sections marked `[...]`.
3. Keep it dense — every rule must prevent a real, likely mistake.
4. Include code examples that are copy-paste ready.

---

## Template

```markdown
# [Skill Name]

**Domain:** [e.g., frontend, backend, database, devops, payments, security, product, qa]
**Loaded when:** [e.g., `react` detected in `package.json`]

---

## When to Use

- [Scenario where this skill should be loaded]
- [Another scenario]

## When NOT to Use

- [Scenario where loading this skill is wasteful or wrong]

---

## Core Rules

1. [Actionable rule — e.g., "Always use `zodResolver` when connecting Zod schemas to React Hook Form."]
2. [Another rule]
3. [Continue as needed — aim for 5-10 high-signal rules]

---

## Code Patterns

### [Pattern Name]

[One-sentence explanation of when to use this pattern.]

```[language]
[Canonical, copy-paste-ready example]
```

### [Pattern Name]

[One-sentence explanation.]

```[language]
[Example]
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| [Bad pattern]  | [Correct pattern] | [Reason — be specific about what breaks] |
| [Bad pattern]  | [Correct pattern] | [Reason] |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] [Specific check — e.g., "No hardcoded color values in any component file"]
- [ ] [Another check — e.g., "All Zod schemas live in `client/src/schemas/`"]
- [ ] [Continue as needed]
```

---

## Design Principles

| Principle | Rationale |
|-----------|-----------|
| Dense, actionable rules | Vague guidance wastes tokens without improving output quality. |
| Copy-paste code patterns | Reduces hallucination risk — the agent matches patterns instead of inventing syntax. |
| Anti-patterns table | LLMs default to common (often wrong) patterns. Explicit "do not" rules have high corrective signal. |
| Verification checklist | Gives the agent a concrete definition of "done" instead of relying on subjective judgment. |
