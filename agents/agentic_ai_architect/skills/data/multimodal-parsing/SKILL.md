---
name: multimodal-parsing
description: Implements advanced PDF parsing for documents containing charts, graphs, and complex tables using LlamaParse Premium or Anthropic's native PDF API. Use when standard PDF loaders destroy visual content, or when the user needs to extract data from charts embedded in PDFs.
---

# Multimodal PDF Parsing

## Core Philosophy
Standard PDF parsers (`PyPDF2`, basic `SimpleDirectoryReader`) convert PDFs to plain text, destroying charts, graphs, and complex table layouts. Multimodal parsing uses vision models under the hood to "see" visual content and extract structured data from it. This skill provides two implementation paths depending on the project's existing dependencies.

## Framework Detection
Before generating code, **check the user's current project context**:
1. If the project uses `llama_index` or `llama-parse` -> use **Pattern A (LlamaParse Premium)**.
2. If the project uses `anthropic` -> use **Pattern B (Anthropic Native PDF)**.
3. If neither is present -> default to **Pattern B** (fewer dependencies).

## Trigger Scenarios
WHEN to use it:
- PDFs contain charts, graphs, or complex multi-column tables that standard text extraction destroys
- Financial reports (10-Ks, earnings statements) where chart data is critical to the analysis
- Building RAG pipelines over visually rich documents where retrieval quality depends on parsed fidelity
- When basic `PyPDF2` or `SimpleDirectoryReader` output is missing key visual data

WHEN NOT to use it:
- Text-only PDFs with simple formatting (standard parsers are sufficient and cheaper)
- When the document is already available as structured data (CSV, JSON, database)
- High-volume batch processing where API costs per page are a concern (LlamaParse Premium charges per page)
- When you only need a rough summary and exact chart data is not required

## Pros vs Cons
- **Pros:** Accurately extracts data from charts and complex tables, dramatically improves RAG retrieval quality on visual documents, LlamaParse Premium combines fast text parsing with multimodal extraction automatically
- **Cons:** More expensive than standard parsing (API cost per page), requires additional API keys (LlamaParse or Anthropic), Anthropic PDF beta may change without notice, slower than pure text extraction

## Implementation Templates

### Pattern A: LlamaParse Premium
Best when you already use LlamaIndex for your RAG pipeline.

```python
# Input: A PDF with charts and complex tables
# Expected Output: High-fidelity markdown with chart data preserved

import nest_asyncio
nest_asyncio.apply()

from llama_parse import LlamaParse

LLAMAPARSE_API_KEY = "your-llamacloud-key"
ANTHROPIC_API_KEY = "your-anthropic-key"

# Option 1: Premium mode (LlamaParse's own multimodal pipeline)
parser_premium = LlamaParse(
    api_key=LLAMAPARSE_API_KEY,
    result_type="markdown",
    premium_mode=True,
)

# Option 2: Vendor multimodal (uses Anthropic/OpenAI vision under the hood)
parser_vendor = LlamaParse(
    api_key=LLAMAPARSE_API_KEY,
    result_type="markdown",
    premium_mode=False,
    use_vendor_multimodal_model=True,
    vendor_multimodal_model_name="anthropic-sonnet-3.5",
    vendor_multimodal_api_key=ANTHROPIC_API_KEY,
)

# Parse the document
documents = parser_premium.load_data("path/to/financial_report.pdf")

for doc in documents:
    print(doc.text)
```

#### When to use Premium vs Vendor Multimodal
| Mode | Best For |
|------|---------|
| `premium_mode=True` | General documents with mixed text + charts. LlamaParse automatically decides when to use vision. |
| `use_vendor_multimodal_model=True` | When you want explicit control over which vision model processes the visual content. |

### Pattern B: Anthropic Native PDF API
Best when you want direct control and are already using the Anthropic SDK.

```python
# Input: A PDF file path
# Expected Output: Extracted chart/table data via Claude's native PDF understanding

import anthropic
import base64

CLAUDE_API_KEY = "your-anthropic-key"

def upload_pdf(path_to_pdf: str) -> str:
    """Read a PDF and return its base64-encoded string."""
    with open(path_to_pdf, "rb") as pdf_file:
        binary_data = pdf_file.read()
        return base64.b64encode(binary_data).decode("utf-8")

client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)
MODEL_NAME = "claude-3-5-sonnet-20241022"

def query_pdf(query: str, pdf_data: str, model: str = MODEL_NAME):
    """Send a query against a base64-encoded PDF using Anthropic's PDF beta."""
    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "document",
                    "source": {
                        "type": "base64",
                        "media_type": "application/pdf",
                        "data": pdf_data,
                    },
                    "cache_control": {"type": "ephemeral"},
                },
                {"type": "text", "text": query},
            ],
        }
    ]

    completion = client.beta.messages.create(
        betas=["pdfs-2024-09-25", "prompt-caching-2024-07-31"],
        model=model,
        max_tokens=8192,
        messages=messages,
        temperature=0,
    )
    return completion

# Usage
pdf_data = upload_pdf("path/to/financial_report.pdf")

response = query_pdf("Extract all data from Chart 1 on page 8.", pdf_data)
print(response.content[0].text)
```

## Common Pitfalls
- **Standard parsers destroy charts**: `PyPDF2`, basic `SimpleDirectoryReader`, and `pdfplumber` convert PDFs to text only. If the document has charts, you WILL lose that data. Always check if the PDF has visual content before choosing a parser.
- **Page number mismatch (Anthropic)**: When asking Claude to extract from a specific page (e.g., "page 8"), use the absolute page index as displayed by your PDF viewer, NOT the page number printed in the document header/footer. These often differ.
- **Anthropic beta flags are required**: The native PDF feature requires `betas=["pdfs-2024-09-25", "prompt-caching-2024-07-31"]` in the API call. Without these flags, the `document` content type will be rejected.
- **Model limitation**: As of the notebook's writing, only `claude-3-5-sonnet-20241022` supports native PDF input. Verify the latest supported models before using a different version.
- **Cost awareness**: LlamaParse Premium charges per page. Anthropic charges per token (the PDF is converted to tokens internally). For a 100-page 10-K, estimate costs before processing.

## Self-Correction Mandate
Throughout every step of implementing or running this pattern, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Anthropic beta flags being rejected (beta may have graduated to GA or changed names)
- LlamaParse Premium returning empty markdown for chart-heavy pages
- Model version returning 404 (check for sunset — see the Gemini lesson in `tasks/self-correction.md`)
