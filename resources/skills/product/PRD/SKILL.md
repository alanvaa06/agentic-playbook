---
name: prd
description: "Generate a Product Requirements Document (PRD) for a new feature or research pipeline. Use when planning a feature, starting a new module, or when asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
user-invocable: true
---

# PRD Generator — Financial Research Edition

Create detailed Product Requirements Documents for financial research pipelines and investment analysis tools. PRDs must be clear, actionable, and suitable for implementation by AI agents or developers working in Cursor.

---

## The Job

1. **Read `resources/skills/ai/retrieval/financial-rag/SKILL.md`** to understand the current pipeline architecture
2. **Read `tasks/todo.md`** to understand what has already been built
3. Receive a feature or research pipeline description from the user
4. Ask 3-5 essential clarifying questions (with lettered options)
5. Generate a structured PRD based on answers, tailored to the project's tech stack
6. Save to `tasks/prd-[feature-name].md`

**Important:** Do NOT start implementing. Just create the PRD.

### Known Tech Stack

This project uses a fixed stack — do not ask about it unless the feature requires new technologies:

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

Use stack-specific terminology in all user stories and acceptance criteria (e.g., "ChromaDB collection" not "vector store", "edgartools Company object" not "data source").

---

## Step 1: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- **Problem/Goal:** What investment or research problem does this solve?
- **Data Source:** Which SEC filings or financial data are involved? (10-Q, 10-K, 8-K, proxy statements, etc.)
- **Core Functionality:** What are the key actions? (retrieve, analyze, compare, alert)
- **Scope/Boundaries:** What should it NOT do? (e.g., not a trading system, not real-time)
- **Target User:** Who consumes the output? (analyst, portfolio manager, compliance, demo audience)
- **Success Criteria:** How do we know it's done?

### Format Questions Like This:

```
1. What is the primary goal of this feature?
   A. Automate extraction of specific financial metrics from SEC filings
   B. Enable natural-language Q&A over company disclosures
   C. Compare financial data across multiple companies or periods
   D. Generate investment research reports or summaries
   E. Other: [please specify]

2. Which SEC filings should this cover?
   A. 10-Q only (quarterly)
   B. 10-K only (annual)
   C. Full reporting year (10-Q + 10-K)
   D. Include 8-K (material events) as well
   E. Other: [please specify]

3. Who is the primary consumer of the output?
   A. Investment analyst performing due diligence
   B. Portfolio manager making allocation decisions
   C. Team demo / proof of concept for stakeholders
   D. Automated downstream system (API consumer)
   E. Other: [please specify]

4. What is the scope for this iteration?
   A. Minimal viable version — single ticker, basic Q&A
   B. Multi-ticker comparison capability
   C. Full pipeline with error handling and persistence
   D. Production-ready with tests and monitoring
```

This lets users respond with "1B, 2C, 3C, 4A" for quick iteration. Remember to indent the options.

---

## Step 2: PRD Structure

Generate the PRD with these sections:

### 1. Introduction/Overview
Brief description of the feature and the investment research problem it solves. State the financial context clearly (e.g., "Analysts currently spend 3+ hours manually reading 10-K risk factor sections").

### 2. Goals
Specific, measurable objectives (bullet list). Frame goals in investment/research terms:
- "Enable an analyst to query a full year of AAPL filings in under 30 seconds"
- "Extract and compare operating margins across 3 quarters automatically"

### 3. User Stories
Each story needs:
- **Title:** Short descriptive name
- **Description:** "As a [financial analyst / portfolio manager / researcher], I want [feature] so that [investment benefit]"
- **Acceptance Criteria:** Verifiable checklist of what "done" means

Each story should be small enough to implement in one focused Cursor Agent session.

**Format:**
```markdown
### US-001: [Title]
**Description:** As a [role], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] `mypy --strict` passes
- [ ] `pytest` tests pass
- [ ] Data accuracy verified against source filing
```

**Important:**
- Acceptance criteria must be verifiable, not vague. "Returns correct data" is bad. "Returns revenue figure matching the 10-K Income Statement line item within rounding tolerance" is good.
- **For any story involving financial data:** Always include "Data accuracy verified against source filing" as acceptance criteria.

### 4. Functional Requirements
Numbered list of specific functionalities:
- "FR-1: The system must fetch the latest 10-K for a given ticker using `edgartools`"
- "FR-2: When a user queries 'What are the risk factors?', the system must retrieve relevant chunks from ChromaDB and return a grounded answer with filing references"

Be explicit and unambiguous. Use the correct financial and technical terminology.

### 5. Non-Goals (Out of Scope)
What this feature will NOT include. Critical for managing scope. Examples:
- "Not a trading signal generator"
- "No real-time market data integration"
- "No XBRL structured data parsing (text-based only)"

### 6. Data & Regulatory Considerations
- Which SEC filing types are in scope
- Data freshness requirements (how recent must filings be?)
- Any compliance or disclaimer requirements for generated output
- Rate-limiting constraints from SEC EDGAR (10 requests/second)
- Data storage and retention policies

