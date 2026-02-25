---
name: smolagents
description: Implements HuggingFace SmolAgents for code-executing agent workflows. Use when the user requests CodeAgent-based tasks, tool-augmented code generation, or explicitly mentions SmolAgents.
---

# SmolAgents (HuggingFace)

## Core Philosophy
SmolAgents uses **CodeAgents** that write and execute Python code at runtime instead of generating JSON tool calls. The agent reasons in code, iteratively refining its script when imports fail or logic errors occur, running inside a sandboxed interpreter.

## Trigger Scenarios
✅ **WHEN to use it:**
- Tasks requiring the agent to write and run Python code dynamically (data analysis, calculations, plotting)
- Single-agent workflows with custom tools that return structured data
- Rapid prototyping where `LiteLLMModel` allows swapping LLM providers without code changes
- Tasks where intermediate computation must be verifiable (the generated code is visible)

❌ **WHEN NOT to use it:**
- Multi-agent collaborative workflows (use CrewAI or AutoGen instead)
- Production systems requiring strict security sandboxing (code execution risk)
- Tasks relying solely on web search for factual data retrieval (web_search tool is inaccurate for precise values)
- Workflows requiring conversation memory across sessions

## Pros vs Cons
- **Pros:** Minimal boilerplate, self-correcting code generation, supports any LiteLLM-compatible model, transparent reasoning (code is visible), built-in base tools
- **Cons:** CodeAgent may hallucinate conclusions when code fails silently, `web_search` returns inaccurate structured data, limited to single-agent, requires explicit `additional_authorized_imports`

## Implementation Template
Use this pattern as the default implementation:

```python
# Input: "Fetch NVIDIA historical stock prices for 2024"
# Expected Output: JSON string of daily OHLCV data from yfinance

from smolagents import CodeAgent, LiteLLMModel
from transformers import tool
import yfinance as yf
import json
import pandas as pd

@tool
def get_historical_prices(symbol: str, start_date: str, end_date: str) -> str:
    """
    Fetches historical prices for a given stock symbol as JSON.

    Args:
        symbol: The stock ticker symbol.
        start_date: Start date formatted as 'YYYY-MM-DD'.
        end_date: End date formatted as 'YYYY-MM-DD'.

    Returns:
        str: Historical stock prices as a JSON string.
    """
    data = yf.download(symbol, start=start_date, end=end_date)
    if isinstance(data.columns, pd.MultiIndex):
        data.columns = data.columns.droplevel(1)
    data.reset_index(inplace=True)
    data["Date"] = data["Date"].astype(str)
    result = data.to_dict(orient="records")
    return json.dumps(result)

model = LiteLLMModel("anthropic/claude-3-5-sonnet-latest")

agent = CodeAgent(
    tools=[get_historical_prices],
    model=model,
    add_base_tools=True,
    additional_authorized_imports=["numpy", "yfinance", "pandas", "json"],
)

agent.run("Fetch the NVIDIA historical stock prices for the entire year of 2024")
```

## Common Pitfalls
- **Missing `additional_authorized_imports`**: The agent will fail on `import numpy` unless you whitelist it. The agent self-corrects by rewriting code without the banned package, but results degrade.
- **`web_search` hallucinating prices**: The default `web_search` tool does not return accurate structured data (e.g., historical prices). Always create a custom `@tool` for precise data retrieval.
- **Silent computation failure**: The agent may draw conclusions (e.g., "volatility is X%") even when its code did not actually compute the value. Always verify the generated code output.
- **Tool decorator**: Import `tool` from `transformers`, not from `smolagents`.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Agent hallucinating conclusions without actual computation in the generated code
- `ImportError` or unauthorized import errors during code execution
- `web_search` returning fabricated or incorrect structured data
