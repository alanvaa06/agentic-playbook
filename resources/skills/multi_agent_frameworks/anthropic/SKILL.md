---
name: anthropic
description: Implements Anthropic Claude agents for tool-calling and parallel execution workflows. Use when the user requests Claude-based agents, parallel LLM calls, function-calling with Claude, or explicitly mentions Anthropic.
---

# Anthropic (Claude)

## Core Philosophy
Anthropic agents leverage Claude's native tool-calling via LlamaIndex's `FunctionCallingAgent` for structured single-agent workflows, or the raw `anthropic` client with `ThreadPoolExecutor` for parallelized LLM calls across independent subtasks. The framework excels at orchestrating multiple concurrent analyses with a single model.

## Trigger Scenarios
✅ **WHEN to use it:**
- Single-agent tasks requiring structured tool-calling with Claude (API lookups, data retrieval)
- Parallel analysis where the same prompt must be applied to multiple independent inputs concurrently
- Tasks requiring Claude's strong reasoning for financial comparisons, sectioning, or voting patterns
- Workflows needing LlamaIndex integration for tool management

❌ **WHEN NOT to use it:**
- Multi-agent handoff workflows where agents must transfer control (use OpenAI Agents SDK)
- Tasks requiring code execution or sandboxed computation (use SmolAgents or AutoGen)
- Workflows requiring built-in conversation memory (LlamaIndex FunctionCallingAgent has limited memory)
- Budget-constrained projects where API costs per token are a concern

## Pros vs Cons
- **Pros:** Strong reasoning quality from Claude models, native tool-calling support, easy parallelization with ThreadPoolExecutor, LlamaIndex integration provides clean tool abstraction
- **Cons:** `allow_parallel_tool_calls=False` is often required for sequential dependencies, no built-in multi-agent orchestration, API cost per token is higher than GPT-4o-mini

## Implementation Template

### Pattern 1: Tool-Calling Agent (via LlamaIndex)
```python
# Input: "Give me the current price of Apple"
# Expected Output: Structured dict with price, volume, EPS, PE from API

from llama_index.llms.anthropic import Anthropic
from llama_index.core.tools import FunctionTool
from llama_index.core.agent import FunctionCallingAgent
import requests
import nest_asyncio
nest_asyncio.apply()

def get_stock_price(symbol: str) -> dict:
    """Fetch current stock price, volume, EPS, PE for a given symbol."""
    url = f"https://financialmodelingprep.com/api/v3/quote-order/{symbol}?apikey={API_KEY}"
    response = requests.get(url)
    data = response.json()
    return {
        "symbol": symbol.upper(),
        "price": data[0]["price"],
        "volume": data[0]["volume"],
        "eps": data[0]["eps"],
        "pe": data[0]["pe"],
    }

tool_stock_price = FunctionTool.from_defaults(fn=get_stock_price)

llm = Anthropic(model="claude-3-5-sonnet-20240620", api_key=CLAUDE_API_KEY)

agent = FunctionCallingAgent.from_tools(
    [tool_stock_price],
    llm=llm,
    verbose=True,
    allow_parallel_tool_calls=False,
)

response = agent.chat("Give me the current price of Apple")
print(str(response))
```

### Pattern 2: Parallel Execution (Sectioning)
```python
# Input: Multiple independent analysis prompts
# Expected Output: List of concurrent LLM responses

from anthropic import Anthropic
from concurrent.futures import ThreadPoolExecutor
from typing import List

CLIENT = Anthropic()

def llm_call(prompt: str, system_prompt: str = "", model="claude-3-5-sonnet-20241022") -> str:
    """Single LLM call with system prompt support."""
    messages = [{"role": "user", "content": prompt}]
    response = CLIENT.messages.create(
        model=model,
        max_tokens=4096,
        system=system_prompt,
        messages=messages,
        temperature=0.1,
    )
    return response.content[0].text

def parallel(prompt: str, inputs: List[str], n_workers: int = 3) -> List[str]:
    """Process multiple inputs concurrently with the same prompt."""
    with ThreadPoolExecutor(max_workers=n_workers) as executor:
        futures = [executor.submit(llm_call, f"{prompt}\nInput: {x}") for x in inputs]
        return [f.result() for f in futures]

sub_tasks = ["Institutional Investors analysis...", "Retail Traders analysis..."]
results = parallel("Analyze the impact of market volatility on this actor.", sub_tasks)
```

## Common Pitfalls
- **Parallel tool calls disabled**: Set `allow_parallel_tool_calls=False` when tools have sequential dependencies; Claude may otherwise call them out of order.
- **API key configuration**: LlamaIndex's `Anthropic` class requires the key passed directly; it does not auto-read `ANTHROPIC_API_KEY` from the environment in all versions.
- **nest_asyncio required**: When running in Jupyter notebooks, always call `nest_asyncio.apply()` before agent execution to avoid event loop conflicts.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Tool-calling failures where Claude misroutes to the wrong function
- ThreadPoolExecutor deadlocks or timeout errors during parallel execution
- LlamaIndex version incompatibilities with the Anthropic LLM wrapper
