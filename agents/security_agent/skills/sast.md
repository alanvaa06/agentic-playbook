# Static Application Security Testing (SAST)

**Domain:** Security
**Loaded when:** `.py`, `.ts`, or `.js` source files are in scope for the current task.

---

## When to Use

- Scanning Python source files for injection vulnerabilities, unsafe subprocess calls, weak cryptography, and hardcoded credentials.
- Scanning JavaScript/TypeScript source files for XSS vectors, prototype pollution, and insecure randomness.
- Running OWASP Top 10 rule sets across a mixed-language codebase with semgrep.
- Reviewing suppression comments (`# nosec`, `// eslint-disable`) to verify they have justifications.

## When NOT to Use

- The task is about secrets in git history — load `secrets_scanning.md` instead.
- The task is about vulnerable dependencies — load `dependency_audit.md` instead.
- The project has no source files in scope (e.g., infra-only change) — skip this skill entirely.

---

## Core Rules

1. **Run bandit on every Python file in scope.** bandit is the canonical Python SAST tool. Always use `-r` (recursive) and `-f json` for machine-readable output. Never rely on a subset of files unless the task is explicitly scoped.
2. **Run semgrep with `--config=auto` as the baseline.** The `auto` config pulls OWASP Top 10 and community rules. For Python projects also add `--config=p/python`; for Node/JS add `--config=p/javascript`.
3. **Every `# nosec` suppression MUST include the rule ID and a one-line justification.** Bare `# nosec` with no rule ID suppresses all bandit rules on that line — a lazy suppression that hides real findings.
4. **HIGH severity bandit findings are blockers.** MEDIUM findings require documentation. LOW findings are informational.
5. **`eval()`, `exec()`, `subprocess(shell=True)`, and `innerHTML` assignment are always escalated to the user.** These patterns have no safe default — every instance requires explicit review regardless of bandit's severity classification.
6. **Never use `Math.random()` or Python's `random` module for security-sensitive values.** These are non-cryptographic PRNGs. Use `secrets.token_hex()` (Python) or `crypto.randomBytes()` (Node).

---

## OWASP Top 10 — Scan Coverage Map

| OWASP Category | Tool | Rule Set |
|----------------|------|----------|
| A01 Broken Access Control | semgrep | `p/owasp-top-ten` |
| A02 Cryptographic Failures | bandit (`B413`, `B303`, `B304`), semgrep | `p/secrets` |
| A03 Injection (SQL, OS, LDAP) | bandit (`B608`, `B602`, `B605`), semgrep | `p/sql-injection` |
| A05 Security Misconfiguration | bandit (`B105`, `B106`, `B107`), trivy config | — |
| A06 Vulnerable Components | `dependency_audit.md` | — |
| A07 Auth Failures | semgrep | `p/jwt` |
| A08 Data Integrity Failures | semgrep | `p/supply-chain` |
| A09 Logging Failures | bandit (`B110`), semgrep | — |

---

## Code Patterns

### bandit — Python SAST

```bash
# Install
pip install bandit

# Scan all Python files recursively, output JSON
bandit -r . -f json -o security/reports/bandit.json

# Exclude test directories (asserts are intentional in tests)
bandit -r . -f json -o security/reports/bandit.json --exclude ./tests,./test

# Human-readable summary with severity filter
bandit -r . --severity-level medium

# Scan a single file
bandit server/utils/subprocess_helper.py -f json
```

**Reading bandit output — key fields:**

```json
{
  "results": [
    {
      "filename": "server/utils/exec.py",
      "line_number": 42,
      "test_id": "B602",
      "test_name": "subprocess_popen_with_shell_equals_true",
      "issue_severity": "HIGH",
      "issue_confidence": "HIGH",
      "issue_text": "subprocess call with shell=True identified, security issue.",
      "more_info": "https://bandit.readthedocs.io/en/latest/plugins/b602_subprocess_popen_with_shell_equals_true.html"
    }
  ]
}
```

Key fields: `filename` + `line_number` (location), `test_id` (use in `# nosec` suppression), `issue_severity` (HIGH/MEDIUM/LOW), `issue_text` (description).

### bandit — suppression format

Only suppress with a specific rule ID and a written justification:

```python
# CORRECT — specific rule ID + justification
result = subprocess.run(cmd, shell=True)  # nosec B602 — cmd is constructed from a validated whitelist of 3 known values defined in config.py:L15

# WRONG — no rule ID, no justification
result = subprocess.run(cmd, shell=True)  # nosec
```

### semgrep — OWASP Top 10 scan

```bash
# Install
pip install semgrep
# or: brew install semgrep

# Baseline scan — auto config covers OWASP Top 10 + community rules
semgrep --config=auto --json --output security/reports/semgrep.json .

# Python-specific rules
semgrep --config=p/python --config=p/sql-injection --json --output security/reports/semgrep-python.json .

# JavaScript/TypeScript rules
semgrep --config=p/javascript --config=p/typescript --json --output security/reports/semgrep-js.json .

# JWT and auth-specific rules
semgrep --config=p/jwt --json --output security/reports/semgrep-jwt.json .

# Human-readable output for review
semgrep --config=auto .
```