### 7. Technical Considerations
- **Tech Stack:** Reference the Known Tech Stack table above
- Known constraints or dependencies (API keys, SEC identity headers)
- Integration points with existing pipeline modules
- Performance requirements (latency, throughput)
- ChromaDB collection schema and metadata fields
- Error handling patterns (retry logic, self-correction logging)

### 8. Success Metrics
How will success be measured? Frame in financial research terms:
- "Analyst can answer a question about a 10-K in under 30 seconds vs. 15 minutes manually"
- "Retrieved answer cites the correct filing section (MD&A, Risk Factors, etc.) 90%+ of the time"
- "Pipeline processes a full year of filings (3x 10-Q + 1x 10-K) in under 5 minutes"

### 9. Open Questions
Remaining questions or areas needing clarification.

---

## Writing for AI Agents

The PRD reader may be an AI agent in Cursor or a junior developer. Therefore:

- Be explicit and unambiguous
- Use correct financial terminology but explain domain-specific concepts (e.g., "MD&A — Management's Discussion and Analysis, the narrative section where management explains financial results")
- Provide enough detail to understand purpose and core logic
- Number requirements for easy reference
- Use concrete examples with real tickers (AAPL, MSFT, NVDA) where helpful
- Mention specific file paths, module names, or function signatures when known
- Distinguish between facts from filings and analytical inferences

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `tasks/`
- **Filename:** `prd-[feature-name].md` (kebab-case)

---

## Example PRD

```markdown
# PRD: Multi-Ticker Financial Comparison

## Introduction

Enable analysts to compare key financial metrics across multiple companies by querying their SEC filings simultaneously. Currently, comparing revenue growth between AAPL, MSFT, and GOOG requires opening three separate 10-K documents and manually locating the Income Statement in each. This feature automates that workflow.

## Goals

- Query up to 5 tickers' filings in a single request
- Extract and compare specific financial metrics (revenue, net income, operating margin)
- Return structured comparison with source citations from each filing
- Complete a 3-ticker comparison in under 60 seconds

## User Stories

### US-001: Ingest filings for multiple tickers
**Description:** As an analyst, I want to load 10-K and 10-Q filings for multiple companies so that I can compare them side by side.

**Acceptance Criteria:**
- [ ] Accept a list of up to 5 tickers as input
- [ ] Fetch and process filings for each ticker using `edgartools`
- [ ] Store all chunks in ChromaDB with ticker metadata for filtered retrieval
- [ ] `mypy --strict` passes
- [ ] `pytest` tests pass

### US-002: Cross-ticker financial query
**Description:** As a portfolio manager, I want to ask "Compare revenue growth for AAPL vs MSFT over the last year" and receive a structured answer.

**Acceptance Criteria:**
- [ ] Retrieves relevant chunks from each ticker's filings via ChromaDB metadata filter
- [ ] Passes multi-source context to Gemini 1.5 Flash with comparison prompt
- [ ] Response includes specific figures and filing source references
- [ ] Data accuracy verified against source filings
- [ ] `mypy --strict` passes
- [ ] `pytest` tests pass

## Functional Requirements

- FR-1: Accept a list of tickers and fetch the full reporting year (10-Q + 10-K) for each
- FR-2: Tag each chunk with ticker, form type, filing date, and period of report in ChromaDB
- FR-3: Support filtered retrieval by ticker when building RAG context
- FR-4: Format comparison responses as structured markdown tables when numeric data is involved

## Non-Goals

- No real-time stock price or market data
- No portfolio optimization or trading signals
- No XBRL structured data extraction (text-based retrieval only)

## Data & Regulatory Considerations

- SEC EDGAR rate limit: 10 requests/second — implement backoff for multi-ticker fetches
- All generated output should include a disclaimer: "Based on SEC filings. Not investment advice."
- Filing data stored locally in ChromaDB; no external data transmission

## Technical Considerations

- Reuse existing `acquisition.py` and `processing.py` modules
- ChromaDB metadata filter: `{"ticker": {"$in": ["AAPL", "MSFT"]}}`
- Gemini 1.5 Flash context window supports multi-document comparison
- Consider batch embedding to reduce API calls

## Success Metrics

- 3-ticker comparison completes in under 60 seconds
- Revenue/net income figures match source 10-K within rounding tolerance
- Analyst reports 80%+ reduction in time vs. manual comparison

## Open Questions

- Should we support custom date ranges or always use the most recent reporting year?
- How should conflicting fiscal year-ends be handled (e.g., AAPL Sep vs MSFT Jun)?
```

---

## Checklist

Before saving the PRD:

- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] User stories are small and specific
- [ ] Functional requirements are numbered and unambiguous
- [ ] Non-goals section defines clear boundaries
- [ ] Data & regulatory considerations addressed
- [ ] Financial terminology is precise and consistent
- [ ] Saved to `tasks/prd-[feature-name].md`
