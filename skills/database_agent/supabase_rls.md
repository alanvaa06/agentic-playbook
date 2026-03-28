# Supabase Row Level Security

**Domain:** Backend
**Loaded when:** `supabase` detected in `requirements.txt` or `@supabase/supabase-js` detected in `package.json`

---

## When to Use

- Creating or modifying database tables that store user-owned data.
- Implementing authentication flows using Supabase Auth.
- Writing RLS policies to control who can read, insert, update, or delete rows.
- Using the Supabase Python client (`supabase-py`) or JS client for CRUD operations.

## When NOT to Use

- Direct Postgres queries via `psycopg2` or `asyncpg` without Supabase — load `sql_postgres.md` instead.
- Supabase Storage (file uploads) — that requires its own skill file (not yet available).

---

## Core Rules

1. **Enable RLS on every table that stores user data.** After `CREATE TABLE`, always run `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`. A table without RLS is publicly readable through the Supabase API by default.
2. **Write explicit policies for every CRUD operation.** RLS with no policies blocks all access. Define separate `SELECT`, `INSERT`, `UPDATE`, and `DELETE` policies. Never use a single `ALL` policy — it obscures intent and is harder to audit.
3. **Use `auth.uid()` to scope data to the authenticated user.** The canonical filter is `auth.uid() = user_id`. Never pass the user ID from the client as a query parameter to filter rows — the client can forge it.
4. **Use a single Supabase client instance.** Define it in `server/lib/supabase.py` (Python) or `server/lib/supabase.ts` (Node). Never instantiate the client inline inside a route handler.
5. **Use the `service_role` key only on the server.** The service role key bypasses RLS entirely. NEVER expose it to the client or include it in frontend bundles. Use the `anon` key for client-side operations.
6. **Always handle `error` from Supabase responses.** Every Supabase client call returns `{ data, error }`. NEVER access `data` without first checking `error is not None` (Python) or `error !== null` (JS).
7. **Use Supabase Auth for JWT verification.** Never roll your own JWT verification when Supabase Auth is available. Use `supabase.auth.get_user(token)` to validate tokens server-side.
8. **Migrations go in `server/db/migrations/`.** RLS policies are SQL and must be version-controlled. Never apply policies manually through the Supabase dashboard in production.

---

## Code Patterns

### Supabase client singleton (Python)

```python
# server/lib/supabase.py
from supabase import create_client, Client
from server.config import settings

supabase: Client = create_client(
    settings.SUPABASE_URL,
    settings.SUPABASE_SERVICE_ROLE_KEY,
)
```

### RLS migration: user-owned table

```sql
-- server/db/migrations/001_create_projects.sql

CREATE TABLE projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Users can only see their own projects
CREATE POLICY "select_own_projects" ON projects
    FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert projects for themselves
CREATE POLICY "insert_own_projects" ON projects
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own projects
CREATE POLICY "update_own_projects" ON projects
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own projects
CREATE POLICY "delete_own_projects" ON projects
    FOR DELETE USING (auth.uid() = user_id);
```

### Querying with the Supabase Python client

```python
# server/services/project_service.py
from server.lib.supabase import supabase

async def get_user_projects(user_id: str) -> list[dict]:
    response = supabase.table("projects") \
        .select("id, name, description, created_at") \
        .eq("user_id", user_id) \
        .order("created_at", desc=True) \
        .execute()

    if response.error:
        raise RuntimeError(f"Supabase query failed: {response.error.message}")

    return response.data
```

### Auth token verification in a FastAPI dependency

```python
# server/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from server.lib.supabase import supabase

bearer_scheme = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    token = credentials.credentials
    user_response = supabase.auth.get_user(token)

    if user_response.user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    return user_response.user
```

### RLS policy for shared resources (team-based access)

```sql
-- Users can see projects belonging to any team they are a member of
CREATE POLICY "select_team_projects" ON projects
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_members
            WHERE team_members.team_id = projects.team_id
              AND team_members.user_id = auth.uid()
        )
    );
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Create a table without `ENABLE ROW LEVEL SECURITY` | Always enable RLS on user-facing tables | Without RLS, the Supabase API exposes all rows to anyone with the `anon` key |
| `CREATE POLICY ... FOR ALL USING (true)` | Write separate policies per operation (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) | `ALL` + `true` disables security entirely; separate policies are auditable |
| `.eq("user_id", request.query_params["user_id"])` | Let RLS handle scoping via `auth.uid() = user_id` | Client-provided IDs can be forged; RLS uses the cryptographically verified JWT |
| `create_client(url, service_role_key)` in frontend code | Use `anon` key in frontend; `service_role` only on the server | The service role key bypasses all RLS — exposing it is a full data breach |
| `response = supabase.table(...).execute()` then access `response.data` directly | Check `response.error` first | Ignoring errors silently returns `None` or stale data; failures go undetected |
| Applying RLS policies via the Supabase dashboard | Version-control policies as SQL migrations in `server/db/migrations/` | Dashboard changes are invisible to the team and cannot be rolled back |
| Rolling your own JWT decode with `pyjwt` | `supabase.auth.get_user(token)` | Custom JWT handling misses token revocation, audience checks, and Supabase session management |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Every table with user data has `ENABLE ROW LEVEL SECURITY`
- [ ] Separate RLS policies exist for `SELECT`, `INSERT`, `UPDATE`, and `DELETE`
- [ ] All policies use `auth.uid()` — no client-provided user ID used for access control
- [ ] The `service_role` key is only used in server-side code, never in the frontend
- [ ] Every Supabase response checks `error` before accessing `data`
- [ ] A single Supabase client instance exists in `server/lib/supabase.py`
- [ ] All RLS policies are stored as SQL migration files in `server/db/migrations/`
- [ ] Auth token verification uses `supabase.auth.get_user()`, not custom JWT decoding
