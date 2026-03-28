---
name: prd
description: "Generate a Product Requirements Document for any feature, page, application, or integration. Use when planning a feature, starting a new module, or when asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
user-invocable: true
---

# PRD Generator

Create detailed Product Requirements Documents for any feature, page, application, or integration. PRDs must be clear, actionable, and suitable for implementation by AI agents or developers working in Cursor.

---

## The Job

1. **Detect the active technology stack** by inspecting `requirements.txt`, `package.json`, and `docker-compose.yml` at runtime. Use stack-specific terminology in all user stories and acceptance criteria.
2. **Read `Context/tasks/todo.md`** to understand what has already been built.
3. **Run Phase 0** — collect the Feature Brief from the user.
4. **Run Phase 1** — ask 3–6 adaptive clarifying questions using the six fixed categories, with options generated from the brief.
5. Generate a structured PRD based on answers.
6. Save to `Context/tasks/prd-[feature-name].md`.

**Important:** Do NOT start implementing. Just create the PRD.

---

## Phase 0: Feature Brief

Before asking any clarifying questions, prompt the user with exactly this:

> **Before we begin, describe in 2–3 sentences what you want to build.** Include:
> - The type of deliverable (feature, web page, API endpoint, full application, pipeline, integration, etc.)
> - The core problem it solves
> - Who uses it
>
> *Example: "A Stripe checkout integration for our SaaS app. Users should be able to subscribe to monthly or annual plans and manage their billing. Target user is our existing free-tier customers."*

**STOP AND WAIT** for the user's brief before proceeding to Phase 1.

Read the brief carefully. Use it to:
- Classify the type of work (UI feature, backend service, integration, data pipeline, etc.)
- Identify the likely data sources and user roles
- Generate relevant, specific options for the Phase 1 questions

---

## Phase 1: Clarifying Questions

Ask only the questions where the brief left something ambiguous. Use these **six fixed categories** in order. Generate the lettered options dynamically based on the brief — do not use hardcoded, domain-specific options.

The six categories are:

- **Problem/Goal:** What problem does this solve for the user?
- **Data Source:** What data or inputs does this feature consume or produce?
- **Core Functionality:** What are the key actions the user performs?
- **Scope/Boundaries:** What should this feature explicitly NOT do in this iteration?
- **Target User:** Who is the primary user?
- **Success Criteria:** What does "done" look like? How do we know it works?

### Format Questions Like This

```
1. What is the primary goal of this feature?
   A. [Option derived from the brief]
   B. [Option derived from the brief]
   C. [Option derived from the brief]
   D. Other: [please specify]

2. What data or inputs does this feature consume?
   A. [Option derived from the brief]
   B. [Option derived from the brief]
   C. [Option derived from the brief]
   D. Other: [please specify]

3. What are the key actions the user performs?
   A. [Option derived from the brief]
   B. [Option derived from the brief]
   C. [Option derived from the brief]
   D. Other: [please specify]

4. What should this feature NOT do in this iteration?
   A. [Option derived from the brief]
   B. [Option derived from the brief]
   C. [Option derived from the brief]
   D. Other: [please specify]

5. Who is the primary user?
   A. [Option derived from the brief]
   B. [Option derived from the brief]
   C. [Option derived from the brief]
   D. Other: [please specify]

6. What does "done" look like?
   A. [Option derived from the brief]
   B. [Option derived from the brief]
   C. [Option derived from the brief]
   D. Other: [please specify]
```

This lets users respond with `1B, 2A, 3C, 4B, 5A, 6C` for quick iteration. Always indent options.

**STOP AND WAIT** for the user's answers before writing the PRD.

---

## Step 2: PRD Structure

Generate the PRD with these sections:

### 1. Introduction / Overview
Brief description of the feature and the problem it solves. State the context clearly — who is affected, what the current pain point is, and why this feature addresses it.

### 2. Goals
Specific, measurable objectives (bullet list). Frame goals in terms of user outcomes and system behavior:
- "User can complete checkout in under 60 seconds"
- "API responds in under 200ms for 95% of requests"

### 3. User Stories

Each story needs:
- **Title:** Short descriptive name
- **Description:** "As a [role], I want [feature] so that [benefit]"
- **Acceptance Criteria:** Verifiable checklist of what "done" means

Each story should be small enough to implement in one focused Cursor Agent session.

**Format:**
```markdown
### US-001: [Title]
**Description:** As a [role], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Linter and type checker pass
- [ ] Tests pass
```

**Important:** Acceptance criteria must be verifiable, not vague. "Works correctly" is bad. "Returns HTTP 201 with the created resource ID when given valid input" is good.

### 4. Functional Requirements
Numbered list of specific functionalities. Be explicit and unambiguous. Use the correct technical terminology for the detected stack.

- "FR-1: The system must…"
- "FR-2: When a user does X, the system must…"

### 5. Non-Goals (Out of Scope)
What this feature will NOT include in this iteration. Critical for managing scope.

### 6. Constraints & Dependencies
Only include items that apply to this feature:
- External API rate limits or quotas
- Compliance or regulatory requirements
- Authentication or permission dependencies
- Data storage or retention policies
- Third-party service availability

### 7. Technical Considerations
- **Tech Stack:** Reference the stack detected at runtime from `requirements.txt` / `package.json`
- Known constraints or dependencies (API keys, environment variables)
- Integration points with existing modules
- Performance requirements (latency, throughput, concurrency)
- Error handling patterns

