---
name: crewai
description: Implements CrewAI for role-based multi-agent collaboration with hierarchical process management. Use when the user requests multi-agent teams with distinct roles, hierarchical task delegation, or explicitly mentions CrewAI.
---

# CrewAI

## Core Philosophy
CrewAI models agents as **team members with roles, goals, and backstories**. A `Crew` orchestrates `Agents` executing `Tasks` via a defined `Process` (sequential or hierarchical). In hierarchical mode, a `manager_llm` delegates tasks to agents, collects results, and synthesizes a final output. Each agent has its own tools and iteration budget.

## Trigger Scenarios
✅ **WHEN to use it:**
- Multi-agent workflows where each agent has a distinct role and specialty (analyst, strategist, advisor)
- Hierarchical delegation where a manager coordinates specialists
- Tasks requiring both custom tools (yfinance) and built-in tools (web scraping, search)
- Workflows needing configurable iteration limits per agent to control cost

❌ **WHEN NOT to use it:**
- Tasks requiring code execution and automated feedback loops (use AutoGen)
- Simple single-tool tasks (CrewAI's role/goal/backstory setup is excessive overhead)
- Budget-constrained projects (default GPT-4 with 25 iterations is very expensive)
- When you need agents to run computations (CrewAI agents reason but don't execute code)

## Pros vs Cons
- **Pros:** Intuitive role-based agent design, hierarchical process with automatic delegation, built-in `ScrapeWebsiteTool` and `SerperDevTool`, intermediate agent outputs are often more insightful than final crew output, parameterized task inputs via `kickoff(inputs={})`
- **Cons:** Default model is GPT-4 (expensive with max_iter=25), agents cannot perform calculations without a code interpreter tool, `gpt-4o` tokenizer not yet supported, requires precise task descriptions to avoid agents doing only part of the work

## Implementation Template
```python
# Input: {'stock_selection': 'AAPL', 'risk_tolerance': 'Medium', ...}
# Expected Output: Multi-agent analysis with data insights, news sentiment, strategy, and execution plan

import os
import yfinance as yf
import pandas as pd
from crewai import Agent, Task, Crew, Process
from crewai_tools import tool, ScrapeWebsiteTool, SerperDevTool
from langchain_openai import ChatOpenAI

os.environ["OPENAI_API_KEY"] = "your-key"
os.environ["SERPER_API_KEY"] = "your-serper-key"
os.environ["OPENAI_MODEL_NAME"] = "gpt-4-turbo"

@tool("Historical prices and volume for a ticker")
def stock_prices(ticker: str) -> pd.DataFrame:
    """Get historical prices and volume for a ticker for the last month."""
    stock = yf.Ticker(ticker)
    return stock.history()

@tool("Most recent news of a stock")
def stock_news(ticker: str) -> list:
    """Get the most recent news from Yahoo Finance."""
    stock = yf.Ticker(ticker)
    return stock.news

search_tool = SerperDevTool()
scrape_tool = ScrapeWebsiteTool()

data_analyst = Agent(
    role="Data Analyst",
    goal="Analyze historical market data to identify trends.",
    backstory="Specializing in financial markets using statistical modeling.",
    tools=[stock_prices],
    verbose=True,
    allow_delegation=True,
    max_iter=3,
)

news_analyst = Agent(
    role="Financial News Analyst",
    goal="Collect and analyze financial news for sentiment and trends.",
    backstory="Expert in financial news analysis and sentiment extraction.",
    tools=[stock_news],
    verbose=True,
    allow_delegation=True,
    max_iter=3,
)

strategist = Agent(
    role="Trading Strategy Developer",
    goal="Propose trading strategies based on data and news insights.",
    backstory="Quantitative analysis expert proposing risk-adjusted strategies.",
    tools=[scrape_tool, search_tool],
    verbose=True,
    allow_delegation=True,
    max_iter=3,
)

advisor = Agent(
    role="Trade Advisor",
    goal="Suggest optimal trade execution strategies.",
    backstory="Specialist in trade timing, pricing, and execution logistics.",
    verbose=True,
    allow_delegation=True,
    max_iter=3,
)

data_task = Task(
    description="Analyze market data for {stock_selection}. Identify trends using historical prices.",
    expected_output="Insights about market trends for {stock_selection}.",
    agent=data_analyst,
)

news_task = Task(
    description="Analyze news for {stock_selection}. Extract sentiment and key insights.",
    expected_output="Sentiment analysis and insights for {stock_selection}.",
    agent=news_analyst,
)

strategy_task = Task(
    description="Develop strategies based on data and news insights for {stock_selection} with {risk_tolerance} risk.",
    expected_output="Trading strategies aligned with risk tolerance for {stock_selection}.",
    agent=strategist,
)

execution_task = Task(
    description="Plan trade execution for {stock_selection} based on approved strategies.",
    expected_output="Detailed execution plans for {stock_selection}.",
    agent=advisor,
)

crew = Crew(
    agents=[data_analyst, news_analyst, strategist, advisor],
    tasks=[data_task, news_task, strategy_task, execution_task],
    manager_llm=ChatOpenAI(model="gpt-4-turbo", temperature=0),
    process=Process.hierarchical,
    verbose=True,
)

result = crew.kickoff(inputs={
    "stock_selection": "AAPL",
    "risk_tolerance": "Medium",
    "trading_strategy_preference": "Trend following",
    "news_impact_consideration": True,
})
```

## Common Pitfalls
- **Default GPT-4 is very expensive**: If you don't set `os.environ["OPENAI_MODEL_NAME"]`, CrewAI defaults to GPT-4 (not GPT-4-turbo). With default `max_iter=25`, a single crew run can cost $10+. Always set the model explicitly and reduce `max_iter`.
- **`gpt-4o` tokenizer error**: CrewAI may throw `KeyError('Could not automatically map gpt-4o to a tokeniser')`. Use `gpt-4-turbo` instead until tokenizer support is added.
- **One tool per focus area**: Assigning both data analysis and news analysis to a single agent with two tools often results in only one tool being used. Split into separate agents with focused tasks.
- **Intermediate results are gold**: The final crew output is often generic. The individual agent intermediate outputs contain the most actionable insights — log or display them.
- **No computation capability**: Agents cannot execute code. They reason about strategies but cannot compute actual returns, signals, or backtest results.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Tokenizer mapping errors when using newer OpenAI models
- Agents exceeding `max_iter` without producing useful output
- Cost overruns from unexpected GPT-4 default usage (check `OPENAI_MODEL_NAME` env var)
