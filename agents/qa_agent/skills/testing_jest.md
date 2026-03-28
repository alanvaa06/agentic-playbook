# Testing — Jest

**Domain:** QA
**Loaded when:** `jest` detected in `package.json`

---

## When to Use

- Writing or extending unit tests, integration tests, or API contract tests for Node.js / TypeScript services.
- Adding Supertest HTTP client tests for Express or Fastify endpoints.
- Configuring coverage thresholds, module mocks, or DB teardown strategies in an existing Jest suite.

## When NOT to Use

- Python-based services — load `testing_pytest.md` instead.
- End-to-end browser testing (Playwright, Cypress) — those run outside Jest's process model.
- React component tests — use React Testing Library conventions alongside Jest, not raw `supertest`.

---

## Core Rules

1. **Use `supertest` for HTTP-level integration tests, never spin up a real server.** Call `supertest(app)` directly without calling `app.listen()`. This avoids port conflicts and ensures the server is garbage-collected after the test.
2. **Create one DB connection per test file, not per test.** Open the connection in `beforeAll`, close it in `afterAll`. Per-test connections are expensive and exhaust connection pool limits on CI.
3. **Isolate DB state with transactions, not `DELETE FROM`.** Begin a transaction in `beforeEach`, roll it back in `afterEach`. Rollback is faster than deletion and preserves sequence counters.
4. **Use `jest.mock()` at the module level, never inside a test function.** Module-level mocks are hoisted by Babel/ts-jest and apply before imports. Mocks created inside test functions are not reliably reset.
5. **Always call `jest.clearAllMocks()` in `afterEach`, or enable `clearMocks: true` in `jest.config`.** Stale call counts and mock implementations are the most common source of false-positive tests.
6. **Use `jest.spyOn` for partial mocks; restore with `.mockRestore()` in `afterEach`.** Never `jest.mock()` an entire module when you only need to intercept one method — it kills tree-shaking and hides coverage gaps.
7. **Set coverage thresholds in `jest.config`; fail the build when they drop.** Configure `branches`, `functions`, `lines`, and `statements` — never leave them all at `0`.
8. **Never use `done` callbacks in async tests.** Return a Promise or use `async/await`. The `done` pattern swallows unhandled rejections and produces misleading timeout errors.
9. **Separate unit tests (`*.unit.test.ts`) from integration tests (`*.integration.test.ts`).** Run unit tests on every commit; run integration tests (which need a DB) on CI only. Configure separate `testMatch` patterns in Jest projects.

---

## Code Patterns

### Supertest with Express — no live server

```typescript
// tests/users.integration.test.ts
import request from "supertest";
import { app } from "../src/app";           // app without app.listen()
import { db } from "../src/db/client";

beforeAll(async () => {
  await db.migrate.latest();
});

afterAll(async () => {
  await db.destroy();
});

describe("POST /api/v1/users", () => {
  it("returns 201 and the created user", async () => {
    const res = await request(app)
      .post("/api/v1/users")
      .send({ email: "jane@example.com", name: "Jane" })
      .set("Accept", "application/json");

    expect(res.status).toBe(201);           // status first
    expect(res.body.email).toBe("jane@example.com");
    expect(res.body.password).toBeUndefined(); // never leak credentials
  });
});
```

### Transaction-based DB isolation

```typescript
// tests/helpers/db.ts
import { db } from "../../src/db/client";
import { Knex } from "knex";

let trx: Knex.Transaction;

export async function beginTestTransaction(): Promise<void> {
  trx = await db.transaction();
  // Override the module-level db reference for the duration of the test
  jest.spyOn(db, "transaction").mockResolvedValue(trx as any);
}

export async function rollbackTestTransaction(): Promise<void> {
  await trx.rollback();
}
```

```typescript
// tests/users.integration.test.ts
import { beginTestTransaction, rollbackTestTransaction } from "./helpers/db";

beforeEach(beginTestTransaction);
afterEach(rollbackTestTransaction);
```

### Module-level mock with jest.mock

```typescript
// Hoisted — must be at module scope, not inside describe/it
jest.mock("../src/services/emailService", () => ({
  sendWelcomeEmail: jest.fn().mockResolvedValue(undefined),
}));

import { sendWelcomeEmail } from "../src/services/emailService";

afterEach(() => {
  jest.clearAllMocks();
});

it("sends a welcome email on registration", async () => {
  await request(app).post("/api/v1/users").send({ email: "x@y.com" });
  expect(sendWelcomeEmail).toHaveBeenCalledTimes(1);
  expect(sendWelcomeEmail).toHaveBeenCalledWith("x@y.com");
});
```

### Partial mock with jest.spyOn

```typescript
import * as stripe from "../src/lib/stripe";

let chargeSpy: jest.SpyInstance;

beforeEach(() => {
  chargeSpy = jest
    .spyOn(stripe, "createCharge")
    .mockResolvedValue({ id: "ch_test_123", status: "succeeded" });
});

afterEach(() => {
  chargeSpy.mockRestore();
});
```

### Coverage thresholds in jest.config

```typescript
// jest.config.ts
import type { Config } from "jest";

const config: Config = {
  preset: "ts-jest",
  testEnvironment: "node",
  clearMocks: true,
  projects: [
    { displayName: "unit",        testMatch: ["**/*.unit.test.ts"] },
    { displayName: "integration", testMatch: ["**/*.integration.test.ts"] },
  ],
  coverageThreshold: {
    global: {
      branches:   80,
      functions:  85,
      lines:      85,
      statements: 85,
    },
  },
  collectCoverageFrom: ["src/**/*.ts", "!src/**/*.d.ts", "!src/db/migrations/**"],
};

export default config;
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `app.listen(3000)` in test setup | `supertest(app)` without `listen()` | Live server causes EADDRINUSE errors in parallel test runs; port cleanup is unreliable |
| `DELETE FROM users` in `afterEach` | Transaction rollback via `beforeEach`/`afterEach` | Deletion is slower, resets auto-increment counters, and fails if FK constraints exist |
| `jest.mock(...)` inside `it(...)` or `describe(...)` | Module-scope `jest.mock(...)` | Inside-block mocks are not hoisted; the real module is already imported and the mock has no effect |
| `done` callback in async test | `return promise` or `async/await` | Unhandled rejections inside `done` callbacks are swallowed; test appears to pass while the assertion failed |
| Single `jest.config.js` running unit + integration together | `projects` array separating `*.unit.test.ts` from `*.integration.test.ts` | Integration tests require a live DB; running them on every save makes the feedback loop unusably slow |
| `coverageThreshold` left at `0` or omitted | Set meaningful thresholds per project | Without thresholds, coverage drops silently and is only noticed after a production incident |
| `expect(fn).toHaveBeenCalled()` without `clearAllMocks` | Enable `clearMocks: true` in config | Call counts accumulate across tests; a test can pass only because a previous test made the same call |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] `app` is imported without calling `.listen()` — `supertest(app)` is used directly
- [ ] DB connection is opened in `beforeAll` and closed in `afterAll` — not per-test
- [ ] `beforeEach`/`afterEach` wrap each test in a transaction that rolls back
- [ ] All `jest.mock()` calls are at module scope, outside any `describe`/`it` blocks
- [ ] `clearMocks: true` is set in `jest.config` or `jest.clearAllMocks()` runs in `afterEach`
- [ ] `coverageThreshold` is configured with non-zero values for `branches`, `functions`, `lines`, `statements`
- [ ] No `done` callback — all async tests use `async/await`
- [ ] Unit and integration tests use separate `testMatch` patterns
- [ ] `jest --coverage` passes without threshold violations
