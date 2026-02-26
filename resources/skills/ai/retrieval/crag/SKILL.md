---
name: crag
description: Implements Corrective RAG (CRAG) for retrieval-augmented generation with relevance evaluation and web search fallback. Use when the user requests RAG with self-correction, document Q&A with fallback search, or explicitly mentions CRAG or Corrective RAG.
---

# CRAG (Corrective RAG)

## Core Philosophy
CRAG enhances standard RAG by adding a **relevance evaluation layer**. After retrieving documents, the system scores each chunk as "relevant" or "not relevant." If any chunk scores "no," the query is automatically refined by an LLM and sent to an external web search (Tavily) as a fallback. This self-correcting retrieval ensures answers are grounded in verified information rather than potentially irrelevant context.

## Trigger Scenarios
✅ **WHEN to use it:**
- Document Q&A where retrieval quality may be unreliable (PDFs, financial reports, unstructured text)
- Tasks where incorrect retrieval would cause hallucinated answers and web search can supplement
- Single-question, fact-based queries against a document corpus
- Workflows needing transparent intermediate outputs (relevancy scores, transformed queries, search results)

❌ **WHEN NOT to use it:**
- Multi-turn conversational agents (CRAG is single-query, stateless)
- Tasks requiring code generation, execution, or computation (use LangGraph or SmolAgents)
- Multi-agent collaborative workflows (use CrewAI or AutoGen)
- High-volume query pipelines (web search fallback adds latency per query)
- Questions requiring cross-document reasoning over many pages at once

## Pros vs Cons
- **Pros:** Self-correcting retrieval reduces hallucination risk, transparent pipeline (relevancy scores visible), web search fallback fills knowledge gaps, works with any LlamaIndex-compatible LLM, LlamaParse integration for high-quality PDF parsing
- **Cons:** One question at a time (multi-question prompts cause hallucinations), query quality is critical (missing keywords degrade search), Tavily API key required, slower than standard RAG due to evaluation + search steps, GPT-4 default in the pack is expensive

## Implementation Template
```python
# Input: "What is the change in net income from 2021 to 2022?"
# Expected Output: Extracted answer from document, with web search fallback if retrieval is irrelevant

import os
import nest_asyncio
nest_asyncio.apply()

from llama_parse import LlamaParse
from llama_index.core import SimpleDirectoryReader

os.environ["OPENAI_API_KEY"] = "your-openai-key"
LLAMAPARSE_API_KEY = "your-llamaparse-key"
TAVILY_API_KEY = "your-tavily-key"

parser = LlamaParse(
    api_key=LLAMAPARSE_API_KEY,
    result_type="markdown",
)

documents = SimpleDirectoryReader(
    input_files=["path/to/financial_report.pdf"],
    file_extractor={".pdf": parser},
).load_data()

from corrective_rag_pack.llama_index.packs.corrective_rag.base import CorrectiveRAGPack

corrective_rag = CorrectiveRAGPack(documents, TAVILY_API_KEY)

response = corrective_rag.run(
    "What is the change in net income from 2021 to 2022?",
    similarity_top_k=2,
)
print(response.response)
```

### Installation
```bash
pip install llama-index llama-index-tools-tavily-research llama-parse
llamaindex-cli download-llamapack CorrectiveRAGPack --download-dir ./corrective_rag_pack
```

### Inspecting Intermediate Results
The CRAG pipeline exposes these intermediate variables:
- `relevancy_results`: Binary scores ("yes"/"no") for each retrieved document
- `relevant_text`: Only documents scored "yes"
- `transformed_query_str`: LLM-refined query for web search
- `search_text`: Results from Tavily web search

## Common Pitfalls
- **One question at a time**: Multi-question prompts (e.g., "What is X? What is Y? What is the difference?") cause hallucinations. Always decompose into separate `corrective_rag.run()` calls.
- **Include entity names in queries**: "What was the net income in 2019?" gets refined to just "2019 net income" which returns irrelevant web results. Use "What was the net income in 2019 of JPMorgan Chase?" instead.
- **GPT-4 default is expensive**: The `CorrectiveRAGPack` defaults to GPT-4 for relevance evaluation. Modify the pack source to use GPT-3.5-turbo for cost savings.
- **LlamaParse without GPT-4o**: Charts and complex tables in PDFs may not parse correctly without `gpt4o_mode=True` in LlamaParse. This is by design to test CRAG's web fallback, but in production enable it.
- **`similarity_top_k` tuning**: Too low (1) risks missing relevant chunks; too high (10+) increases evaluation cost. Start with `similarity_top_k=2`.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Relevancy evaluator scoring all documents as "no" (indicates poor chunking or query quality)
- Tavily web search returning no results for the transformed query
- Multi-question prompts producing hallucinated answers not grounded in any source
