# FastAPI Architecture

**Domain:** Backend
**Loaded when:** `fastapi` detected in `requirements.txt`

---

## When to Use

- Building or modifying API endpoints in a FastAPI application.
- Adding dependency injection, middleware, or background tasks.
- Defining Pydantic v2 request/response schemas for FastAPI routes.

## When NOT to Use

- The project uses Django or Flask — those have their own routing and ORM conventions.
- Pure database migration work with no API surface changes — load `sql_postgres.md` instead.

---

## Core Rules

1. **One router per resource.** Each domain entity (`users`, `projects`, `invoices`) gets its own file in `server/routers/`. Never put unrelated routes in the same file.
2. **Always use `APIRouter`, never add routes to `app` directly.** Routers are registered in `server/main.py` via `app.include_router()`. This keeps `main.py` a thin composition root.
3. **Use Pydantic v2 models for all request and response schemas.** Define them in `server/schemas/`. Never use raw `dict` as a return type or accept unvalidated `dict` input.
4. **Use `Depends()` for all cross-cutting concerns.** Database sessions, current user, pagination, and feature flags are injected via dependency functions. Never import and call them directly inside route handlers.
5. **Use `lifespan` context manager instead of `on_event`.** The `@app.on_event("startup")` decorator is deprecated in modern FastAPI. Define a lifespan async context manager and pass it to the `FastAPI()` constructor.
6. **Return explicit status codes.** Use `status_code=status.HTTP_201_CREATED` for resource creation, `status.HTTP_204_NO_CONTENT` for deletes. Never rely on the default `200` for every response.
7. **Use `BackgroundTasks` for fire-and-forget work.** Email sending, webhook dispatches, and audit logging should never block the response. Inject `BackgroundTasks` via the function signature.
8. **All async route handlers must use `async def`.** Never define a route handler as `def` if it calls `await`. Mixing sync handlers with async database calls silently blocks the event loop.

---

## Code Patterns

### Application factory with lifespan

```python
# server/main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from server.routers import users, projects
from server.db.session import engine

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: verify DB connection
    async with engine.begin() as conn:
        await conn.execute(text("SELECT 1"))
    yield
    # Shutdown: dispose connection pool
    await engine.dispose()

app = FastAPI(title="My API", lifespan=lifespan)
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(projects.router, prefix="/api/v1/projects", tags=["projects"])
```

### Router with dependency injection

```python
# server/routers/users.py
from fastapi import APIRouter, Depends, status
from server.schemas.user import UserCreate, UserResponse
from server.services.user_service import UserService
from server.dependencies import get_db, get_current_user

router = APIRouter()

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: UserCreate,
    db=Depends(get_db),
) -> UserResponse:
    service = UserService(db)
    return await service.create(payload)

@router.get("/me", response_model=UserResponse)
async def get_me(current_user=Depends(get_current_user)) -> UserResponse:
    return current_user
```

### Pydantic v2 schemas with model_config

```python
# server/schemas/user.py
from pydantic import BaseModel, EmailStr, ConfigDict

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    full_name: str
    is_active: bool
```

### Database session dependency

```python
# server/dependencies.py
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession
from server.db.session import async_session_factory

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session
```

### Background tasks

```python
@router.post("/invite", status_code=status.HTTP_202_ACCEPTED)
async def invite_user(
    payload: InviteRequest,
    background_tasks: BackgroundTasks,
    db=Depends(get_db),
) -> dict[str, str]:
    service = UserService(db)
    user = await service.create_invite(payload)
    background_tasks.add_task(send_invite_email, user.email, user.invite_token)
    return {"status": "invite sent"}
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `@app.get("/users")` directly in `main.py` | Use `APIRouter` in `server/routers/users.py` | `main.py` becomes unmaintainable as routes grow; routers enable modular testing |
| `def create_user(request: Request)` then `data = await request.json()` | `async def create_user(payload: UserCreate)` | Skips Pydantic validation; unvalidated input reaches business logic |
| `@app.on_event("startup")` | `lifespan` async context manager | `on_event` is deprecated and does not support cleanup on shutdown reliably |
| `return {"id": user.id, "email": user.email}` | `return UserResponse.model_validate(user)` | Raw dicts skip response validation and can accidentally leak fields like `hashed_password` |
| Calling `db.execute()` inside a route handler | Delegate to a service in `server/services/` | Violates business logic isolation; makes routes untestable without a real database |
| `def handle_upload(file: UploadFile)` (sync) with `await` inside | Always use `async def` for handlers that `await` | Sync handlers run in a threadpool; `await` inside them silently blocks the event loop |
| Hardcoding `status_code=200` for `POST` that creates a resource | Use `status.HTTP_201_CREATED` | Misleads API consumers; `201` is the correct semantic for resource creation |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Every router file uses `APIRouter`, not direct `@app` decorators
- [ ] All request bodies and query params pass through Pydantic models in `server/schemas/`
- [ ] No route handler contains business logic — all delegated to `server/services/`
- [ ] `response_model` is set on every route that returns data
- [ ] All `POST` endpoints that create resources use `status_code=201`
- [ ] No `@app.on_event("startup")` — lifespan context manager is used instead
- [ ] Database sessions are injected via `Depends(get_db)`, never imported directly
- [ ] No `password` or `hashed_password` field appears in any response schema
