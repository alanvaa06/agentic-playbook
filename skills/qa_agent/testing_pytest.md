# Testing — pytest

**Domain:** QA
**Loaded when:** `pytest` detected in `requirements.txt` or `pyproject.toml`

---

## When to Use

- Writing or extending unit tests, integration tests, or end-to-end API tests for Python services.
- Adding test fixtures, factories, or database isolation strategies to an existing test suite.
- Diagnosing flaky tests caused by shared state, missing teardown, or event-loop conflicts.

## When NOT to Use

- The project's test runner is `unittest` only with no `pytest` dependency — stick to `unittest` conventions.
- Frontend or Node.js testing — load `testing_jest.md` instead.

---

## Core Rules

1. **One `conftest.py` per scope boundary.** Place shared fixtures in the `conftest.py` closest to the tests that need them: root-level for app-wide fixtures (DB engine, event loop), module-level for domain-specific factories. Never dump all fixtures into a single root `conftest.py`.
2. **Use `scope="session"` for the DB engine; `scope="function"` for transactions.** The engine is expensive to create; create it once. Each test gets its own transaction that is rolled back on teardown — never commit during tests.
3. **Always use `httpx.AsyncClient` for async FastAPI tests.** Import `ASGITransport` and pass the `app` directly — no running server required. Never use `TestClient` (sync) in an async codebase.
4. **Isolate every test with a transaction rollback, not table truncation.** Wrap each test in a savepoint; roll back after the test. Truncation is slow and leaves sequences in an unpredictable state.
5. **Use `factory_boy` for object creation, never raw `dict` or hand-rolled fixtures.** Factories are maintainable, support traits, and guarantee referential integrity between related models.
6. **Mark all async tests with `@pytest.mark.anyio`.** Never use `asyncio.run()` inside a test or mix `@pytest.mark.asyncio` with `anyio` — one event-loop policy per suite.
7. **Never use `time.sleep()` in tests.** Use `anyio.sleep()` for async waits, or better, mock the time dependency.
8. **Assert the status code before asserting the response body.** A wrong status code means the body is an error payload, not the expected schema — the secondary assertion will produce a confusing failure message.
9. **Parametrize edge-case inputs with `@pytest.mark.parametrize`.** Avoid copy-pasted test functions that differ only in input values.

---

## Code Patterns

### Session-scoped engine + function-scoped transactional session

Each test receives a clean session that is rolled back after the test without hitting the disk.

```python
# tests/conftest.py
import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from server.db.base import Base
from server.main import app
from server.dependencies import get_db

DATABASE_URL = "postgresql+asyncpg://user:pass@localhost/test_db"

@pytest.fixture(scope="session")
def engine():
    return create_async_engine(DATABASE_URL, echo=False)

@pytest.fixture(scope="session")
async def create_tables(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest_asyncio.fixture
async def db_session(engine, create_tables):
    async with engine.connect() as conn:
        await conn.begin_nested()  # savepoint
        session = AsyncSession(bind=conn, expire_on_commit=False)
        yield session
        await session.rollback()
        await session.close()

@pytest_asyncio.fixture
async def client(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    async with httpx.AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()
```

### Async test with httpx.AsyncClient

```python
# tests/test_users.py
import pytest
import httpx
from httpx import ASGITransport

@pytest.mark.anyio
async def test_create_user_returns_201(client: httpx.AsyncClient):
    payload = {"email": "jane@example.com", "password": "s3cret", "full_name": "Jane"}
    response = await client.post("/api/v1/users/", json=payload)

    assert response.status_code == 201          # check status first
    body = response.json()
    assert body["email"] == payload["email"]
    assert "password" not in body               # never leak credentials
```

### Factory with factory_boy + SQLAlchemy

```python
# tests/factories.py
import factory
from factory.alchemy import SQLAlchemyModelFactory
from server.models.user import User

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "flush"  # flush, not commit

    email = factory.Sequence(lambda n: f"user{n}@example.com")
    full_name = factory.Faker("name")
    hashed_password = "hashed_placeholder"
    is_active = True

class InactiveUserFactory(UserFactory):
    class Meta:
        exclude = ["is_active"]
    is_active = False
```

### Parametrized edge cases

```python
@pytest.mark.parametrize("email", [
    "not-an-email",
    "",
    "missing@tld",
    "a" * 300 + "@example.com",
])
@pytest.mark.anyio
async def test_create_user_rejects_invalid_email(client, email):
    response = await client.post("/api/v1/users/", json={"email": email, "password": "x"})
    assert response.status_code == 422
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `TestClient(app)` in async routes | `httpx.AsyncClient` with `ASGITransport` | `TestClient` runs a sync WSGI adapter; async routes silently run in the wrong context |
| `db.commit()` inside a test | `db.flush()` only; rely on fixture rollback | Commits make state leak across tests; truncation-based cleanup is slow |
| `@pytest.fixture` returning a plain `dict` for model data | `factory_boy` `SQLAlchemyModelFactory` | Dicts skip model constraints; factories enforce schema integrity at creation time |
| `async def test_foo(): asyncio.run(...)` | Mark with `@pytest.mark.anyio` | Double event loops cause `RuntimeError: This event loop is already running` |
| One massive `conftest.py` at root for all fixtures | Scope-appropriate `conftest.py` files per package | Root-level fixtures are re-evaluated for unrelated test modules; scope leaks slow suites down |
| `assert response.json()["name"] == "Jane"` before checking status | `assert response.status_code == 200` first | On error, `response.json()` is an error payload; the name assertion fails with a confusing `KeyError` |
| `time.sleep(2)` waiting for background task | Mock the background task or use `anyio.sleep` with event synchronization | `sleep` makes tests slow, brittle, and non-deterministic on CI |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] `conftest.py` uses `scope="session"` for the engine and `scope="function"` for the session
- [ ] Every async test is decorated with `@pytest.mark.anyio`
- [ ] `httpx.AsyncClient` + `ASGITransport` is used — no `TestClient`
- [ ] No `db.commit()` inside any test or fixture; only `flush()` before assertions
- [ ] All model creation goes through a `factory_boy` factory
- [ ] `app.dependency_overrides` is cleared in fixture teardown
- [ ] Parametrize is used for any test that covers 3+ input variations
- [ ] `pytest --cov` runs without error and coverage is above the project threshold