**Reading semgrep output — key fields:**

```json
{
  "results": [
    {
      "check_id": "python.lang.security.audit.sqli.formatted-sql-query",
      "path": "server/db/queries.py",
      "start": { "line": 87 },
      "extra": {
        "severity": "ERROR",
        "message": "Detected string formatting in SQL query. Use parameterized queries instead.",
        "metadata": { "owasp": ["A03:2021 - Injection"] }
      }
    }
  ]
}
```

### eslint-plugin-security — Node/JS SAST

```bash
# Install
npm install --save-dev eslint eslint-plugin-security

# Add to .eslintrc.json
```

```json
{
  "plugins": ["security"],
  "extends": ["plugin:security/recommended"],
  "rules": {
    "security/detect-eval-with-expression": "error",
    "security/detect-non-literal-regexp": "warn",
    "security/detect-non-literal-fs-filename": "warn",
    "security/detect-object-injection": "warn",
    "security/detect-possible-timing-attacks": "error",
    "security/detect-pseudoRandomBytes": "error"
  }
}
```

```bash
# Run the scan
npx eslint . --format json --output-file security/reports/eslint-security.json

# Human-readable
npx eslint . --ext .js,.ts
```

**Suppression format — always include justification:**

```typescript
// CORRECT
const filename = req.params.file; // eslint-disable-next-line security/detect-non-literal-fs-filename -- filename is validated against an allowlist in middleware/file-validation.ts:L23
fs.readFile(path.join(UPLOAD_DIR, filename), callback);

// WRONG — no justification
// eslint-disable-next-line security/detect-non-literal-fs-filename
fs.readFile(filename, callback);
```

### Dangerous patterns — always escalate regardless of tool severity

These patterns require a human decision regardless of how the scanner scores them:

```python
# Python — always escalate
eval(user_input)                          # arbitrary code execution
exec(user_input)                          # arbitrary code execution
subprocess.run(cmd, shell=True)           # OS injection
subprocess.Popen(cmd, shell=True)         # OS injection
os.system(user_input)                     # OS injection
pickle.loads(untrusted_data)              # arbitrary code execution on deserialization
yaml.load(data)                           # use yaml.safe_load() instead
import random; random.token_hex(32)       # non-cryptographic PRNG — use secrets.token_hex()
```

```javascript
// JavaScript/TypeScript — always escalate
eval(userInput)                           // arbitrary code execution
document.getElementById('x').innerHTML = userInput  // XSS
new Function(userInput)()                 // arbitrary code execution
Math.random()                             // use crypto.randomBytes() for security tokens
child_process.exec(userInput, callback)   // OS injection — use execFile() with args array
fs.readFile(req.params.path, ...)         // path traversal — validate against allowlist
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `# nosec` with no rule ID | `# nosec B602 — reason` | Bare nosec silently suppresses all bandit rules on the line, hiding unrelated future findings |
| `bandit -r . --skip B101` globally | `bandit -r . --exclude ./tests` | Skipping B101 globally hides real assert-as-auth-bypass bugs in non-test code |
| `semgrep --config=auto` without reviewing false positives | Triage each finding before reporting | auto config includes broad community rules; some are high noise for certain codebases |
| Use `Math.random()` for session tokens, CSRF tokens, or API keys | `crypto.randomBytes(32).toString('hex')` | `Math.random()` is predictable — a PRNG with ~53 bits of state, not a CSPRNG |
| Use `yaml.load(data)` (Python) | `yaml.safe_load(data)` | `yaml.load()` can deserialize arbitrary Python objects from untrusted input |
| `subprocess.run(f"git clone {repo_url}", shell=True)` | `subprocess.run(["git", "clone", repo_url], shell=False)` | `shell=True` with interpolated input enables OS command injection via repo_url |
| Report `issue_confidence: LOW` findings as confirmed vulnerabilities | Label them as "potential" and note the confidence level | Low-confidence bandit findings have high false-positive rates; misreporting erodes trust |

---

## Verification Checklist

Before marking a SAST task as done, confirm:

- [ ] `bandit -r .` returns zero HIGH severity findings (excluding documented suppressions with justifications)
- [ ] All `# nosec` suppressions include the rule ID and a one-line justification
- [ ] `semgrep --config=auto` returns zero ERROR-level findings in OWASP Top 10 categories
- [ ] `eslint-plugin-security` returns zero `error`-level findings (Node/JS projects)
- [ ] All instances of `eval`, `exec`, `subprocess(shell=True)`, `innerHTML` assignment, `Math.random()` (security context), `yaml.load()`, and `pickle.loads()` have been reviewed and either justified or remediated
- [ ] Scan reports saved to `security/reports/` and that directory is in `.gitignore`
- [ ] Every suppressed finding has a reproduction command so it can be verified manually
