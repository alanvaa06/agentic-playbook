# Secrets Scanning

**Domain:** Security
**Loaded when:** Always — `.git/` is always present. This skill is loaded on every Security Agent invocation.

---

## When to Use

- Auditing git commit history for accidentally committed secrets, credentials, or private keys.
- Setting up pre-commit hooks to block secrets from being committed in the future.
- Verifying that `.gitignore` is complete and that sensitive file patterns are covered.
- Reviewing CI workflow files for secret exposure in `echo`, `run`, or `env` steps.

## When NOT to Use

- The task is purely about dependency vulnerabilities — load `dependency_audit.md` instead.
- The task is about code logic vulnerabilities — load `sast.md` instead.

---

## Core Rules

1. **Always scan at least the last 50 commits on the current branch.** Recent history is the highest-risk window; a secret committed and immediately deleted is still in the git object store.
2. **Use both pattern-based and entropy-based detection.** Pattern-based tools (gitleaks) catch known secret formats (AWS keys, GitHub tokens). Entropy-based tools (truffleHog) catch unknown high-entropy strings. Neither alone is sufficient.
3. **Verify `.gitignore` covers all sensitive file patterns before running any other scan.** A missing `.gitignore` entry is the root cause of most committed secrets — fix the gate first.
4. **Pre-commit hooks are the only reliable prevention mechanism.** Scanner findings in history mean the gate was missing. Always recommend installing `detect-secrets` as part of remediation.
5. **Never propose rotating a secret autonomously.** Rotation touches external systems (cloud consoles, third-party dashboards). Always present the finding and ask the user to confirm rotation before proceeding.
6. **A clean scan result is not permanent.** Every new commit is a new risk surface. Always recommend re-running after significant commit activity.

---

## Code Patterns

### .gitignore completeness audit

Before running scanners, verify these patterns are present in `.gitignore`. Report any that are missing.

```
# Required entries in .gitignore
.env
.env.*
!.env.example
*.pem
*.key
*.p12
*.pfx
*.jks
*.keystore
*.crt
*.cer
*.der
*.p8
secrets/
credentials/
```

### gitleaks — scan last 50 commits

Pattern-based scanner. Detects known secret formats (AWS, GCP, GitHub, Stripe, Slack, etc.).

```bash
# Install
brew install gitleaks          # macOS
# or: pip install gitleaks / download from https://github.com/gitleaks/gitleaks/releases

# Scan the last 50 commits on the current branch
gitleaks detect --source . --log-opts="HEAD~50..HEAD" --report-format json --report-path security/reports/gitleaks.json

# Scan entire history (slower — use for first-time audit)
gitleaks detect --source . --report-format json --report-path security/reports/gitleaks-full.json

# Review findings
cat security/reports/gitleaks.json | python -m json.tool
```

### truffleHog — entropy-based scan

Catches high-entropy strings that don't match known patterns (custom tokens, internal secrets).

```bash
# Install
pip install trufflehog
# or: brew install trufflehog

# Scan git history with entropy detection
trufflehog git file://. --since-commit HEAD~50 --json > security/reports/trufflehog.json

# Scan for high-entropy strings only (reduces noise)
trufflehog git file://. --since-commit HEAD~50 --only-verified --json > security/reports/trufflehog-verified.json
```

### detect-secrets — pre-commit hook setup

Prevents future commits from containing secrets. Install once per project.

```bash
# Install
pip install detect-secrets

# Initialize the baseline (audit current state — expected secrets are whitelisted here)
detect-secrets scan > .secrets.baseline

# Add to .pre-commit-config.yaml
```

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: .*/tests/.*
```

```bash
# Install the hook into the local git repo
pre-commit install

# Test it manually
pre-commit run detect-secrets --all-files
```

### Reviewing a gitleaks finding

When a finding is returned, record the following before taking any action:

```
File:      [path/to/file]
Commit:    [SHA]
Author:    [name <email>]
Date:      [ISO 8601]
Rule:      [e.g., "github-pat", "aws-access-key-id"]
Secret:    [first 4 chars]***[last 4 chars]  ← never log the full secret
```

Then STOP and ask the user: "This secret appears in commit [SHA]. Has it been rotated? If not, rotate it now before I propose history remediation steps."

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| Run `git log -p` and eyeball for secrets manually | Use `gitleaks` + `truffleHog` | Manual review misses high-entropy tokens and does not scale past a few commits |
| Only scan the working tree (`git status`) | Scan commit history with `HEAD~50..HEAD` | A deleted secret is still in history and can be extracted with `git show <SHA>` |
| Add `.env` to `.gitignore` after the fact and assume it is safe | Verify with `git ls-files --error-unmatch .env` that the file is not already tracked | `.gitignore` does not un-track already-committed files |
| Rewrite git history immediately upon finding a secret | Rotate the secret first, then propose history rewrite for user approval | Rewriting history before rotation leaves the live secret exposed during the window between rewrite and rotation |
| Whitelist a secret in `.secrets.baseline` without a comment | Add a comment explaining why it is a false positive | Whitelists without justification accumulate silently and hide real secrets |

---

## Verification Checklist

Before marking a secrets-scanning task as done, confirm:

- [ ] `.gitignore` contains all required sensitive file patterns listed above
- [ ] `gitleaks` scan returned zero findings on `HEAD~50..HEAD`
- [ ] `truffleHog` scan returned zero verified findings on `HEAD~50..HEAD`
- [ ] `detect-secrets` pre-commit hook is installed (`pre-commit run detect-secrets --all-files` passes)
- [ ] `security/reports/` is listed in `.gitignore` (reports themselves must not be committed)
- [ ] Any suppressed or whitelisted finding has a written justification in `.secrets.baseline` or inline comment
- [ ] If any secret was found: user has confirmed rotation before this checklist is signed off
