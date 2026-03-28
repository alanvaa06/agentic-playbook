# Skill: Financial SEC Filings RAG Pipeline

Use this skill when the user asks you to build, run, or extend the SEC filings RAG pipeline. This pipeline covers the **full reporting year** — both **10-Q** (quarterly) and **10-K** (annual) filings — to provide complete financial context. Follow each step in order. If any step fails, log the error and resolution in `tasks/self-correction.md` before continuing.

---

## Prerequisites

Ensure the following environment is ready before starting:

- **Python 3.10+**
- **API Key:** `GOOGLE_API_KEY` must be set as an environment variable (never hard-code it).
- **SEC Identity:** `edgartools` requires a user-agent identity for SEC EDGAR requests. Set it via `edgar.set_identity("Your Name your@email.com")`.

## Step 1 — Data Acquisition

Use the `edgartools` library to fetch both **10-Q** and **10-K** filings for a given ticker, covering the full reporting year (three quarterly 10-Qs plus one annual 10-K).

```python
from edgar import Company

company = Company(ticker)

# Fetch quarterly filings (10-Q)
quarterly_filings = company.get_filings(form="10-Q")
recent_10qs = quarterly_filings.latest(3)  # Up to 3 quarters

# Fetch annual filing (10-K)
annual_filings = company.get_filings(form="10-K")
latest_10k = annual_filings.latest(1)

all_filings = list(recent_10qs) + list(latest_10k)
```

- Iterate over `all_filings` and extract the full document text from each filing object.
- Tag each document with its form type (`10-Q` or `10-K`) and period of report for downstream metadata.
- If `edgartools` returns HTML/XML, strip tags to produce clean plain text.
- Handle rate-limiting gracefully: if you get a 429 response, wait and retry with exponential backoff.
- Be mindful of the 10-K's larger size — it contains the full annual audited financials, MD&A, risk factors, and notes that overlap with but expand upon the 10-Q content.

## Step 2 — Text Processing

Clean the extracted text:

1. Remove residual HTML tags, XBRL artifacts, and boilerplate headers/footers.
2. Normalize whitespace (collapse multiple newlines, strip leading/trailing spaces).
3. Validate that the resulting text is non-empty and contains meaningful content.

## Step 3 — Chunking

Split the clean text using LangChain's `RecursiveCharacterTextSplitter`:

```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    separators=["\n\n", "\n", ". ", " ", ""],
)
chunks = splitter.split_text(clean_text)
```

- Verify that no chunk is empty after splitting.
- Log the total number of chunks for debugging.

## Step 4 — Vector Database

Initialize a local ChromaDB instance and create (or get) a collection:

```python
import chromadb

client = chromadb.PersistentClient(path="./chroma_db")
collection = client.get_or_create_collection(
    name="sec_filings",
    metadata={"hnsw:space": "cosine"},
)
```

- Use `PersistentClient` so that embeddings survive across sessions.
- Store chunk metadata alongside each document: **ticker**, **form type** (`10-Q` or `10-K`), **filing date**, **period of report**, and **chunk index**.
- This metadata enables filtered retrieval (e.g., query only 10-K filings, or only a specific quarter).

## Step 5 — Embeddings & LLM (Gemini 1.5 Flash)

Use Google's Gemini 1.5 Flash via `langchain-google-genai` for both embedding generation and question answering. This model minimizes cost while delivering strong performance.

### Embedding

```python
from langchain_google_genai import GoogleGenerativeAIEmbeddings

embeddings = GoogleGenerativeAIEmbeddings(
    model="models/embedding-001",
    google_api_key=os.environ["GOOGLE_API_KEY"],
)
```

Embed all chunks and upsert them into the ChromaDB collection.

### LLM for RAG Queries

```python
from langchain_google_genai import ChatGoogleGenerativeAI

llm = ChatGoogleGenerativeAI(
    model="gemini-1.5-flash",
    google_api_key=os.environ["GOOGLE_API_KEY"],
    temperature=0.2,
)
```

Build a retrieval chain that:
1. Takes a user question.
2. Retrieves the top-k most relevant chunks from ChromaDB.
3. Passes them as context to Gemini 1.5 Flash.
4. Returns a grounded answer with source references.

## Step 6 — Self-Correction Mandate

Throughout every step above, if you encounter any of the following, **immediately** append an entry to `tasks/self-correction.md`:

| Trigger | Example |
|---|---|
| Missing dependency | `ModuleNotFoundError: No module named 'edgar'` |
| Missing or invalid API key | `google.api_core.exceptions.PermissionDenied` |
| SEC rate limiting | HTTP 429 from EDGAR |
| Empty or malformed document | Parsed text is blank after stripping |
| ChromaDB schema conflict | Collection already exists with different metadata |
| Any unexpected exception | Unhandled tracebacks |

Use the entry format defined in `tasks/self-correction.md`. Then fix the issue and continue.
