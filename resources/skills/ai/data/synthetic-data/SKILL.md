---
name: synthetic-data-generation
description: Implements framework-adaptive synthetic data generation for RAG evaluation and embedding fine-tuning. Use when the user requests synthetic Q&A dataset creation, RAG evaluation data, embedding training pairs, or explicitly mentions synthetic data generation. Adapts to LlamaIndex or LangChain based on the project's existing orchestrator.
---

# Synthetic Data Generation (Framework-Adaptive)

## Core Philosophy
Instead of manually labeling evaluation datasets for RAG systems, use a cheap LLM to **reverse-engineer questions from document chunks**. The technique is framework-agnostic: chunk text, pass each chunk to an LLM, parse the output. This skill adapts the implementation to match whichever orchestrator (LlamaIndex or LangChain) is already present in the user's project.

## Framework Detection
Before generating code, **check the user's current project context**:
1. Look at the open file's imports and the project's `requirements.txt` or `pyproject.toml`.
2. If the project uses `llama_index` or `llama-index` → use **Pattern A (LlamaIndex)**.
3. If the project uses `langchain` or `langchain_*` → use **Pattern B (LangChain)**.
4. If neither is present or the user has no preference → default to **Pattern C (Pure Python)** with no orchestrator dependency.

## Trigger Scenarios
✅ **WHEN to use it:**
- Building evaluation datasets for RAG pipeline retrieval accuracy
- Preparing training pairs `(query, context)` for fine-tuning embedding models on a specific domain
- Converting large unstructured documents (10-Ks, PDFs, reports) into realistic user questions for testing
- When manual question labeling is too slow or expensive

❌ **WHEN NOT to use it:**
- Generating runtime answers to user questions (this is for *dataset creation*, not inference)
- When source documents contain highly sensitive PII that cannot be sent to an external LLM
- When you need adversarial or edge-case questions (LLM-generated questions tend to be well-formed and predictable)
- When you need human-validated ground truth (synthetic questions lack real user phrasing diversity)

## Pros vs Cons
- **Pros:** Extremely cost-effective (~$0.005 for 350+ questions using Gemini 2.5 Flash), infinitely scalable, removes human bias from question formulation, framework-adaptive (works with LlamaIndex, LangChain, or pure Python), pairs questions with source chunk IDs automatically
- **Cons:** Generated questions may be too closely aligned to chunk vocabulary (lacking messy real-user phrasing), requires regex post-processing to clean LLM formatting, quality depends on chunk size and prompt design

## Shared Prompt Template
This prompt is used identically across all patterns:

```python
PROMPT_TEMPLATE = """\
Context information is below.

---------------------
{context_str}
---------------------

Given the context information and no prior knowledge,
generate only questions based on the below query.

You are a domain expert.
Your task is to create {num_questions} questions based on the provided context.
The questions should be diverse in nature across the document.
The questions should reference specific data points, metrics, or concepts from the context.
Restrict the questions to the context information provided.
"""
```

## Shared Output Parser
This parsing logic is used identically across all patterns:

```python
import re
import uuid

def parse_questions(response_text: str) -> list[str]:
    """Clean numbered-list formatting from LLM output and return question strings."""
    raw = response_text.strip().split("\n")
    cleaned = [re.sub(r"^\d+[).\s]", "", q).strip() for q in raw]
    return [q for q in cleaned if len(q) > 0]

def collect_questions(questions: list[str], node_id: str, queries: dict, relevant_context: dict):
    """Assign UUIDs and store question-to-chunk mappings."""
    for question in questions:
        qid = str(uuid.uuid4())
        queries[qid] = question
        relevant_context[qid] = [node_id]
```

## Implementation Templates

### Pattern A: LlamaIndex
Use when the project already imports `llama_index`.

```python
# Input: A PDF or text file
# Expected Output: Two dicts — queries{id: text} and relevant_context{id: [node_id]}

import json
from tqdm import tqdm
from llama_index.core import SimpleDirectoryReader
from llama_index.core.node_parser import SimpleNodeParser
from llama_index.llms.gemini import Gemini

documents = SimpleDirectoryReader(input_files=["path/to/report.pdf"]).load_data()
parser = SimpleNodeParser()
nodes = parser.get_nodes_from_documents(documents)
corpus = {node.node_id: node.text for node in nodes}

llm = Gemini(model="models/gemini-2.5-flash", api_key=GOOGLE_API_KEY)

queries, relevant_context = {}, {}
for node_id, text in tqdm(corpus.items()):
    prompt = PROMPT_TEMPLATE.format(context_str=text, num_questions=3)
    response = llm.complete(prompt)
    questions = parse_questions(str(response))
    collect_questions(questions, node_id, queries, relevant_context)

with open("synthetic_qa_dataset.json", "w") as f:
    json.dump({"queries": queries, "relevant_context": relevant_context}, f, indent=2)
```

