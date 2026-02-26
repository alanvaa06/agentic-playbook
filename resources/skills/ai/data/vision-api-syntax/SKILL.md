---
name: vision-api-syntax
description: Provides the exact, provider-specific boilerplate for sending images to OpenAI and Anthropic vision models. Use when the user needs to pass raw images (charts, screenshots, diagrams) to an LLM for visual reasoning, data extraction, or analysis.
---

# Vision API Syntax (OpenAI + Anthropic)

## Core Philosophy
Sending images to LLMs requires provider-specific message structures that are easy to confuse. OpenAI uses `image_url` with a data URI; Anthropic uses `image` with a `source` object. This skill eliminates guesswork by providing copy-paste-ready boilerplate for both providers, including the shared base64 encoding logic.

## Trigger Scenarios
WHEN to use it:
- Passing raw `.png`, `.jpg`, or `.webp` images (financial charts, screenshots, diagrams) to an LLM for analysis
- Building scripts that extract structured data from chart images via vision models
- Comparing outputs across OpenAI and Anthropic vision models for benchmarking
- Any task where the input is an image file, not a PDF (for PDFs, use the `multimodal-parsing` skill instead)

WHEN NOT to use it:
- When the input is a PDF document (use `resources/skills/ai/data/multimodal-parsing/SKILL.md` instead)
- When the image is embedded in a webpage and can be scraped as text/HTML
- When OCR tools (Tesseract) would suffice for simple text-in-image extraction
- When using multimodal models via LlamaIndex or LangChain abstractions (they handle encoding internally)

## Pros vs Cons
- **Pros:** Direct API control, works with any image format, supports multiple images per message, provider-agnostic encoding logic, supports JSON mode for structured extraction (OpenAI)
- **Cons:** Manual base64 encoding required, message structure differs between providers (easy to confuse), image size affects token cost and latency

## Shared: Image Encoding

This encoding logic is used identically for both OpenAI and Anthropic. It resizes large images to reduce token cost and converts to base64.

```python
import io
import base64
from PIL import Image

def encode_images(image_paths: list[str], max_size: tuple = (1024, 1024), quality: int = 75) -> list[str]:
    """Resize and base64-encode a list of images for vision API calls."""
    encoded_images = []
    for path in image_paths:
        image = Image.open(path)
        if image.size[0] > max_size[0] or image.size[1] > max_size[1]:
            image.thumbnail(max_size, Image.Resampling.LANCZOS)
        buffer = io.BytesIO()
        image.save(buffer, format="PNG", optimize=True, quality=quality)
        buffer.seek(0)
        encoded = base64.b64encode(buffer.getvalue()).decode("utf-8")
        encoded_images.append(encoded)
    return encoded_images
```

## Implementation Templates

### Pattern A: OpenAI (gpt-4o / o1)

```python
# Input: One or more chart images + a question
# Expected Output: Structured JSON extracted from the chart

from openai import OpenAI

client = OpenAI(api_key=OPENAI_API_KEY)

encoded_images = encode_images(["chart1.png", "chart2.png"])

content = [
    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img}"}}
    for img in encoded_images
]
content.append({"type": "text", "text": "Extract all data from these charts as JSON."})

messages = [{"role": "user", "content": content}]

# Standard call (gpt-4o)
response = client.chat.completions.create(
    model="gpt-4o",
    messages=messages,
    response_format={"type": "json_object"},
)
print(response.choices[0].message.content)

# Reasoning call (o1) — same message structure, no json_mode
response_o1 = client.chat.completions.create(
    model="o1",
    messages=messages,
)
print(response_o1.choices[0].message.content)
```

#### OpenAI Message Structure
```python
messages = [
    {
        "role": "user",
        "content": [
            {
                "type": "image_url",
                "image_url": {"url": f"data:image/png;base64,{encoded_png}"}
            },
            {
                "type": "text",
                "text": "Your question here"
            }
        ]
    }
]
```

### Pattern B: Anthropic (Claude 3.5 Sonnet)

```python
# Input: One or more chart images + a question
# Expected Output: Detailed text analysis of the chart data

import anthropic

client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)

encoded_images = encode_images(["chart1.png", "chart2.png"])

content = [
    {
        "type": "image",
        "source": {"type": "base64", "media_type": "image/png", "data": img},
    }
    for img in encoded_images
]
content.append({"type": "text", "text": "Extract all data from these charts."})

messages = [{"role": "user", "content": content}]

response = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=2048,
    temperature=0,
    messages=messages,
)
print(response.content[0].text)
```

#### Anthropic Message Structure
```python
messages = [
    {
        "role": "user",
        "content": [
            {
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": "image/png",
                    "data": encoded_png
                }
            },
            {
                "type": "text",
                "text": "Your question here"
            }
        ]
    }
]
```

## Quick Reference: Provider Differences

| Feature | OpenAI (gpt-4o / o1) | Anthropic (Claude 3.5) |
|---------|----------------------|------------------------|
| Image content type | `"image_url"` | `"image"` |
| Image data wrapper | `{"url": "data:image/png;base64,..."}` | `{"source": {"type": "base64", "media_type": "image/png", "data": "..."}}` |
| JSON mode | `response_format={"type": "json_object"}` | Not natively supported; instruct in prompt |
| Multiple images | Multiple `image_url` entries in `content` array | Multiple `image` entries in `content` array |
| Best for charts | Claude 3.5 Sonnet outperformed GPT-4o and Claude 3 Opus on complex financial chart extraction |

## Common Pitfalls
- **Mixing up message structures**: OpenAI uses `image_url` with a `url` field containing the full data URI. Anthropic uses `image` with a `source` object containing `type`, `media_type`, and `data` separately. Swapping these causes silent failures or API errors.
- **Image size vs cost**: Large images (4000x3000) consume significantly more tokens. Always resize with `image.thumbnail((1024, 1024))` before encoding. This reduces cost without meaningfully degrading chart readability.
- **`o1` does not support JSON mode**: While `gpt-4o` supports `response_format={"type": "json_object"}`, the `o1` reasoning model does not. Instruct JSON output in the prompt text instead.
- **Claude 3.5 Sonnet is the most accurate for charts**: Based on benchmarking in this repository, Claude 3.5 Sonnet extracted all information accurately from complex financial charts, while GPT-4o and Claude 3 Opus missed key data points. Prefer Claude 3.5 for chart extraction tasks.
- **Media type must match**: Set `media_type` to `"image/png"` for PNGs and `"image/jpeg"` for JPEGs. A mismatch may cause silent decoding errors.

## Self-Correction Mandate
Throughout every step of implementing or running this pattern, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- API returning errors due to incorrect message structure (provider mismatch)
- Model returning 404 (check for sunset — verify current model names before replacing)
- Vision model hallucinating chart values that don't exist in the image
