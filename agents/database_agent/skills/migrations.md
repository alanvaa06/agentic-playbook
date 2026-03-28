# Database Migrations

**Domain:** Database
**Loaded when:** `alembic` detected in `requirements.txt`, `alembic.ini` present in the project root, or `prisma` detected in `package.json`

---

## When to Use

- Adding, modifying, or removing tables or columns.
- Adding or removing indexes or constraints.
- Backfilling data during a schema change.
- Renaming a column or table in a live production database.
- Implementing zero-downtime schema changes.

## When NOT to Use

- The task involves only query optimization with no schema changes — no migration is needed.
- Seeding test data — use `server/db/seeds/` scripts instead.

---

## Core Rules

1. **Never modify an already-applied migration file.** If a migration has run in any environment (even dev), treat it as immutable. Create a new migration to correct it.
2. **Every Up migration MUST have a working Down migration.** Test the Down migration in a local environment before committing. A Down migration that fails leaves the database in an unrecoverable state.
3. **All schema changes go through migration files.** Never apply DDL manually in production via `psql` or a database GUI. Untracked changes cannot be reproduced, reviewed, or rolled back.
4. **Number migrations sequentially.** Use a sortable prefix — ISO timestamp (`20240101120000_`) for Alembic autogenerate, or integer (`001_`, `002_`) for manual SQL files. This prevents ordering conflicts in team environments.
5. **Add columns as nullable first.** Adding a NOT NULL column with no default to a large table locks the entire table while Postgres validates every existing row. Add nullable → backfill → add constraint is the zero-downtime path.
6. **Use `CREATE INDEX CONCURRENTLY` on existing tables.** Standard `CREATE INDEX` takes an `ACCESS SHARE` lock that blocks writes. `CONCURRENTLY` builds the index without blocking — it takes longer but is safe for production.
7. **Backfill in batches, never all at once.** A single `UPDATE SET new_col = ...` on a 50M-row table creates a giant transaction that holds locks and can exhaust WAL. Batch in groups of 1,000–10,000 rows with a `WHERE id > $last_id` cursor.
8. **Test migrations against a production-scale snapshot.** Timing a migration on a 1k-row dev database reveals nothing about a 50M-row production table. Always estimate lock duration before deploying.

---

## Zero-Downtime Column Addition Pattern

The safe three-step sequence for adding a NOT NULL column to a live table:

**Step 1 — Add nullable column (no downtime)**
```sql
ALTER TABLE users ADD COLUMN display_name TEXT;
```

**Step 2 — Backfill existing rows in batches**
```python
# Alembic data migration
from alembic import op
import sqlalchemy as sa

def upgrade() -> None:
    conn = op.get_bind()
    conn.execute(sa.text("""
        UPDATE users
        SET display_name = full_name
        WHERE display_name IS NULL
          AND id IN (
              SELECT id FROM users WHERE display_name IS NULL LIMIT 5000
          )
    """))
    # Loop until all rows are backfilled
```

**Step 3 — Add NOT NULL constraint (brief lock, much shorter than full scan)**
```sql
-- Only after 100% of rows have been backfilled
ALTER TABLE users ALTER COLUMN display_name SET NOT NULL;
```

---

## Code Patterns

### Alembic — Generate and Apply Migrations

```bash
# Generate a new revision (autogenerate from SQLAlchemy models)
alembic revision --autogenerate -m "add_display_name_to_users"

# Apply all pending migrations
alembic upgrade head

# Roll back the last applied migration
alembic downgrade -1

# Show current migration state
alembic current

# Show full migration history
alembic history --verbose
```

### Alembic — Migration File Structure

```python
# alembic/versions/20240201_120000_add_display_name_to_users.py
"""add display_name to users

Revision ID: abc123def456
Revises: 789xyz
Create Date: 2024-02-01 12:00:00
"""
from alembic import op
import sqlalchemy as sa

revision = "abc123def456"
down_revision = "789xyz"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Step 1: Add nullable (no lock on existing rows)
    op.add_column("users", sa.Column("display_name", sa.Text(), nullable=True))

    # Step 2: Backfill (run in batches for large tables)
    op.execute("UPDATE users SET display_name = full_name WHERE display_name IS NULL")

    # Step 3: Enforce NOT NULL after backfill is complete
    op.alter_column("users", "display_name", nullable=False)


def downgrade() -> None:
    op.drop_column("users", "display_name")
```

### Alembic — Adding a Concurrent Index

```python
# alembic/versions/20240202_090000_add_idx_users_email.py
from alembic import op

revision = "bcd234efg567"
down_revision = "abc123def456"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # CONCURRENTLY cannot run inside a transaction — disable autobegin
    op.execute("COMMIT")
    op.execute(
        "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users (email)"
    )


def downgrade() -> None:
    op.execute("COMMIT")
    op.execute("DROP INDEX CONCURRENTLY IF EXISTS idx_users_email")
```

### Alembic — Table Rename (Zero-Downtime)

