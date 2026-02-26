---
name: autogen
description: Implements Microsoft AutoGen for multi-agent collaborative group chats with code execution. Use when the user requests group-chat-style multi-agent workflows, code generation with critic review, or explicitly mentions AutoGen.
---

# AutoGen (Microsoft)

## Core Philosophy
AutoGen orchestrates **collaborative group chats** where specialized agents (code generator, code executor, critic, comparer) converse in rounds managed by a `GroupChatManager`. The manager dynamically selects the next speaker, broadcasts responses, and loops until the task converges or `max_round` is reached. Unlike handoff-based systems, all agents see all messages.

## Trigger Scenarios
✅ **WHEN to use it:**
- Workflows requiring code generation, execution, and critique in an automated loop
- Tasks where multiple expert perspectives must evaluate the same output (critic, comparer roles)
- End-to-end pipelines: generate code -> execute -> evaluate -> refine
- Tasks requiring local code execution with timeout controls (`LocalCommandLineCodeExecutor`)

❌ **WHEN NOT to use it:**
- Simple single-tool-call tasks (group chat overhead is excessive)
- Tasks requiring structured handoffs between agents (use OpenAI Agents SDK)
- Workflows where agents must operate independently in parallel (use Anthropic parallel pattern)
- Security-sensitive environments where local code execution is not acceptable

## Pros vs Cons
- **Pros:** Built-in code execution with `LocalCommandLineCodeExecutor`, self-correcting feedback loop between generator and executor, flexible role definitions, supports any OpenAI-compatible model, `GroupChatManager` handles speaker selection automatically
- **Cons:** Token-expensive (all agents see all messages), difficult to control conversation flow precisely, `max_round` must be tuned per task, no built-in tools/function-calling (relies on code generation), date-awareness requires explicit prompting

## Implementation Template
```python
# Input: "Implement a momentum trading strategy for NVIDIA and compute returns"
# Expected Output: Generated Python code, executed results, critic review, and comparison

import os
from autogen import AssistantAgent, UserProxyAgent, GroupChat, GroupChatManager
from autogen.coding import LocalCommandLineCodeExecutor

OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]
config_list = [{"model": "gpt-4o", "api_key": OPENAI_API_KEY}]

executor = LocalCommandLineCodeExecutor(timeout=60, work_dir="code")

code_generator = AssistantAgent(
    name="Code_generator",
    llm_config={"config_list": config_list},
    human_input_mode="NEVER",
)

code_executor = UserProxyAgent(
    name="Code_executor",
    code_execution_config={"executor": executor},
    llm_config=False,
    human_input_mode="NEVER",
)

critic = AssistantAgent(
    name="Critic_agent",
    system_message="""Critic. Evaluate code for:
    - Executability: Are all libraries available?
    - Calculation: Is the trading strategy accurately implemented?
    - Buy/Sell Signals: Are signals computed correctly?
    - Return: Is the final return computed correctly?
    Provide a score for each aspect.""",
    llm_config={"config_list": config_list},
    human_input_mode="NEVER",
)

comparer = AssistantAgent(
    name="Comparer",
    system_message="Compare results across strategy variations. Comment on signals and returns.",
    llm_config={"config_list": config_list},
    human_input_mode="NEVER",
)

groupchat = GroupChat(
    agents=[code_executor, code_generator, critic, comparer],
    messages=[],
    max_round=20,
)
manager = GroupChatManager(groupchat=groupchat, llm_config={"config_list": config_list})

chat_result = code_executor.initiate_chat(
    manager,
    message="""Let's proceed step by step:
    1- Which date is today?
    2- Implement a momentum trading strategy with 2 moving averages.
    3- Apply to NVIDIA historical prices for the current year.
    4- Compute buy/sell signals and final return.
    """,
)
```

## Common Pitfalls
- **Outdated data without date prompt**: If you don't ask "What is today's date?" first, the agent may use its training cutoff date and fetch stale prices. Always include a date-check step.
- **`max_round` tuning**: Simple tasks need `max_round=5`; complex multi-step tasks need `max_round=20+`. Too low and the conversation terminates before completion.
- **Work directory artifacts**: `LocalCommandLineCodeExecutor` creates files in `work_dir`. Clean up between runs to avoid stale file conflicts.
- **Token cost explosion**: All agents receive all messages. With 4 agents and 20 rounds, token consumption grows quadratically. Monitor costs actively.
- **Code executor feedback loop**: When generated code fails, the executor's error feeds back to the generator automatically, which then corrects. This is a feature, not a bug — but it can consume many rounds.

## 🚨 Self-Correction Mandate
Throughout every step of implementing or running this framework, if you encounter any errors or unexpected behavior, **immediately** append an entry to `tasks/self-correction.md` detailing the failure and the attempted fix. Pay special attention to:
- `LocalCommandLineCodeExecutor` timeout errors (increase `timeout` parameter)
- GroupChat conversations looping without convergence (increase `max_round` or improve prompts)
- Code generator producing non-executable code that the executor cannot run
