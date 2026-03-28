---
name: langchain-langgraph
description: Implements LangChain and LangGraph for reflection agents, stateful graph workflows, and ReAct agents. Use when the user requests self-correcting code generation, graph-based agent workflows, ReAct reasoning, or explicitly mentions LangChain or LangGraph.
---

# LangChain / LangGraph

## Core Philosophy
LangGraph extends LangChain with **stateful, graph-based** agent orchestration. Nodes represent agent actions (generate, check, reflect), edges define control flow (conditional loops, max iterations), and state accumulates across steps. This enables patterns impossible with linear chains: reflection loops, conditional branching, and multi-step self-correction.

## Trigger Scenarios
✅ **WHEN to use it:**
- Self-correcting workflows where generated output must be critiqued and refined iteratively (Reflection pattern)
- Complex multi-step pipelines requiring conditional branching and state management (LangGraph)
- ReAct-style agents that interleave reasoning with tool-calling and maintain conversation memory
- Tasks requiring model flexibility (supports OpenAI, Anthropic, Mistral via LangChain wrappers)

❌ **WHEN NOT to use it:**
- Simple single-tool call tasks (overhead of graph setup is unnecessary; use direct API calls)
- Multi-agent handoff workflows where distinct agents transfer control (use OpenAI Agents SDK)
- Tasks requiring parallel independent LLM calls (use Anthropic parallel pattern)
- When team has no familiarity with graph/state-machine concepts (steep learning curve)

## Pros vs Cons
- **Pros:** Model-agnostic (swap providers freely), powerful state management, visual graph debugging (`graph.get_graph().draw_mermaid_png()`), built-in `MemorySaver` for conversation history, structured output via Pydantic, iterative refinement is first-class
- **Cons:** Verbose boilerplate for graph setup, reflection may not improve code if prompts are unclear, debugging complex graphs is difficult, requires understanding of TypedDict state patterns

## Implementation Template

### Pattern 1: ReAct Agent (Simplest Entry Point)
```python
# Input: "Get NVIDIA stock prices for 2024 and compute weekly returns"
# Expected Output: Agent reasons, calls tool, returns data with analysis

from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage
from langgraph.checkpoint.memory import MemorySaver
from langgraph.prebuilt import create_react_agent
import yfinance as yf
import pandas as pd

def get_stock_prices(ticker: str, start_date: str, end_date: str) -> pd.DataFrame:
    """Get historical prices and volume for a ticker.

    Args:
        ticker: the stock ticker symbol
        start_date: start date in YYYY-MM-DD format
        end_date: end date in YYYY-MM-DD format
    """
    return yf.download(ticker, start=start_date, end=end_date)

memory = MemorySaver()
model = ChatAnthropic(model_name="claude-3-5-sonnet-20241022")
agent = create_react_agent(model, [get_stock_prices], checkpointer=memory)

config = {"configurable": {"thread_id": "1"}}
result = agent.invoke({"messages": HumanMessage(content="Get NVIDIA prices for 2024")}, config)
```

### Pattern 2: Reflection Loop (Manual)
```python
# Input: "Generate a momentum trading strategy in Python"
# Expected Output: Code refined through 3 iterations of generate -> critique -> improve

from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-3.5-turbo-0125")

generate_prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a Python code generator. Produce clean, executable code only."),
    MessagesPlaceholder(variable_name="messages"),
])
generate = generate_prompt | llm

reflect_prompt = ChatPromptTemplate.from_messages([
    ("system", "Evaluate the code for correctness, PEP 8, and logic errors."),
    MessagesPlaceholder(variable_name="messages"),
])
reflect = reflect_prompt | llm

request = HumanMessage(content="Implement a momentum trading strategy")
code = generate.invoke({"messages": [request]}).content

for _ in range(3):
    reflection = reflect.invoke({"messages": [request, HumanMessage(content=code)]}).content
    code = generate.invoke({
        "messages": [request, AIMessage(content=code), HumanMessage(content=reflection)]
    }).content
```

### Pattern 3: LangGraph State Machine
For the full LangGraph pattern with `StateGraph`, `GraphState`, conditional edges, and structured output via Pydantic, see [reference.md](reference.md).

## Common Pitfalls
- **Reflection adds no value with vague prompts**: If the reflection prompt doesn't specify what to check (computation accuracy, signal correctness), it may return "looks good" and waste iterations.
- **`max_iterations` guard**: Always set a `max_iterations` cap in LangGraph to prevent infinite loops in generate-check-reflect cycles.
- **Non-existent methods**: Explicitly instruct the generator to avoid hallucinating methods like `np.rolling` or `pd.rolling` (these don't exist).
- **Thread ID for memory**: When using `MemorySaver`, always pass a `thread_id` in the config; without it, conversation history is not persisted.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Infinite loops in reflection/generate cycles (missing termination condition)
- `GraphState` TypedDict missing required fields causing runtime KeyError
- Reflection agent returning unchanged code across iterations

## Additional Resources
- For the full LangGraph `StateGraph` pattern with structured output, conditional edges, and code-check nodes, see [reference.md](reference.md)