### 8. Success Metrics
How will success be measured? Use concrete, observable indicators:
- "Checkout conversion rate matches or exceeds baseline"
- "Feature passes all acceptance criteria with zero critical bugs"
- "Response time under load stays below 500ms at p99"

### 9. Open Questions
Remaining questions or areas needing clarification before or during implementation.

---

## Writing for AI Agents

The PRD reader may be an AI agent in Cursor or a developer. Therefore:

- Be explicit and unambiguous — never rely on implied knowledge
- Use correct technical terminology for the detected stack
- Provide enough detail to understand purpose and core logic without over-specifying implementation
- Number requirements for easy reference (`FR-1`, `US-001`)
- Use concrete examples where helpful (real endpoints, field names, example values)
- Mention specific file paths, module names, or function signatures when known
- Distinguish between required behavior and optional enhancements

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `Context/tasks/`
- **Filename:** `prd-[feature-name].md` (kebab-case)

---

## Example PRD

```markdown
# PRD: Stripe Subscription Checkout

## Introduction

Free-tier users currently have no way to upgrade to a paid plan from within the app — they must contact sales. This feature adds a self-serve Stripe checkout flow that lets users subscribe to monthly or annual plans directly, reducing time-to-upgrade and removing a manual step from the sales process.

## Goals

- Users can subscribe to a paid plan in under 60 seconds with no sales involvement
- Webhook handler correctly provisions access within 5 seconds of payment confirmation
- Subscription status is reflected in the UI immediately after checkout completes

## User Stories

### US-001: Initiate checkout
**Description:** As a free-tier user, I want to click "Upgrade" and be taken to a Stripe-hosted checkout page so that I can subscribe without leaving a trusted payment interface.

**Acceptance Criteria:**
- [ ] Clicking "Upgrade" creates a Stripe Checkout Session via the backend API
- [ ] User is redirected to the Stripe-hosted checkout URL
- [ ] Session includes the correct `price_id` for the selected plan
- [ ] `mypy --strict` passes
- [ ] `pytest` tests pass

### US-002: Provision access after payment
**Description:** As a newly subscribed user, I want my account to be upgraded automatically after payment so that I can access paid features immediately.

**Acceptance Criteria:**
- [ ] Stripe `checkout.session.completed` webhook is verified cryptographically before processing
- [ ] User's plan is updated in the database within 5 seconds of the event
- [ ] Webhook handler is idempotent — duplicate events do not create duplicate records
- [ ] `pytest` tests pass

## Functional Requirements

- FR-1: Expose `POST /api/v1/subscriptions/checkout` that creates a Stripe Checkout Session and returns the session URL
- FR-2: Accept `plan` parameter (`monthly` | `annual`) and map it to the correct Stripe `price_id` from environment config
- FR-3: Implement `POST /api/v1/webhooks/stripe` that verifies the `Stripe-Signature` header and handles `checkout.session.completed`
- FR-4: On successful payment, update the user's `plan` field to `pro` and set `subscription_id` in the database

## Non-Goals

- No custom card input UI (Stripe-hosted checkout only)
- No invoice or billing history UI in this iteration
- No multi-seat or team plan support

## Constraints & Dependencies

- Stripe secret key and webhook signing secret must be set as environment variables (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`)
- Webhook endpoint must respond within 5 seconds — offload database writes to a background task
- Stripe Checkout Sessions expire after 24 hours

## Technical Considerations

- Backend: FastAPI — create a new router at `server/routers/subscriptions.py`
- Use `stripe.checkout.Session.create()` with `mode="subscription"`
- Load `price_id` values from environment config, not hardcoded
- Webhook raw body must be read before any JSON parsing for signature verification

## Success Metrics

- Free-to-paid conversion completes end-to-end in a local test environment
- Webhook handler passes duplicate-event test (same event delivered twice → one DB update)
- No Stripe API keys appear in source code or logs

## Open Questions

- Should we support annual-only, monthly-only, or let the user choose on the upgrade page?
- Do we need a post-checkout success page or just redirect back to the dashboard?
```

---

## Checklist

Before saving the PRD:

- [ ] Phase 0 brief was collected and informed the question options
- [ ] Phase 1 questions used all six categories
- [ ] User's answers are incorporated throughout
- [ ] User stories are small and specific (one Cursor session each)
- [ ] Functional requirements are numbered and unambiguous
- [ ] Non-goals section defines clear boundaries
- [ ] Constraints & Dependencies section covers only what applies
- [ ] Acceptance criteria are verifiable, not vague
- [ ] Saved to `Context/tasks/prd-[feature-name].md`

---

## Appendix: Financial Research Domain

When building features for the SEC filings / financial research pipeline, supplement the standard question options with:

**Data Source options:**
- 10-Q only (quarterly), 10-K only (annual), Full reporting year (10-Q + 10-K), Include 8-K (material events)

**Known stack for this domain:**

| Layer | Technology |
|---|---|
| Language | Python 3.10+ |
| Data Source | SEC EDGAR via `edgartools` |
| Text Processing | LangChain `RecursiveCharacterTextSplitter` |
| Vector Database | ChromaDB (`PersistentClient`) |
| Embeddings | Google `embedding-001` via `langchain-google-genai` |
| LLM | Google Gemini 1.5 Flash via `langchain-google-genai` |
| Type Checking | `mypy` (strict mode) |
| Testing | `pytest` |

**Additional acceptance criterion for any story involving financial data:**
- [ ] Data accuracy verified against source filing

**Additional constraints to include:**
- SEC EDGAR rate limit: 10 requests/second — implement backoff for multi-ticker fetches
- All generated output should include: "Based on SEC filings. Not investment advice."
