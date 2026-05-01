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
