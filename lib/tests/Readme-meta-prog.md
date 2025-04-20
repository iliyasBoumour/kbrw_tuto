# Quote & unquote

## Quote
- In Elixir abstract syntax tree (AST) os the internal representation of our code, is composed of tuples. 
- These tuples contain three parts: `function name, metadata, and function arguments`.
- In order to see these internal structures, Elixir supplies us with the `quote/2` function. 
- Using `quote/2` we can convert Elixir code into its underlying representation:

```elixir
quote do: 42
# 42

quote do: 1 + 2
# {:+, [context: Elixir, import: Kernel], [1, 2]}

quote do: 1+2+3
# {
#    :+, 
#    [context: Elixir, import: Kernel],
#    [
#        # First param
#        {
#            :+, 
#            [context: Elixir, import: Kernel], 
#            [1, 2]
#        }, 
#        # Second param
#        3
#    ]
# }

quote do: if value, do: "True", else: "False"
# {
#    :if, 
#    [context: Elixir, import: Kernel],
#    [
#        {:value, [], Elixir}, 
#        [do: "True", else: "False"]
#    ]
# }
```

Notice the first three don’t return tuples? There are five literals that return themselves when quoted:
- Atoms
- strings
- numbers
- lists
- 2 elements tuples

## Unquote

- Now that we can retrieve the internal structure of our code, how do we modify it? To inject new code or values we use `unquote/1`. 
- When we unquote an expression it will be evaluated and injected into the AST. 
- To demonstrate unquote/1 let’s look at some examples:

```elixir
denominator = 2
# 2

quote do: divide(42, denominator)
# {:divide, [], [42, {:denominator, [], Elixir}]}
# Notice that it evaluated denominator as an atom

quote do: divide(42, unquote(denominator))
# {:divide, [], [42, 2]}
```

Working with lists

```elixir
inner = [3, 4, 5]
Macro.to_string(quote do: [1, 2, unquote(inner), 6])
"[1, 2, [3, 4, 5], 6]"

Macro.to_string(quote do: [1, 2, unquote_splicing(inner), 6])
"[1, 2, 3, 4, 5, 6]"
```
### Usage
The main usage is to inject code inside code.
Unquoting is very useful when working with macros. When writing macros, developers are able to receive code chunks and inject them inside other code chunks, which can be used to transform code or write code that generates code during compilation.

# Macros

- At their core macros are special-case functions designed to `return a quoted expression` that will be inserted into our application code.
- Imagine the macro being replaced with the quoted expression rather than called like a function. 
- With macros we have everything necessary to extend Elixir and dynamically add code to our applications.

## Implement `unless` as a macro 

```elixir
defmodule Unless do
  defmacro macro_unless(expr, do: block) do
    quote do
      if !unquote(expr), do: unquote(block)
    end
  end
end
```

Usage:

```elixir
require Unless
# nil
Unless.macro_unless true, do: "Hi"
# nil
Unless.macro_unless false, do: "Hi"
# "Hi"
```

## debug a macro
let's assume we call a macro inside a module Unless
```elixir
Unless.macro_unless(true, do: IO.puts("this should never be printed"))
```

if we wanna see the final result after injecting code we can use:
```elixir
require Unless

expr = quote do: Unless.macro_unless(true, do: IO.puts("this should never be printed"))

exp |> Macro.expand_once(__ENV__) |> Macro.to_string |> IO.puts

# if(!true) do
#   IO.puts("this should never be printed")
# end
# :ok
```

## Macro hygiene

### access context variable inside macro

Variables inside a quote won't conflict with variables defined in the context where that macro is expanded:

```elixir
defmodule Hygiene do
  defmacro no_interference do
    # This a variable has nothing to do with a in line 146
    quote do: a = 1
  end
end

defmodule HygieneTest do
  def go do
    require Hygiene
    a = 13
    Hygiene.no_interference()
    a
  end
end

HygieneTest.go()
# => 13
```

if we really wanna use the context variable we should use `var!/1`:

```elixir
defmodule Hygiene do
  defmacro interference do
    # now we are using HygieneTest.go's `a` variable
    quote do: var!(a) = 1
  end
end

defmodule HygieneTest do
  def go do
    require Hygiene
    a = 13
    Hygiene.interference()
    a
  end
end

HygieneTest.go()
# => 1
```

### access macro variable inside context

variables defined inside marcos are not accessible after using it, to do so we need to use `Macro.var`

```elixir
defmacro create_variable_x(value) do
  quoted_var = Macro.var(:x, nil)
  quote do
    unquote(quoted_var) = unquote(value)
  end
end

def run_x do
  create_variable_x(9)

  x
end
```

## Tips
- We use unquote if we wanna evaluate the value of a variable defined outside of the quote blocks






