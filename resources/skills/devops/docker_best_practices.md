# Docker Best Practices

**Domain:** DevOps
**Loaded when:** `Dockerfile` or `docker-compose.yml` detected in the project root

---

## When to Use

- Writing or modifying a `Dockerfile` for any service.
- Configuring or extending a `docker-compose.yml` for local development or staging.
- Diagnosing slow builds, bloated image sizes, or container startup failures.
- Adding healthchecks, non-root users, or `.dockerignore` files to an existing service.

## When NOT to Use

- Kubernetes or Helm chart work — those have their own deployment conventions.
- Cloud-native build systems (e.g., Cloud Build, Buildpacks) that do not use Dockerfiles directly.

---

## Core Rules

1. **Multi-stage builds are mandatory for production images.** Use a `builder` stage to compile or install dependencies and a lean `runtime` stage that copies only the final artifact. Never ship build tools (`gcc`, `pip`, `npm`) into the runtime image.
2. **Pin every base image to a specific version.** `FROM python:3.12-slim` is acceptable. `FROM python:latest` is forbidden. Unpinned images break reproducibility silently.
3. **Order Dockerfile instructions by change frequency (ascending).** System dependencies → language runtime → package manifest copy → dependency install → application code copy. This maximizes cache reuse across builds.
4. **Copy only the dependency manifest before installing.** `COPY requirements.txt .` then `RUN pip install` — never `COPY . .` before `pip install`. The install layer must be invalidated only when the manifest changes, not on every code edit.
5. **Run containers as a non-root user.** Create a dedicated system user in the builder stage and switch to it before the final `CMD`/`ENTRYPOINT`.
6. **Always provide a `.dockerignore` file.** Exclude `.git/`, `__pycache__/`, `node_modules/`, `.env`, `*.log`, and any test/coverage directories. A missing `.dockerignore` bloats build context and invalidates cache unnecessarily.
7. **Add a `HEALTHCHECK` to every service that exposes an HTTP port.** Use `CMD curl -f http://localhost:PORT/health || exit 1` or equivalent. Without a healthcheck, `docker-compose` cannot determine when a dependency is truly ready.
8. **Use `depends_on` with `condition: service_healthy` in `docker-compose.yml`.** Never rely on `sleep` hacks or fixed delays — wait for the upstream service's healthcheck to pass.

---

## Dockerfile Pattern (Python)

```dockerfile
# ── Stage 1: Builder ────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# Install system build dependencies (only in builder)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy manifest first — install layer is cached until requirements.txt changes
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: Runtime ────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Create a non-root user
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copy application source
COPY --chown=appuser:appgroup . .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Dockerfile Pattern (Node.js)

```dockerfile
# ── Stage 1: Builder ────────────────────────────────────────────────────────
FROM node:20-slim AS builder

WORKDIR /build

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .
RUN npm run build

# ── Stage 2: Runtime ────────────────────────────────────────────────────────
FROM node:20-slim AS runtime

WORKDIR /app

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

COPY --from=builder --chown=appuser:appgroup /build/dist ./dist
COPY --from=builder --chown=appuser:appgroup /build/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /build/package.json .

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

---

## docker-compose.yml Pattern

```yaml
# docker-compose.yml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: runtime
    env_file: .env            # secrets come from .env — never hardcoded
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:16-alpine  # always pinned
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
```

---

## .dockerignore Pattern

```
# Version control
.git/
.gitignore

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.egg-info/
dist/
build/
.venv/
venv/

# Node
node_modules/
.next/
dist/

# Environment and secrets
.env
.env.*
!.env.example

# Testing and coverage
.pytest_cache/
htmlcov/
.coverage
coverage/

# Editor and OS
.idea/
.vscode/
*.DS_Store
```

---

## Common Pitfalls

- **Copying the entire project before installing dependencies.** `COPY . .` before `RUN pip install` means every code change invalidates the expensive install layer. Always copy the manifest first.
- **Using `latest` for base images.** A silent upstream update can break your build or introduce a CVE between runs. Pin the version tag.
- **Running as root.** Most base images default to root. If the container is compromised, the attacker has root inside it. Always switch to a non-root user before `CMD`.
- **Missing `.dockerignore`.** Without it, the build context includes `.git/`, `node_modules/`, `.env`, and other large/sensitive directories — bloating the context and potentially leaking secrets into image layers.
- **Relying on `sleep` instead of healthchecks.** `sleep 5 && docker-compose up api` is fragile. Use `depends_on: condition: service_healthy` paired with a real `HEALTHCHECK`.
- **Installing dev dependencies in the runtime image.** `pip install -r requirements-dev.txt` in a production Dockerfile ships test frameworks and linters. Use a separate stage or `--no-deps` with a prod-only manifest.

---

## Self-Correction Mandate

If you encounter an unexpected build failure, a bloated image, a container running as root, or any pattern that required more than one attempt to get right, you MUST log the failure to `tasks/self-correction.md` before marking the task complete.

Pay special attention to:
- Cache invalidation surprises caused by instruction ordering.
- Permission errors at runtime due to file ownership mismatches between builder and runtime stages.
