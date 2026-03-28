---
name: openai-agents-sdk
description: Implements OpenAI Agents SDK for multi-agent orchestration with handoffs, function tools, and tracing. Use when the user requests multi-agent handoff workflows, OpenAI-based agents, or explicitly mentions OpenAI Agents SDK.
---

# OpenAI Agents SDK

## Core Philosophy
The Agents SDK is OpenAI's production-ready multi-agent framework (successor to the experimental Swarm). Agents are defined with instructions, tools, and handoffs. A **Manager Agent** routes user requests to specialized sub-agents, which execute tools and return results. Built-in tracing provides full observability via the OpenAI Dashboard.

## Trigger Scenarios
✅ **WHEN to use it:**
- Multi-agent workflows where a manager delegates to specialized agents via handoffs
- Tasks requiring built-in tools (WebSearchTool, file search, computer use)
- Workflows needing production-grade tracing and observability (OpenAI Dashboard)
- Structured output requirements (typed responses via `output_type` with dataclasses)
- Agent-to-agent chaining where one agent's output feeds the next

❌ **WHEN NOT to use it:**
- Tasks requiring conversation memory across sessions (not yet supported; Assistants API threads planned for mid-2026)
- Workflows requiring code execution in a sandbox (use SmolAgents or AutoGen)
- Budget-sensitive projects where OpenAI API costs are prohibitive
- Tasks requiring non-OpenAI models (SDK is OpenAI-only)

## Pros vs Cons
- **Pros:** Clean handoff abstraction, built-in WebSearchTool, production-ready tracing, structured outputs via dataclasses, straightforward agent definitions, official OpenAI support
- **Cons:** No conversation memory yet, OpenAI-only (no model swapping), multiple handoffs in a single turn are ignored (only first is executed), API costs scale with agent count

## Implementation Template

### Pattern 1: Multi-Agent with Handoffs
```python
# Input: "What is the current stock price of Amazon and Nvidia?"
# Expected Output: Manager routes to Stock Price Agent, which calls get_stock_price tool

from agents import Agent, Runner, function_tool
import requests
import nest_asyncio
nest_asyncio.apply()

@function_tool
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
    }

@function_tool
def get_company_financials(symbol: str) -> dict:
    """Fetch company profile: industry, sector, market cap."""
    url = f"https://financialmodelingprep.com/api/v3/profile/{symbol}?apikey={API_KEY}"
    response = requests.get(url)
    data = response.json()
    return {"companyName": data[0]["companyName"], "marketCap": data[0]["mktCap"]}

stock_agent = Agent(
    name="Stock Price Agent",
    instructions="Fetch stock prices for given symbols.",
    tools=[get_stock_price],
)

financials_agent = Agent(
    name="Financials Agent",
    instructions="Fetch company financial profiles.",
    tools=[get_company_financials],
)

manager = Agent(
    name="Manager Agent",
    instructions="Route the user's request to the best sub-agent.",
    handoffs=[stock_agent, financials_agent],
)

output = Runner.run_sync(starting_agent=manager, input="Current price of AMZN?")
print(output.final_output)
```

### Pattern 2: Structured Output with Evaluation Loop
```python
# Input: "Get top 5 European financial news"
# Expected Output: News summary evaluated for completeness, looped until passing

from agents import Agent, Runner, WebSearchTool, ItemHelpers
from dataclasses import dataclass
from typing import Literal

@dataclass
class EvaluationFeedback:
    feedback: str
    score: Literal["successful", "needs_links"]

searcher = Agent(
    name="news_searcher",
    instructions="Search for the latest financial news in the requested region.",
    tools=[WebSearchTool()],
)

evaluator = Agent(
    name="news_evaluator",
    instructions="Evaluate if each news item has a supporting external link.",
    output_type=EvaluationFeedback,
)

result = await Runner.run(searcher, "Top 5 European financial news")
input_items = result.to_input_list()

eval_result = await Runner.run(evaluator, ItemHelpers.text_message_outputs(result.new_items))
feedback: EvaluationFeedback = eval_result.final_output
```

### Debugging Intermediate Steps
```python
from agents import items

for item in output.new_items:
    if isinstance(item, items.HandoffCallItem):
        print(f"Handoff -> {item.agent.name}")
    elif isinstance(item, items.ToolCallItem):
        print(f"Tool call by {item.agent.name}")
    elif isinstance(item, items.MessageOutputItem):
        print(f"Message: {item.raw_item.content[0].text}")
```

## Common Pitfalls
- **Multiple handoffs ignored**: If the manager tries to handoff to two agents in one turn, only the first executes. Design prompts to request one thing at a time, or chain sequentially.
- **No memory**: The SDK does not persist conversation history across `Runner.run_sync` calls. Pass prior output via `result.to_input_list()` for chaining.
- **`nest_asyncio` required**: Always call `nest_asyncio.apply()` in Jupyter notebooks before using `Runner.run_sync`.
- **Default model**: If no model is specified, the SDK defaults to `gpt-4o-2024-08-06`.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Handoff routing failures where the manager selects the wrong sub-agent
- `Runner.run_sync` hanging due to missing `nest_asyncio.apply()`
- Structured output deserialization errors with `output_type` dataclasses