### Pattern B: LangChain
Use when the project already imports `langchain`.

```python
# Input: A PDF or text file
# Expected Output: Two dicts — queries{id: text} and relevant_context{id: [node_id]}

import json
from tqdm import tqdm
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate

loader = PyPDFLoader("path/to/report.pdf")
docs = loader.load()
splitter = RecursiveCharacterTextSplitter(chunk_size=1024, chunk_overlap=100)
splits = splitter.split_documents(docs)

llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", google_api_key=GOOGLE_API_KEY)
prompt = PromptTemplate.from_template(PROMPT_TEMPLATE)
chain = prompt | llm

queries, relevant_context = {}, {}
for i, split in enumerate(tqdm(splits)):
    node_id = f"chunk_{i}"
    response = chain.invoke({"context_str": split.page_content, "num_questions": 3})
    questions = parse_questions(response.content)
    collect_questions(questions, node_id, queries, relevant_context)

with open("synthetic_qa_dataset.json", "w") as f:
    json.dump({"queries": queries, "relevant_context": relevant_context}, f, indent=2)
```

### Pattern C: Pure Python (No Orchestrator)
Use when no orchestrator is present, or the user wants minimal dependencies.

```python
# Input: A plain text or markdown file
# Expected Output: Two dicts — queries{id: text} and relevant_context{id: [node_id]}

import json
from tqdm import tqdm
import google.generativeai as genai

genai.configure(api_key=GOOGLE_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

with open("path/to/report.txt", "r") as f:
    full_text = f.read()

chunk_size = 3000
chunks = [full_text[i:i + chunk_size] for i in range(0, len(full_text), chunk_size)]

queries, relevant_context = {}, {}
for i, chunk in enumerate(tqdm(chunks)):
    node_id = f"chunk_{i}"
    prompt = PROMPT_TEMPLATE.format(context_str=chunk, num_questions=3)
    response = model.generate_content(prompt)
    questions = parse_questions(response.text)
    collect_questions(questions, node_id, queries, relevant_context)

with open("synthetic_qa_dataset.json", "w") as f:
    json.dump({"queries": queries, "relevant_context": relevant_context}, f, indent=2)
```

### Swapping the LLM Provider
The patterns above default to Gemini 2.5 Flash. To use a different LLM, replace only the LLM initialization line:

| Provider | LlamaIndex | LangChain | Pure Python |
|----------|-----------|-----------|-------------|
| **Gemini 2.5 Flash** | `Gemini(model="models/gemini-2.5-flash")` | `ChatGoogleGenerativeAI(model="gemini-2.5-flash")` | `genai.GenerativeModel("gemini-2.5-flash")` |
| **OpenAI GPT-4o-mini** | `OpenAI(model="gpt-4o-mini")` | `ChatOpenAI(model="gpt-4o-mini")` | `openai.chat.completions.create(model="gpt-4o-mini")` |
| **Anthropic Claude** | `Anthropic(model="claude-3-5-sonnet")` | `ChatAnthropic(model="claude-3-5-sonnet")` | `anthropic.messages.create(model="claude-3-5-sonnet")` |

## Common Pitfalls
- **LLM numbered list formatting**: LLMs prefix generated questions with "1.", "2)", "3 -", etc. The shared `parse_questions` function handles most patterns, but test on a small sample first — different models format differently.
- **Empty strings after splitting**: Splitting `response` by `\n` often produces empty strings. The `parse_questions` function filters these automatically.
- **Chunk size matters**: Very small chunks produce trivial questions; very large chunks produce vague ones. LlamaIndex's `SimpleNodeParser` defaults to ~1024 tokens; LangChain's `RecursiveCharacterTextSplitter` requires explicit `chunk_size`. Start with 1024.
- **Google model sunsets are unpredictable**: Google skips generations and retires models without backward-compatible replacements. If any Google model returns a 404, **do NOT just increment the version number**. Always verify via [Google's models page](https://ai.google.dev/gemini-api/docs/models) or the `ListModels` API before committing a replacement. When one model family is sunset, proactively check all other Google model references in your codebase.
- **Prompt customization**: The prompt template above is generalist. For domain-specific datasets (e.g., financial reports), add domain context: *"You are a financial analyst. Questions should reference key metrics like revenue, EBITDA, EPS, and quarter-over-quarter changes."*
- **LangChain response format**: In LangChain, `chain.invoke()` returns a message object — access the text via `.content`. In LlamaIndex, `llm.complete()` returns a response that can be cast with `str()`. In pure Python with `google.generativeai`, use `.text`.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this pattern, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Google model returning 404 (model sunset — verify before replacing)
- LLM generating answers instead of questions (prompt template issue)
- Empty or malformed `queries` dict after processing (regex or splitting failure)
- Mixing up response access patterns between frameworks (`.content` vs `str()` vs `.text`)