```python
# Rename is a two-phase operation across two deployments.
# Phase 1 (this migration): create a view with the old name pointing to the new table
# Phase 2 (next migration after code is deployed): drop the view

def upgrade() -> None:
    op.rename_table("old_table_name", "new_table_name")
    op.execute("CREATE VIEW old_table_name AS SELECT * FROM new_table_name")


def downgrade() -> None:
    op.execute("DROP VIEW IF EXISTS old_table_name")
    op.rename_table("new_table_name", "old_table_name")
```

### Alembic — Column Rename (Safe Pattern)

```python
def upgrade() -> None:
    # Never use op.alter_column for a rename on large tables without testing
    op.alter_column("users", "old_name", new_column_name="new_name")


def downgrade() -> None:
    op.alter_column("users", "new_name", new_column_name="old_name")
```

### Prisma — Generate and Apply Migrations

```bash
# Create a new migration (Prisma compares schema to current DB state)
npx prisma migrate dev --name add_display_name_to_users

# Apply all pending migrations in production (no interactive prompts)
npx prisma migrate deploy

# Roll back is NOT built into Prisma — use shadow database or manual SQL
# Best practice: always write a corresponding rollback SQL file in db/rollbacks/

# Validate that schema.prisma matches the database
npx prisma migrate status

# Generate the Prisma client after schema changes
npx prisma generate
```

### Prisma — schema.prisma Pattern

```prisma
// prisma/schema.prisma

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id          String   @id @default(uuid()) @db.Uuid
  email       String   @unique
  displayName String?  @map("display_name")   // nullable first; enforce NOT NULL after backfill
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz

  @@map("users")
  @@index([email])
}
```

### Manual Batch Backfill Script (Python / asyncpg)

```python
import asyncio
import asyncpg
from server.config import settings

BATCH_SIZE = 5_000

async def backfill_display_name() -> None:
    pool = await asyncpg.create_pool(dsn=settings.DATABASE_URL, min_size=1, max_size=3)
    last_id = None
    total = 0

    async with pool.acquire() as conn:
        while True:
            if last_id is None:
                rows = await conn.fetch(
                    "SELECT id FROM users WHERE display_name IS NULL LIMIT $1",
                    BATCH_SIZE,
                )
            else:
                rows = await conn.fetch(
                    "SELECT id FROM users WHERE display_name IS NULL AND id > $1 LIMIT $2",
                    last_id, BATCH_SIZE,
                )

            if not rows:
                break

            ids = [r["id"] for r in rows]
            await conn.execute(
                "UPDATE users SET display_name = full_name WHERE id = ANY($1::uuid[])",
                ids,
            )
            last_id = ids[-1]
            total += len(ids)
            print(f"Backfilled {total} rows...")

    print(f"Done. Total rows updated: {total}")
    await pool.close()


if __name__ == "__main__":
    asyncio.run(backfill_display_name())
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Edit an already-applied migration file | Create a new migration to correct the state | Edited migrations diverge from what ran in production; rollbacks become impossible |
| `ALTER TABLE users ADD COLUMN name TEXT NOT NULL` on a large table | Add nullable first → backfill → add NOT NULL constraint | Full-table lock blocks all reads and writes while Postgres validates every row |
| `CREATE INDEX idx ON users (email)` on a live table | `CREATE INDEX CONCURRENTLY idx ON users (email)` | Standard CREATE INDEX takes a write-blocking lock; CONCURRENTLY does not |
| Single `UPDATE SET new_col = derived_value` on 50M rows | Batch-update in groups of 5k rows | A single giant transaction holds row locks, inflates WAL, and can cause replication lag |
| Applying DDL manually via `psql` in production | Create a numbered Alembic or Prisma migration | Manual DDL is untracked, unreviewable, and cannot be rolled back deterministically |
| `alembic upgrade head` without running `alembic current` first | Check `alembic current` and `alembic history` before deploying | Deploying to a database already at `head` is a no-op, but deploying a wrong revision corrupts state |
| No Down migration (`pass` in `downgrade()`) | Write a fully working `downgrade()` that reverses the change | A broken Down migration means you cannot roll back — the only recovery is a database restore |
| Renaming a column in a single deployment | Two-phase rename: deploy code to handle both names → migrate → remove old name | Renaming mid-deployment causes `column not found` errors in in-flight requests |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] The migration file has both a working `upgrade()` and a working `downgrade()`
- [ ] The migration was tested locally with a `downgrade` followed by `upgrade` to confirm reversibility
- [ ] No existing applied migration file was modified — a new revision was created instead
- [ ] New NOT NULL columns were added nullable first, then backfilled, then constrained
- [ ] Indexes on existing large tables use `CREATE INDEX CONCURRENTLY`
- [ ] Backfills on large tables use batching, not a single `UPDATE` statement
- [ ] All schema changes are captured in migration files — no manual DDL was applied
- [ ] `alembic current` or `prisma migrate status` confirms the database is at the expected revision after applying
- [ ] For Prisma: `prisma generate` was run after the migration to regenerate the client
