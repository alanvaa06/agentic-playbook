# Vector Databases

**Domain:** Database
**Loaded when:** `pgvector`, `pinecone-client`, `pinecone`, `chromadb`, `qdrant-client`, or `weaviate-client` detected in `requirements.txt` or `package.json`

---

## When to Use

- Setting up a vector column in Postgres with `pgvector`.
- Initializing or querying a Pinecone index, Chroma collection, or Qdrant collection.
- Implementing semantic search, RAG retrieval, or recommendation systems.
- Debugging incorrect similarity search results.

## When NOT to Use

- The task involves only relational schema changes with no vector columns — load `sql_postgres.md` instead.
- The task involves keyword (full-text) search only — use Postgres `tsvector` / `GIN` indexes instead.

---

## Dimension Reference Table

**Always look up the exact dimension here before defining any vector column or collection.**
Never assume or guess — a dimension mismatch causes silent data corruption (embeddings stored truncated or rejected entirely).

### Google Gemini (Preferred)

| Model                       | Dimensions | Notes                                              |
|-----------------------------|------------|----------------------------------------------------|
| `text-embedding-004`        | 768        | Default; supports Matryoshka truncation to 256     |
| `text-embedding-004` (256)  | 256        | Truncated via `output_dimensionality=256`          |
| `text-multilingual-embedding-002` | 768  | Multilingual; same dimension as `text-embedding-004` |
| `embedding-001` (legacy)    | 768        | Legacy model; prefer `text-embedding-004`          |

> **Distance metric for Gemini:** Use **Cosine Similarity** — Gemini embeddings are normalized.

### Anthropic / Voyage AI (Preferred)

Anthropic's recommended embedding partner is **Voyage AI**. Use `voyageai` Python client or `@voyageai/client` for Node.

| Model                 | Dimensions | Context Window | Notes                                     |
|-----------------------|------------|----------------|-------------------------------------------|
| `voyage-3`            | 1024       | 32k tokens     | General-purpose; best quality             |
| `voyage-3-lite`       | 512        | 32k tokens     | Faster and cheaper; good for bulk indexing|
| `voyage-3-large`      | 1024       | 32k tokens     | Highest quality for retrieval             |
| `voyage-code-2`       | 1536       | 16k tokens     | Optimized for code retrieval              |
| `voyage-finance-2`    | 1024       | 32k tokens     | Optimized for financial documents         |
| `voyage-law-2`        | 1024       | 32k tokens     | Optimized for legal documents             |

> **Distance metric for Voyage:** Use **Cosine Similarity** — Voyage embeddings are normalized.

### OpenAI (Reference)

| Model                         | Dimensions | Notes                                           |
|-------------------------------|------------|-------------------------------------------------|
| `text-embedding-3-small`      | 1536       | Supports Matryoshka truncation                  |
| `text-embedding-3-large`      | 3072       | Supports Matryoshka truncation to 256–3072      |
| `text-embedding-ada-002`      | 1536       | Legacy; prefer `text-embedding-3-small`         |

> **Distance metric for OpenAI:** Use **Cosine Similarity** — OpenAI embeddings are normalized.

### Open Source / Local (HuggingFace)

| Model                          | Dimensions | Notes                                         |
|--------------------------------|------------|-----------------------------------------------|
| `all-MiniLM-L6-v2`             | 384        | Fast, small; good for dev/testing             |
| `all-mpnet-base-v2`            | 768        | Higher quality than MiniLM                    |
| `nomic-embed-text-v1.5`        | 768        | Open source; competitive with commercial models|
| `mxbai-embed-large-v1`         | 1024       | State-of-the-art open source (2024)           |
| `bge-large-en-v1.5`            | 1024       | Strong retrieval benchmark performance        |

> **Distance metric for HuggingFace:** Varies — check whether the model outputs normalized embeddings. If unsure, use **Cosine Similarity**.

---

## Core Rules

