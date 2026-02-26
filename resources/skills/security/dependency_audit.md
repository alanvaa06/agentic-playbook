# Dependency Audit

**Domain:** Security
**Loaded when:** `requirements.txt`, `package.json`, `poetry.lock`, `package-lock.json`, or `Dockerfile` is in scope for the current task.

---

## When to Use

- Auditing Python or Node.js dependency manifests for known CVEs.
- Scanning a Docker image for vulnerable OS packages and language runtime dependencies.
- Triaging CVE findings and classifying them as blockers, warnings, or informational.
- Advising on dependency pinning strategy to reduce supply-chain risk.

## When NOT to Use

- The task involves secrets in source code or git history — load `secrets_scanning.md` instead.
- The task involves code logic vulnerabilities — load `sast.md` instead.

---

## CVSS Severity Thresholds

Apply these thresholds to every finding from every tool. They are non-negotiable.

| CVSS Score | Severity | Action Required |
|------------|----------|-----------------|
| 9.0–10.0 | **Critical / Blocker** | Must be resolved before the task is marked done. Escalate immediately. |
| 7.0–8.9 | **High / Blocker** | Must be resolved before the task is marked done. |
| 4.0–6.9 | **Medium / Warning** | Document with an accepted-risk note or open a remediation ticket. |
| 0.1–3.9 | **Low / Informational** | Report but do not block. |
| N/A | **Unscored** | Treat as Medium until a score is published. |

---

## Core Rules

1. **Always use a lockfile when scanning Python projects.** `pip-audit` against `requirements.txt` alone may miss transitive dependencies. Prefer scanning the installed environment or a resolved lockfile (`pip-audit --requirement requirements.txt` captures direct deps; `pip-audit` with no args scans the active virtualenv including transitive deps).
2. **Treat unscored CVEs as Medium.** A CVE without a published CVSS score is not low-risk — it is unclassified. Assume Medium until the NVD record is updated.
3. **Pin dependencies to exact versions in production.** Range specifiers (`>=`, `^`, `~`, `*`) allow silent upgrades that introduce new CVEs between audit runs. Pin with `==` (Python) or exact versions (Node).
4. **Never use `--legacy-peer-deps` to silence `npm audit`.** This flag suppresses peer dependency resolution warnings and can mask CVEs in peer packages.
5. **Container scans cover OS packages too.** Language-level audits (`pip-audit`, `npm audit`) miss CVEs in the base OS image (e.g., `libssl`, `libc`). Always run `trivy` for any project that ships a Docker image.
6. **Report the upgrade path, not just the CVE.** Every finding must include the minimum safe version that patches the vulnerability, so the remediation is unambiguous.

---

## Code Patterns

### pip-audit — Python dependency scan

```bash
# Install
pip install pip-audit

# Scan direct dependencies from requirements.txt
pip-audit --requirement requirements.txt --format json --output security/reports/pip-audit.json

# Scan the entire active virtualenv (includes transitive dependencies — preferred)
pip-audit --format json --output security/reports/pip-audit.json

# Human-readable output for quick review
pip-audit --requirement requirements.txt
```

**Reading the output:**

```json
{
  "dependencies": [
    {
      "name": "cryptography",
      "version": "38.0.1",
      "vulns": [
        {
          "id": "PYSEC-2023-XXX",
          "fix_versions": ["41.0.0"],
          "description": "...",
          "aliases": ["CVE-2023-XXXX"]
        }
      ]
    }
  ]
}
```

Key fields: `name` + `version` (what is installed), `vulns[].fix_versions` (minimum safe version), `vulns[].aliases` (CVE ID for CVSS lookup).

### npm audit — Node.js dependency scan

```bash
# Run from the project root (requires package-lock.json or yarn.lock)
npm audit --json > security/reports/npm-audit.json

# Human-readable summary
npm audit

# Automatically fix low-risk vulnerabilities (review diff before committing)
npm audit fix

# For high/critical only — do NOT use --legacy-peer-deps to suppress output
npm audit --audit-level=high
```

**Reading the output:**

