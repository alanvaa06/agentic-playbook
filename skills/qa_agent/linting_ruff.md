# Linting & Formatting — Ruff

**Domain:** QA
**Loaded when:** `ruff` detected in `requirements.txt` or `pyproject.toml`

---

## When to Use

- Configuring or extending a Ruff linting setup for a Python project.
- Migrating from `flake8`, `isort`, `pyupgrade`, or `black` to Ruff.
- Adding per-file lint overrides or suppressing specific rules in a targeted way.
- Integrating Ruff into pre-commit hooks or CI pipelines.

## When NOT to Use

- JavaScript or TypeScript projects — use ESLint and Prettier instead.
- Projects that have a hard contractual dependency on `black` formatting (e.g., shared library with external contributors who run `black` locally) — `ruff format` produces identical output to `black` in most cases, but verify first.

---

## Core Rules

1. **Configure Ruff exclusively in `pyproject.toml` under `[tool.ruff]`.** Never use `ruff.toml` alongside `pyproject.toml` — two config files cause silent precedence conflicts.
2. **Enable at minimum the `E`, `F`, `I`, `UP`, and `B` rule sets.** `E`/`F` replaces flake8 core, `I` replaces isort, `UP` enforces modern Python idioms (pyupgrade), `B` catches common bugbear mistakes. Do not run Ruff with zero rule selection — it does nothing by default.
3. **Use `per-file-ignores` for targeted suppressions, never global `ignore`.** Global ignores remove rules from all files; per-file ignores apply only where a rule genuinely does not apply (e.g., `F401` unused imports in `__init__.py`).
4. **Run `ruff format` alongside `ruff check`.** `ruff format` is a drop-in replacement for `black`. Running lint without format leaves inconsistent whitespace that `ruff check` won't catch.
5. **Never use `# noqa` without a rule code.** Always write `# noqa: F401` — bare `# noqa` suppresses every rule on that line and hides future regressions.
6. **Fix auto-fixable violations in CI with `ruff check --fix` only in pre-commit, not in CI.** CI runs `ruff check` in check mode (no `--fix`) — auto-fixing in CI silently modifies code and can mask real failures.
7. **Set `target-version` to match `python_version` in mypy and the project's minimum supported Python.** Mismatched target versions cause Ruff to flag valid syntax as wrong or miss real upgrades.
8. **Exclude generated files and migrations from linting.** Add `migrations/`, `*_pb2.py` (protobuf), and any codegen directories to `[tool.ruff.lint] exclude` — linting generated code produces noise without actionable fixes.

---

## Code Patterns

### Canonical pyproject.toml configuration

```toml
[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "F",    # pyflakes
    "I",    # isort
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "C4",   # flake8-comprehensions
    "SIM",  # flake8-simplify
    "TCH",  # flake8-type-checking (moves TYPE_CHECKING imports)
    "RUF",  # ruff-specific rules
]
ignore = [
    "E501",   # line too long — handled by ruff format
    "B008",   # do not perform function calls in default args (FastAPI uses this intentionally)
]

[tool.ruff.lint.per-file-ignores]
"__init__.py"      = ["F401"]  # re-exports are intentional
"tests/**/*.py"    = ["S101"]  # assert is expected in tests
"scripts/**/*.py"  = ["T201"]  # print() is acceptable in scripts

[tool.ruff.lint.isort]
known-first-party = ["server", "tests"]
force-sort-within-sections = true

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

### Running Ruff in CI (check only, no auto-fix)

```yaml
# .github/workflows/lint.yml
- name: Lint with Ruff
  run: |
    ruff check . --output-format=github
    ruff format . --check
```

### Pre-commit hook configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.4          # pin to a specific version
    hooks:
      - id: ruff          # lint + auto-fix
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format   # format (equivalent to black)
```

### Targeted suppression with rule code

```python
# Correct: scoped suppression — only silences F401 on this line
from server.models import User  # noqa: F401

# Wrong: bare noqa silences everything, including future regressions
from server.models import User  # noqa
```

### Moving TYPE_CHECKING imports automatically (TCH rule)

Ruff's `TCH` ruleset automatically flags imports that are only needed for type hints and moves them under `TYPE_CHECKING`:

```python
# Before (TCH001 violation):
from server.models.user import User

def get_name(user: User) -> str: ...

# After (ruff --fix applies this automatically):
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from server.models.user import User

def get_name(user: User) -> str: ...
```

---

## Rule Reference — Key Codes

| Code | Ruleset | What it catches |
|------|---------|-----------------|
| `E711` | pycodestyle | `== None` instead of `is None` |
| `F401` | pyflakes | Unused imports |
| `F841` | pyflakes | Unused local variable |
| `I001` | isort | Import order violation |
| `UP006` | pyupgrade | `typing.List` instead of `list` |
| `UP007` | pyupgrade | `typing.Optional[X]` instead of `X \| None` |
| `B006` | bugbear | Mutable default argument |
| `B007` | bugbear | Unused loop control variable |
| `B904` | bugbear | `raise X` inside `except` without `from` |
| `C401` | comprehensions | Unnecessary `list()` around a generator |
| `SIM108` | simplify | Ternary expression can replace if/else block |
| `TCH001` | type-checking | Runtime import only needed for type hints |
| `RUF100` | ruff | Unused `# noqa` directive |

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `ignore = ["F401"]` globally | `per-file-ignores = {"__init__.py" = ["F401"]}` | Global ignores silence unused import warnings everywhere; real mistakes go undetected in regular modules |
| Bare `# noqa` | `# noqa: F401` with the specific code | Bare noqa suppresses all rules on the line, hiding future regressions |
| `ruff check --fix` in CI | `ruff check` (no `--fix`) in CI; `ruff --fix` in pre-commit only | Auto-fixing in CI silently modifies the branch; CI should verify, not transform |
| `select = []` (empty rule list) | `select = ["E", "F", "I", "UP", "B"]` at minimum | An empty select list makes Ruff a no-op; nothing is checked |
| Two config files (`pyproject.toml` + `ruff.toml`) | Single `[tool.ruff]` section in `pyproject.toml` | Dual configs cause silent precedence issues; the precedence order is: `ruff.toml` > `.ruff.toml` > `pyproject.toml` |
| Pinning pre-commit to `rev: main` | Pin to a specific tagged version (e.g., `rev: v0.4.4`) | Unpinned pre-commit hooks produce non-reproducible results across developer machines |
| Running `ruff check` without `ruff format` | Always pair `ruff check` with `ruff format --check` in CI | Lint and format are complementary; passing lint with bad formatting is a false green |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] `[tool.ruff]` and `[tool.ruff.lint]` sections exist in `pyproject.toml` — no separate `ruff.toml`
- [ ] `select` includes at minimum `E`, `F`, `I`, `UP`, `B`
- [ ] `target-version` matches the project's minimum Python version
- [ ] No bare `# noqa` — every suppression has a rule code
- [ ] No global `ignore` entries that should be `per-file-ignores`
- [ ] `ruff format . --check` passes in CI
- [ ] `ruff check . --output-format=github` passes in CI
- [ ] Pre-commit hooks pin Ruff to a specific `rev`, not `main`
- [ ] Generated files and migration directories are in `exclude`