1. **Always verify dimensions before creating a column or collection.** Look up the exact dimension in the Dimension Reference Table above. Do not guess or carry over a dimension from a prior project.
2. **Never mix embeddings from different models in the same column or collection.** If the embedding model changes, create a new column and re-embed. Tag each row with the model name and version in a metadata column.
3. **Always create an approximate index (`HNSW` or `IVFFlat`) on production pgvector columns.** A column with no index defaults to exact KNN — a full sequential scan that becomes unusable beyond ~100k rows.
4. **Choose the distance operator that matches the model's output.** Normalized embeddings (Gemini, Voyage, OpenAI) use `<=>` (Cosine). Unnormalized embeddings may perform better with `<->` (L2/Euclidean).
5. **For Pinecone and Chroma, explicitly set the metric at collection/index creation time.** It cannot be changed after creation without deleting and recreating the index.
6. **Paginate large vector uploads.** Never upsert more than 100 vectors per Pinecone or Chroma batch call — large payloads cause timeouts and silent failures.
7. **Store embedding metadata alongside vectors.** Always include `document_id`, `chunk_index`, `model`, and `created_at` in the metadata payload so results can be traced back to source documents.
8. **For RAG applications, chunk text before embedding.** Never embed documents longer than the model's context window. Use `chunk_size=512` tokens with `chunk_overlap=64` as a safe default.

---

## Code Patterns

### pgvector — Table and Index Setup

Create the extension, define the column with the correct dimension, and add an HNSW index immediately.

```sql
-- Enable the extension (run once per database)
CREATE EXTENSION IF NOT EXISTS vector;

-- Example: Gemini text-embedding-004 (768 dims), Voyage voyage-3 (1024 dims)
CREATE TABLE document_chunks (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content     TEXT NOT NULL,
    embedding   VECTOR(768),          -- match your model's dimension exactly
    model       TEXT NOT NULL,        -- e.g., 'gemini/text-embedding-004'
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- HNSW index for approximate nearest neighbor (ANN) search
-- Use for read-heavy workloads; faster queries, slower inserts
CREATE INDEX ON document_chunks USING hnsw (embedding vector_cosine_ops);

-- IVFFlat index — alternative for write-heavy workloads
-- lists = sqrt(total_rows) is a good starting value
-- CREATE INDEX ON document_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

### pgvector — Similarity Search (Python / asyncpg)

```python
import asyncpg
from server.config import settings

async def semantic_search(
    pool: asyncpg.Pool,
    query_embedding: list[float],
    limit: int = 5,
    min_score: float = 0.75,
) -> list[dict]:
    rows = await pool.fetch(
        """
        SELECT
            id,
            document_id,
            chunk_index,
            content,
            1 - (embedding <=> $1::vector) AS score
        FROM document_chunks
        WHERE 1 - (embedding <=> $1::vector) >= $2
        ORDER BY embedding <=> $1::vector
        LIMIT $3
        """,
        query_embedding,
        min_score,
        limit,
    )
    return [dict(row) for row in rows]
```

### Gemini Embedding (Python)

```python
import google.generativeai as genai
from server.config import settings

genai.configure(api_key=settings.GEMINI_API_KEY)

GEMINI_EMBEDDING_MODEL = "models/text-embedding-004"
GEMINI_EMBEDDING_DIMS = 768  # hard-coded constant — never derive at runtime

def embed_text(text: str) -> list[float]:
    result = genai.embed_content(
        model=GEMINI_EMBEDDING_MODEL,
        content=text,
        task_type="retrieval_document",
    )
    embedding = result["embedding"]
    assert len(embedding) == GEMINI_EMBEDDING_DIMS, (
        f"Dimension mismatch: expected {GEMINI_EMBEDDING_DIMS}, got {len(embedding)}"
    )
    return embedding
```

### Voyage AI Embedding (Python, for Anthropic ecosystem)

```python
import voyageai
from server.config import settings

voyage = voyageai.Client(api_key=settings.VOYAGE_API_KEY)

VOYAGE_MODEL = "voyage-3"
VOYAGE_DIMS = 1024  # hard-coded constant — never derive at runtime

def embed_texts(texts: list[str]) -> list[list[float]]:
    result = voyage.embed(texts, model=VOYAGE_MODEL, input_type="document")
    embeddings = result.embeddings
    for emb in embeddings:
        assert len(emb) == VOYAGE_DIMS, (
            f"Dimension mismatch: expected {VOYAGE_DIMS}, got {len(emb)}"
        )
    return embeddings
```

### Pinecone — Index Setup and Upsert (Python)

```python
from pinecone import Pinecone, ServerlessSpec
from server.config import settings

PINECONE_INDEX = "my-index"
PINECONE_DIMS = 1024   # set to match your embedding model
PINECONE_METRIC = "cosine"  # must match embedding model normalization

