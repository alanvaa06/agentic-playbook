# LangGraph StateGraph Reference

Full implementation of the LangGraph state-machine pattern for iterative code generation with reflection.

## State Definition

```python
from typing import Annotated, TypedDict, List
from langgraph.graph.message import AnyMessage, add_messages

class GraphState(TypedDict):
    error: str                          # "yes" / "no" — did code check fail?
    messages: Annotated[list[AnyMessage], add_messages]
    generation: str                     # current code solution
    iterations: int                     # loop counter
    reflection: str                     # "yes" / "no" — was reflection applied?
    not_reflect_anymore: str            # "yes" / "no" — stop reflecting?
```

## Structured Output with Pydantic

```python
from pydantic import BaseModel, Field
from langchain_mistralai import ChatMistralAI

class CodeGenerate(BaseModel):
    prefix: str = Field(description="Description of the strategy and parameters")
    imports: str = Field(description="Import statements")
    code: str = Field(description="Code block without imports")

llm = ChatMistralAI(model="codestral-latest", temperature=0)
code_gen_chain = llm.with_structured_output(CodeGenerate)
```

## Node Definitions

```python
def generate(state: GraphState):
    """Generate a code solution from the current messages."""
    messages = state["messages"]
    iterations = state["iterations"]
    code_solution = code_gen_chain.invoke(messages)
    messages += [
        ("assistant", f"Attempt: {code_solution.prefix}\nImports: {code_solution.imports}\nCode: {code_solution.code}")
    ]
    return {"generation": code_solution, "messages": messages, "iterations": iterations + 1}

def code_check(state: GraphState):
    """Execute the generated code and check for errors."""
    code_solution = state["generation"]
    combined = f"{code_solution.imports}\n{code_solution.code}"
    try:
        exec(combined)
        return {"error": "no"}
    except Exception as e:
        state["messages"] += [("user", f"Code failed with error: {e}. Fix it.")]
        return {"error": "yes"}

def code_reflection(state: GraphState):
    """Reflect on the generated code for accuracy and improvements."""
    code_solution = state["generation"]
    reflection_msg = [("user", f"Reflect on this code for accuracy, signals, and improvements: {code_solution}")]
    reflected = code_gen_chain.invoke(reflection_msg)
    if reflected.code == code_solution.code:
        return {"reflection": "no", "not_reflect_anymore": "yes"}
    return {"generation": reflected, "reflection": "yes", "not_reflect_anymore": "yes"}
```

## Conditional Edge Functions

```python
max_iterations = 5

def decide_to_reflect_or_finish(state: GraphState):
    if state["error"] == "no" and state.get("not_reflect_anymore", "no") == "no":
        return "reflect"
    elif state["error"] == "no" and state.get("not_reflect_anymore") == "yes":
        return "end"
    elif state["iterations"] >= max_iterations:
        return "end"
    else:
        return "regenerate"

def decide_after_reflection(state: GraphState):
    if state["reflection"] == "no" or state["iterations"] >= max_iterations:
        return "end"
    return "recheck"
```

## Graph Assembly

```python
from langgraph.graph import END, StateGraph

builder = StateGraph(GraphState)

builder.add_node("generate", generate)
builder.add_node("check", code_check)
builder.add_node("reflect", code_reflection)

builder.set_entry_point("generate")
builder.add_edge("generate", "check")
builder.add_conditional_edges("check", decide_to_reflect_or_finish, {
    "reflect": "reflect",
    "end": END,
    "regenerate": "generate",
})
builder.add_conditional_edges("reflect", decide_after_reflection, {
    "end": END,
    "recheck": "check",
})

graph = builder.compile()
```

## Execution and Visualization

```python
from IPython.display import Image, display

display(Image(graph.get_graph().draw_mermaid_png()))

result = graph.invoke({
    "messages": [("user", "Implement a momentum trading strategy for NVDA")],
    "iterations": 0,
    "error": "no",
    "reflection": "no",
    "not_reflect_anymore": "no",
})
```
