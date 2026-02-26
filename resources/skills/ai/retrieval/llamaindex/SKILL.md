---
name: llamaindex
description: Implements LlamaIndex FinanceAgentToolSpec for pre-built financial data retrieval agents. Use when the user requests financial data aggregation from multiple APIs, earnings analysis, stock screening, or explicitly mentions LlamaIndex.
---

# LlamaIndex (FinanceAgentToolSpec)

## Core Philosophy
LlamaIndex provides a **pre-built financial toolkit** (`FinanceAgentToolSpec`) that bundles 15+ financial data tools into a single agent. Instead of writing custom API wrappers, you instantiate the spec with API keys and get immediate access to stock prices, earnings, news, trending data, and company comparisons. The agent handles tool selection and API orchestration automatically.

## Trigger Scenarios
✅ **WHEN to use it:**
- Rapid prototyping of financial data agents without writing custom tool functions
- Tasks requiring aggregation from multiple data sources (Polygon, Finnhub, Alpha Vantage, NewsAPI)
- Earnings history analysis, stock screening (gainers, losers, undervalued), and news retrieval
- When you need a working agent in under 20 lines of code

❌ **WHEN NOT to use it:**
- Tasks requiring custom data transformations or computations (the tools return raw data only)
- When you need precise control over API parameters (the tool spec abstracts away options)
- Production systems where specific tool reliability is critical (some tools use unreliable yfinance URLs)
- Multi-agent or code-execution workflows (use OpenAI Agents SDK or SmolAgents)

## Pros vs Cons
- **Pros:** 15+ pre-built tools, minimal boilerplate, supports any LlamaIndex-compatible LLM (OpenAI, Claude), good starting point for customization, verbose mode shows tool selection reasoning
- **Cons:** Several tools broken (yfinance URL-based tools return errors), news search by ticker returns wrong results (must use company name), no custom computation capabilities, limited to the data sources bundled in the spec

## Implementation Template
```python
# Input: "What was the last closing price of Amazon?"
# Expected Output: Dict with current price, high, low, open, and % change from API

from llama_index.tools.finance import FinanceAgentToolSpec
from llama_index.agent.openai import OpenAIAgent
from llama_index.llms.openai import OpenAI

POLYGON_API_KEY = "your-polygon-key"
FINNHUB_API_KEY = "your-finnhub-key"
ALPHA_VANTAGE_API_KEY = "your-alpha-vantage-key"
NEWS_API_KEY = "your-newsapi-key"
OPENAI_API_KEY = "your-openai-key"

tool_spec = FinanceAgentToolSpec(
    POLYGON_API_KEY,
    FINNHUB_API_KEY,
    ALPHA_VANTAGE_API_KEY,
    NEWS_API_KEY,
)

llm = OpenAI(temperature=0, model="gpt-4o-mini", api_key=OPENAI_API_KEY)

agent = OpenAIAgent.from_tools(
    tool_spec.to_tool_list(),
    llm=llm,
    verbose=True,
)

response = agent.chat("What was the last closing price of Amazon?")
print(str(response))
```

### Available Tools
```python
tool_spec.spec_functions
# Returns:
# ['find_similar_companies', 'get_earnings_history',
#  'get_stocks_with_upcoming_earnings', 'get_current_gainer_stocks',
#  'get_current_loser_stocks', 'get_current_undervalued_growth_stocks',
#  'get_current_technology_growth_stocks', 'get_current_most_traded_stocks',
#  'get_current_undervalued_large_cap_stocks',
#  'get_current_aggressive_small_cap_stocks', 'get_trending_finance_news',
#  'get_google_trending_searches', 'get_google_trends_for_query',
#  'get_latest_news_for_stock', 'get_current_stock_price_info']
```

## Common Pitfalls
- **News by ticker returns wrong results**: `get_latest_news_for_stock("AMZN")` may return NVIDIA news. Use the company name instead: `agent.chat("Latest news about Amazon")`.
- **yfinance-based tools broken**: `get_current_technology_growth_stocks` and `get_current_gainer_stocks` use a yfinance URL that returns an error page. These tools need custom patching.
- **Earnings estimate tool unreliable**: `get_latest_earning_estimate` may fail silently when asked alongside actual earnings.
- **4 API keys required**: All four keys (Polygon, Finnhub, Alpha Vantage, NewsAPI) must be valid; a single invalid key can cause silent failures in specific tools.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- Tools returning "Will be right back" or HTML error pages instead of data
- News queries returning results for the wrong company
- `ImportError` from missing `llama_index.tools.finance` package (requires `pip install llama-index-tools-finance`)
