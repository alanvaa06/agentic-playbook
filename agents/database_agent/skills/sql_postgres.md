# SQL & Postgres

**Domain:** Backend
**Loaded when:** `psycopg2`, `psycopg`, `asyncpg`, or `pg` detected in `requirements.txt` or `package.json`

---

## When to Use

- Writing or modifying SQL queries that run directly against PostgreSQL.
- Setting up database connections using async drivers (`asyncpg`, `psycopg3`).
- Creating or altering tables, indexes, or migrations.
- Optimizing slow queries or debugging query plans.

## When NOT to Use

- The project uses Supabase client libraries exclusively — load `supabase_rls.md` instead (RLS handles access control, not raw SQL).
- Pure ORM work with SQLAlchemy models where no raw SQL is needed — that belongs in a future `sqlalchemy_orm.md` skill.

---

## Core Rules

1. **Always use parameterized queries.** Pass values as parameters (`$1`, `%s`, `:name`), never via f-strings or string concatenation. SQL injection is the most dangerous and most preventable vulnerability.
2. **Use `async` drivers in async applications.** If the project uses FastAPI or any async framework, use `asyncpg` or `psycopg3` in async mode. Never use synchronous `psycopg2` inside `async def` handlers — it blocks the event loop.
3. **Every table MUST have a primary key.** Prefer `UUID` (`gen_random_uuid()`) for distributed systems or `BIGSERIAL` for single-database applications. Never use `SERIAL` (32-bit) for tables expected to grow beyond a few million rows.
4. **Add indexes for every column used in `WHERE`, `JOIN`, or `ORDER BY` clauses.** Missing indexes are the number-one cause of slow queries. Use `EXPLAIN ANALYZE` to verify the index is being used.
5. **Use `TIMESTAMPTZ` for all timestamp columns, never `TIMESTAMP`.** Bare `TIMESTAMP` stores no timezone information. When the server or client timezone changes, every stored time silently shifts.
6. **All schema changes go through migration files.** Migrations live in `server/db/migrations/`, numbered sequentially (`001_create_users.sql`, `002_add_projects.sql`). Never apply DDL manually in production.
7. **Use transactions for multi-step writes.** Any operation that touches more than one table, or inserts multiple rows that must succeed together, MUST be wrapped in an explicit transaction (`BEGIN ... COMMIT`).
8. **Always set connection pool limits.** Configure `min_size` and `max_size` on the pool. Never open unlimited connections — PostgreSQL has a hard connection limit (default 100) and each connection consumes ~10MB of RAM.

---

## Code Patterns

### Async connection pool with asyncpg

```python
# server/db/session.py
import asyncpg
from server.config import settings

pool: asyncpg.Pool | None = None

async def init_pool() -> asyncpg.Pool:
    global pool
    pool = await asyncpg.create_pool(
        dsn=settings.DATABASE_URL,
        min_size=2,
        max_size=10,
    )
    return pool

async def get_pool() -> asyncpg.Pool:
    if pool is None:
        raise RuntimeError("Database pool not initialized")
    return pool
```

### Parameterized query (asyncpg)

```python
async def get_user_by_email(email: str) -> dict | None:
    pool = await get_pool()
    row = await pool.fetchrow(
        "SELECT id, email, full_name, is_active FROM users WHERE email = $1",
        email,
    )
    return dict(row) if row else None
```

### Parameterized query (psycopg3 async)

```python
import psycopg

async def get_user_by_email(conn: psycopg.AsyncConnection, email: str) -> dict | None:
    async with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
        await cur.execute(
            "SELECT id, email, full_name, is_active FROM users WHERE email = %s",
            (email,),
        )
        return await cur.fetchone()
```

### Transaction for multi-step write

```python
async def transfer_funds(
    pool: asyncpg.Pool,
    from_account: str,
    to_account: str,
    amount: int,
) -> None:
    async with pool.acquire() as conn:
        async with conn.transaction():
            await conn.execute(
                "UPDATE accounts SET balance = balance - $1 WHERE id = $2",
                amount, from_account,
            )
            await conn.execute(
                "UPDATE accounts SET balance = balance + $1 WHERE id = $2",
                amount, to_account,
            )
```

### Migration file structure

```sql
-- server/db/migrations/001_create_users.sql

CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    hashed_password TEXT NOT NULL,
    full_name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_users_email ON users (email);
```

### Index verification with EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT id, email, full_name
FROM users
WHERE email = 'test@example.com';

-- Expected: "Index Scan using idx_users_email on users"
-- Red flag: "Seq Scan on users" means the index is missing or not being used
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `f"SELECT * FROM users WHERE email = '{email}'"` | `"SELECT ... WHERE email = $1", email` | SQL injection — an attacker can drop tables or exfiltrate data via the email field |
| `psycopg2.connect()` inside an `async def` handler | Use `asyncpg` or `psycopg3` async mode | Synchronous drivers block the event loop; all concurrent requests stall |
| `CREATE TABLE ... (id SERIAL PRIMARY KEY)` | `id BIGSERIAL` or `id UUID DEFAULT gen_random_uuid()` | `SERIAL` overflows at ~2.1 billion rows; `BIGSERIAL` is safe to 9.2 quintillion |
| `created_at TIMESTAMP DEFAULT now()` | `created_at TIMESTAMPTZ DEFAULT now()` | `TIMESTAMP` loses timezone info; times silently shift when server timezone changes |
| `SELECT *` in application queries | List columns explicitly: `SELECT id, email, name` | `SELECT *` fetches unnecessary data, breaks when columns are added, and can leak sensitive fields |
| Applying schema changes via `psql` on production | Create a numbered migration file in `server/db/migrations/` | Untracked DDL changes cannot be reproduced, reviewed, or rolled back |
| Opening a new connection per request without a pool | Use `asyncpg.create_pool()` with `min_size` / `max_size` | Each connection uses ~10MB RAM; PostgreSQL defaults to max 100 connections total |
| Multi-table writes without a transaction | Wrap in `async with conn.transaction()` | Partial writes leave the database in an inconsistent state on failure |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] All SQL queries use parameterized values — no f-strings or string concatenation
- [ ] Async handlers use async database drivers (`asyncpg` or `psycopg3`), not `psycopg2`
- [ ] Every new table has a primary key (`UUID` or `BIGSERIAL`)
- [ ] All timestamp columns use `TIMESTAMPTZ`, not `TIMESTAMP`
- [ ] Columns used in `WHERE`, `JOIN`, or `ORDER BY` have indexes
- [ ] Schema changes are captured in numbered migration files in `server/db/migrations/`
- [ ] Multi-step writes are wrapped in explicit transactions
- [ ] Connection pool has `min_size` and `max_size` configured
- [ ] No `SELECT *` in application queries — all columns are listed explicitly
