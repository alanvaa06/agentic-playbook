# GitHub Actions

**Domain:** DevOps
**Loaded when:** `.github/workflows/` directory detected in the project root

---

## When to Use

- Writing or modifying a GitHub Actions workflow (`.github/workflows/*.yml`).
- Adding lint, test, build, or deploy jobs to an existing pipeline.
- Configuring job dependencies, secrets, matrix builds, or environment protection rules.
- Debugging a failing workflow step or optimizing pipeline wall-clock time.

## When NOT to Use

- GitLab CI or CircleCI — those use different syntax and concepts.
- Local-only automation (use `scripts/` shell scripts or a `Makefile` instead).

---

## Core Rules

1. **Gate every deploy job behind a passing test job.** Use `needs: [test]` on all jobs that push images, deploy infrastructure, or release artifacts. Never deploy from a red pipeline.
2. **Inject secrets exclusively via `${{ secrets.SECRET_NAME }}`.** Never echo, print, or log secret values. GitHub automatically masks registered secrets in logs, but only if they are injected through the `secrets` context — not through environment file tricks.
3. **Pin every third-party action to a full commit SHA, not a tag.** `uses: actions/checkout@v4` is acceptable. `uses: actions/checkout@main` is forbidden. Tags are mutable; SHAs are immutable.
4. **Cache dependency layers keyed on the lockfile hash.** Use `actions/cache` with a cache key like `${{ hashFiles('requirements.txt') }}` or `${{ hashFiles('package-lock.json') }}`. A stale key means a missed cache hit.
5. **Run independent jobs in parallel.** Lint and test can run simultaneously. Only the deploy job needs to wait. Minimize `needs` chains to reduce wall-clock time.
6. **Use environment protection rules for production deployments.** Configure required reviewers in the GitHub Environment settings. Workflows that target a protected environment pause for manual approval automatically.
7. **Set `permissions` explicitly on every workflow.** Default permissions are too broad. Use the principle of least privilege: `contents: read` for CI, `packages: write` only for image push jobs.
8. **Use `concurrency` to cancel stale runs on pull requests.** A new push to a PR branch should cancel the previous in-progress run to save runner minutes.

---

## CI Workflow Pattern (Python)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b  # v5.3.0
        with:
          python-version: "3.12"
      - name: Cache pip
        uses: actions/cache@6849a6489940f00c2f30c0fb92c6274307ccb58a  # v4.1.2
        with:
          path: ~/.cache/pip
          key: pip-${{ hashFiles('requirements.txt') }}
          restore-keys: pip-
      - run: pip install ruff mypy
      - run: ruff check .
      - run: mypy .

  test:
    name: Test
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b  # v5.3.0
        with:
          python-version: "3.12"
      - name: Cache pip
        uses: actions/cache@6849a6489940f00c2f30c0fb92c6274307ccb58a  # v4.1.2
        with:
          path: ~/.cache/pip
          key: pip-${{ hashFiles('requirements.txt') }}
          restore-keys: pip-
      - run: pip install -r requirements.txt
      - run: pytest --tb=short
        env:
          DATABASE_URL: postgresql://test_user:test_pass@localhost:5432/test_db

  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    needs: [lint, test]              # both must pass before deploy runs
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production          # triggers manual approval gate
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - name: Log in to GHCR
        uses: docker/login-action@9780b0c442fbb1117ed29e0efdff1e18412f7567  # v3.3.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push image
        uses: docker/build-push-action@4f58ea79222b3b9dc2c8bbdd6debcef730109a75  # v6.9.0
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## CI Workflow Pattern (Node.js)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af  # v4.1.0
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-node@39370e3970a6d050c480ffad4ff0ed4d3fdee5af  # v4.1.0
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
      - run: npm test
```

---

## Reusable Workflow Pattern

For teams with multiple repos sharing the same CI logic, extract common jobs into a reusable workflow:

```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test Job

on:
  workflow_call:
    inputs:
      python-version:
        required: false
        type: string
        default: "3.12"
    secrets:
      DATABASE_URL:
        required: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b  # v5.3.0
        with:
          python-version: ${{ inputs.python-version }}
      - run: pip install -r requirements.txt
      - run: pytest
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

Call it from another workflow with:

```yaml
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    secrets:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

---

## Matrix Build Pattern

Use matrix builds to test across multiple runtimes without duplicating job definitions:

```yaml
jobs:
  test:
    strategy:
      matrix:
        python-version: ["3.11", "3.12"]
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - uses: actions/setup-python@0b93645e9fea7318ecaed2b359559ac225c90a2b  # v5.3.0
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -r requirements.txt && pytest
```

---

## Common Pitfalls

- **Using mutable action tags (`@v4`, `@main`).** Tags can be moved to a different commit at any time. Pin to the full commit SHA to guarantee reproducibility and prevent supply-chain attacks.
- **Deploying without `needs: [test]`.** If you forget `needs`, the deploy job runs immediately in parallel with the test job and can ship broken code. Always declare the dependency explicitly.
- **Printing or logging secret values.** Even a `run: echo ${{ secrets.MY_KEY }}` leaks the value if GitHub's masking fails. Never reference secrets in `echo`, `print`, or debug steps.
- **Over-broad `permissions`.** Omitting `permissions` gives the workflow the repository's default token permissions, which are often write-all. Always declare the minimum required permissions.
- **Missing `concurrency` on PR workflows.** Without it, rapid pushes queue up multiple redundant runs, consuming runner minutes and cluttering the PR status checks.
- **Not caching dependency installs.** A bare `pip install -r requirements.txt` on every run can add 60–120 seconds to wall-clock time. Always add `actions/cache` keyed on the lockfile hash.
- **Hardcoding environment-specific values (URLs, hostnames) in workflow YAML.** These belong in GitHub Environment variables, not in the workflow file — the file is committed to the repo and may be public.

---

## Self-Correction Mandate

If you encounter a failing workflow step, a leaked secret in logs, a missed cache hit, or any pattern that required more than one attempt to get right, you MUST log the failure to `tasks/self-correction.md` before marking the task complete.

Pay special attention to:
- `needs` dependency chains that are missing or circular.
- Secrets accidentally referenced outside the `secrets` context (e.g., embedded in a URL string).