```json
{
  "vulnerabilities": {
    "lodash": {
      "severity": "high",
      "via": ["CVE-2021-23337"],
      "fixAvailable": { "name": "lodash", "version": "4.17.21" },
      "range": "<4.17.21"
    }
  }
}
```

Key fields: `severity`, `via` (CVE IDs), `fixAvailable.version` (upgrade target), `range` (affected versions).

### trivy — Container image scan

Covers OS packages (apt/apk/yum), language runtime deps (pip/npm inside the image), and Dockerfile misconfigurations.

```bash
# Install
brew install aquasecurity/trivy/trivy   # macOS
# or: https://aquasecurity.github.io/trivy/latest/getting-started/installation/

# Scan a local image
trivy image --format json --output security/reports/trivy.json <image-name>:<tag>

# Scan and filter by severity
trivy image --severity HIGH,CRITICAL <image-name>:<tag>

# Scan a Dockerfile for misconfigurations (before building)
trivy config --format json --output security/reports/trivy-config.json .

# Scan the filesystem (useful in CI before image build)
trivy fs --format json --output security/reports/trivy-fs.json .
```

**Reading the output — key fields:**

```json
{
  "Results": [
    {
      "Target": "python:3.12-slim (debian 12.4)",
      "Vulnerabilities": [
        {
          "VulnerabilityID": "CVE-2023-XXXX",
          "PkgName": "libssl3",
          "InstalledVersion": "3.0.11",
          "FixedVersion": "3.0.12",
          "Severity": "HIGH",
          "CVSS": { "nvd": { "V3Score": 7.5 } }
        }
      ]
    }
  ]
}
```

### CVE triage — accepted-risk documentation

When a CVE cannot be fixed immediately (no patch available, upgrade breaks compatibility), document the accepted risk in `security/policies/accepted-risks.md`:

```markdown
## Accepted Risk — [CVE-ID]

| Field | Value |
|-------|-------|
| CVE | CVE-2023-XXXX |
| Package | cryptography 38.0.1 |
| CVSS | 7.5 (High) |
| Reason not fixed | No patch available as of [date]; upstream issue open at [URL] |
| Mitigating controls | Feature using this package is behind authentication; input is validated |
| Re-review date | [date + 30 days] |
| Approved by | [user name] |
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `pip install -r requirements.txt` then manually check PyPI for CVEs | `pip-audit --requirement requirements.txt` | Manual checks miss transitive dependencies and known CVE databases |
| `npm audit --legacy-peer-deps` | Fix peer dependency conflicts explicitly | `--legacy-peer-deps` silences warnings that may mask real CVEs |
| Leave `"lodash": "*"` in `package.json` | Pin to `"lodash": "4.17.21"` | Wildcard allows npm to silently install vulnerable versions on fresh installs |
| Skip container scanning if language deps pass | Run `trivy image` even if `pip-audit` is clean | Language audits miss OS-level vulnerabilities in the base image |
| Mark a CVSS 5.0 finding "low risk" without documentation | Write an accepted-risk entry in `security/policies/accepted-risks.md` | Undocumented accepted risks accumulate invisibly and are never re-reviewed |
| Run `npm audit fix --force` | Run `npm audit fix` (no `--force`) and review the diff | `--force` can introduce breaking major version changes |

---

## Verification Checklist

Before marking a dependency audit task as done, confirm:

- [ ] `pip-audit` returned zero findings with CVSS ≥ 7.0 (or all are documented in `accepted-risks.md`)
- [ ] `npm audit` returned zero HIGH or CRITICAL findings (or all are documented in `accepted-risks.md`)
- [ ] `trivy image` returned zero HIGH or CRITICAL findings (or all are documented in `accepted-risks.md`)
- [ ] All accepted-risk entries include a re-review date within 30 days
- [ ] All production dependencies are pinned to exact versions (`==` for Python, exact version for Node)
- [ ] Scan reports are saved to `security/reports/` and `security/reports/` is in `.gitignore`
- [ ] Every finding includes the minimum safe version (upgrade path) in the report
