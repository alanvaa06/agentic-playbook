# Static Analysis — mypy

**Domain:** QA
**Loaded when:** `mypy` detected in `requirements.txt` or `pyproject.toml`

---

## When to Use

- Adding or enforcing type annotations across a Python codebase.
- Configuring mypy for a new project or tightening an existing permissive config.
- Diagnosing and fixing common mypy errors (`missing return type`, `incompatible types`, `untyped decorator`).
- Integrating mypy into CI or pre-commit hooks.

## When NOT to Use

- JavaScript or TypeScript projects — TypeScript's compiler is the equivalent tool; do not apply mypy patterns there.
- Rapid prototyping scripts where type annotations add friction without benefit — annotate production modules, not throwaway scripts.

---

## Core Rules

1. **Enable strict mode from the start; never weaken it retroactively.** Add `strict = true` under `[tool.mypy]` in `pyproject.toml`. Enabling it later on a large codebase is painful — each relaxed setting is technical debt.
2. **Configure mypy exclusively in `pyproject.toml`, not in `mypy.ini` or `setup.cfg`.** A single source of truth avoids config shadowing. If both `pyproject.toml` and `mypy.ini` exist, mypy uses `mypy.ini` and silently ignores `pyproject.toml`.
3. **Install stubs for every third-party library that lacks inline types.** Run `mypy --install-types` to discover missing stubs, then add them as dev dependencies (e.g., `types-requests`, `types-redis`). Never suppress errors caused by missing stubs with `# type: ignore`.
4. **Use `[[tool.mypy.overrides]]` for gradual adoption, not `ignore_errors = true` globally.** Target untyped modules with `module = "legacy_module.*"` and `ignore_errors = true` scoped to that module. Never blanket-ignore the entire codebase.
5. **Never use bare `# type: ignore`.** Always add an error code: `# type: ignore[attr-defined]`. Bare ignores suppress all future errors on that line, including regressions.
6. **Annotate all public function signatures; skip trivial private helpers only if return type is `None`.** Missing return-type annotations on public functions are the most common source of `Any` propagation — one unannotated function contaminates all callers.
7. **Use `typing.TYPE_CHECKING` for import-only-for-type-hints imports.** This avoids circular imports at runtime while preserving type information for mypy.
8. **Run mypy in CI on every PR with `--no-incremental` to avoid stale cache false-positives.** The local incremental cache can mask errors; CI always runs from a clean state.

---

## Code Patterns

### Canonical pyproject.toml configuration

```toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_ignores = true
show_error_codes = true
pretty = true

# Pydantic plugin — enables type-checking of model fields
plugins = ["pydantic.mypy"]

[tool.pydantic-mypy]
init_forbid_extra = true
init_typed = true
warn_required_dynamic_aliases = true

# Per-module overrides for third-party or legacy modules without stubs
[[tool.mypy.overrides]]
module = ["alembic.*", "some_legacy_module.*"]
ignore_missing_imports = true
```

### Annotating with TYPE_CHECKING to avoid circular imports

```python
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from server.models.user import User   # only imported during type-checking, not at runtime

def get_display_name(user: "User") -> str:
    return f"{user.first_name} {user.last_name}"
```

### Handling Optional and None safely

```python
from typing import Optional

def find_user(user_id: int) -> Optional["User"]:
    ...

# Caller must narrow the type before use
user = find_user(42)
if user is None:
    raise ValueError("User not found")
reveal_type(user)   # mypy: User (narrowed from Optional[User])
```

### Typed TypedDict for structured dicts

```python
from typing import TypedDict

class PaginationParams(TypedDict):
    page: int
    page_size: int
    total: int

def paginate(params: PaginationParams) -> list[dict[str, object]]:
    ...
```

### Scoped type: ignore with error code

```python
# Correct: scoped suppression with reason
result = some_untyped_lib.fetch()  # type: ignore[no-untyped-call]

# Wrong: bare ignore hides all future errors on this line
result = some_untyped_lib.fetch()  # type: ignore
```

---

## Common Error Patterns and Fixes

| mypy Error | Root Cause | Fix |
|------------|------------|-----|
| `error: Function is missing a return type annotation` | Public function has no `-> ReturnType` | Add explicit return type; use `-> None` for procedures |
| `error: Returning Any from function declared to return "str"` | Called an untyped function and returned its result | Annotate the callee, or cast: `return str(result)` |
| `error: Cannot call function of unknown type` | Variable typed as `Callable[..., Any]` or untyped | Narrow with `assert callable(fn)` or use `Callable[[ArgType], RetType]` |
| `error: Incompatible types in assignment (expression has type "X", variable has type "Y")` | Reassigning a variable to a different type | Use `Union[X, Y]` or introduce a new variable |
| `error: Decorator makes function "f" lose type information` | Untyped decorator wraps a typed function | Add `@functools.wraps` and annotate the decorator with `ParamSpec` |
| `error: Module "X" has no attribute "Y"` | Missing stubs for third-party library | Install `types-X` from PyPI or add `ignore_missing_imports = true` in `[[tool.mypy.overrides]]` |
| `error: Need type annotation for "X" (hint: "X: List[<type>] = ...")` | Empty collection assigned without annotation | Add inline annotation: `items: list[str] = []` |

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `ignore_errors = true` at root level | `[[tool.mypy.overrides]]` scoped to legacy modules | Global ignore defeats the purpose of mypy; errors in new code go undetected |
| `# type: ignore` without an error code | `# type: ignore[specific-code]` | Bare ignores suppress all future errors on that line, masking regressions |
| Mixing `mypy.ini` and `pyproject.toml` | Consolidate in `pyproject.toml` | mypy's config precedence silently ignores `pyproject.toml` when `mypy.ini` exists |
| `from typing import List, Dict, Tuple` (Python < 3.9 style) | `list[str]`, `dict[str, int]`, `tuple[int, ...]` | PEP 585 built-in generics are available from Python 3.9+; `typing` aliases are deprecated |
| Running `mypy --ignore-missing-imports` globally in CI | Install stubs or add per-module overrides | Global flag hides real type errors caused by API misuse of untyped libraries |
| Annotating internal helpers exhaustively before public API | Annotate public functions and class interfaces first | Type inference propagates inward; annotating the boundary fixes the most errors per line changed |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] `[tool.mypy]` section exists in `pyproject.toml` with `strict = true`
- [ ] `show_error_codes = true` is set so all ignores can be scoped
- [ ] All third-party libraries have either stubs installed or a targeted `[[tool.mypy.overrides]]` entry
- [ ] No bare `# type: ignore` — every suppress has an error code
- [ ] All public functions have explicit return type annotations
- [ ] `mypy .` exits with code `0` in CI with `--no-incremental`
- [ ] Pydantic plugin is enabled if Pydantic models are in use
- [ ] No `from typing import List, Dict` — built-in generics are used throughout