pc = Pinecone(api_key=settings.PINECONE_API_KEY)

def get_or_create_index() -> None:
    if PINECONE_INDEX not in pc.list_indexes().names():
        pc.create_index(
            name=PINECONE_INDEX,
            dimension=PINECONE_DIMS,
            metric=PINECONE_METRIC,
            spec=ServerlessSpec(cloud="aws", region="us-east-1"),
        )

def upsert_vectors(vectors: list[tuple[str, list[float], dict]]) -> None:
    index = pc.Index(PINECONE_INDEX)
    # Upload in batches of 100 — never exceed this
    batch_size = 100
    for i in range(0, len(vectors), batch_size):
        batch = vectors[i : i + batch_size]
        index.upsert(
            vectors=[
                {"id": vid, "values": emb, "metadata": meta}
                for vid, emb, meta in batch
            ]
        )
```

### Chroma — Collection Setup and Query (Python)

```python
import chromadb
from chromadb.config import Settings

CHROMA_COLLECTION = "document_chunks"
CHROMA_DIMS = 768   # set to match your embedding model
CHROMA_METRIC = "cosine"  # cannot be changed after creation

client = chromadb.PersistentClient(path="./chroma_db")

def get_or_create_collection() -> chromadb.Collection:
    return client.get_or_create_collection(
        name=CHROMA_COLLECTION,
        metadata={"hnsw:space": CHROMA_METRIC},
    )

def query_collection(
    collection: chromadb.Collection,
    query_embedding: list[float],
    n_results: int = 5,
) -> list[dict]:
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        include=["documents", "metadatas", "distances"],
    )
    return [
        {
            "document": doc,
            "metadata": meta,
            "score": 1 - dist,  # convert distance to similarity score
        }
        for doc, meta, dist in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0],
        )
    ]
```

---

## Anti-Patterns

| Do NOT do this | Do this instead | Why |
|----------------|-----------------|-----|
| `VECTOR(1536)` for a Gemini model | `VECTOR(768)` | Gemini `text-embedding-004` outputs 768 dims; a 1536 column stores zeros or rejects inserts |
| `VECTOR(1024)` for Voyage `voyage-3-lite` | `VECTOR(512)` | `voyage-3-lite` outputs 512 dims; a 1024 column silently pads or truncates |
| No index on a vector column | Add `HNSW` or `IVFFlat` index | Defaults to exact KNN — full sequential scan unusable beyond ~100k rows |
| Using `<->` (L2) with normalized embeddings | Use `<=>` (cosine) | L2 and cosine are equivalent only when vectors are unit-normalized; mixing them gives wrong ranking |
| Mixing embeddings from different models in one column | Create separate columns or collections; tag metadata with `model` | Different models use different semantic spaces; combining them produces nonsense results |
| `pc.index.upsert(vectors=all_10k_vectors)` | Batch in groups of 100 | Pinecone and Chroma time out on large payloads; vectors silently fail to upload |
| Embedding raw document text (100k tokens) | Chunk first (`chunk_size=512`, `overlap=64`) | Models have fixed context windows; text beyond the limit is silently truncated |
| Hardcoding `api_key="sk-..."` | Load from `settings.GEMINI_API_KEY` or `settings.VOYAGE_API_KEY` | API keys in source code get committed to git and leak in logs |
| Using `metric="euclidean"` for Pinecone with Voyage/Gemini embeddings | Use `metric="cosine"` | Normalized embeddings rank identically with cosine; switching metric after index creation requires full re-indexing |

---

## Verification Checklist

Before marking a task as done, confirm:

- [ ] Vector column dimension matches the exact output dimension of the embedding model (verified against the Dimension Reference Table)
- [ ] An HNSW or IVFFlat index exists on every pgvector column used for similarity search
- [ ] The distance metric (`cosine`, `l2`, or `inner product`) is explicitly set and matches the model's normalization
- [ ] Embeddings are never mixed across models in the same column or collection
- [ ] Each record includes metadata: `document_id`, `chunk_index`, `model`, `created_at`
- [ ] Pinecone and Chroma upserts are batched at ≤ 100 vectors per call
- [ ] Text is chunked before embedding (no raw documents larger than the model's context window)
- [ ] API keys are loaded from environment variables — no hardcoded credentials
- [ ] Dimension assertion is present in the embedding function to catch mismatches at runtime
