# alias, require, import, and use

All of those are `lexically scoped`, which means if they are defined in a module they would be available for all the module, and if they are defined in a function they would be available only inside it.

## alias
Allows you to set up aliases for any given module name.

```elixir
defmodule Stats do
  alias Math.List, as: List
  # We can now access Math.List using List
  # The original List can still be accessed within Stats by the fully-qualified name Elixir.List.
end
```

Calling alias without an `:as` option sets the alias automatically to the last part of the module name:

```elixir
alias Math.List, as: List
# is equivalent to
alias Math.List
```

## require
- Used to access only macros
- Public functions in modules are globally available, but in order to use macros, you need to require the module they are defined in.

```elixir
Integer.is_odd(3)
# (UndefinedFunctionError) function Integer.is_odd/1 is undefined or private. However, there is a macro with the same name and arity. Be sure to require Integer if you intend to invoke this macro

require Integer
#Integer

Integer.is_odd(3)
true
```

## import
- used to access macros and functions without using MaduleName.

```elixir
import List, only: [duplicate: 2]
#List
duplicate(:ok, 3)
#[:ok, :ok, :ok]
```

## use 
Behind the scenes, use requires the given module and then calls the `__using__/1` callback on it allowing the module to inject some code into the current context.

```elixir
defmodule Example do
  use Feature, option: :value
end
```
Is equivalent to this

```elixir
defmodule Example do
  require Feature
  Feature.__using__(option: :value)
end
```

# Module attributes
Module attributes in Elixir serve three purposes:
- as module and function annotations
- as temporary module storage to be used during compilation
- as compile-time constants

## As annotations
Elixir has a handful of reserved attributes. Here are a few of them, the most commonly used ones:
- `@moduledoc`: provides documentation for the current module.
- `@doc`: provides documentation for the function or macro that follows the attribute.
- `@spec`: provides a typespec for the function that follows the attribute.
- `@behaviour`: used for specifying an OTP or user-defined behaviour.

### For documentation
```elixir
defmodule Math do
  @moduledoc """
  Provides math-related functions.
  """

  @doc """
  Calculates the sum of two numbers.
  """
  @spec sum(float(), float()) :: float()
  def sum(a, b), do: a + b
end
```

## An temporary storage
we can achieve this by using `@some_name`

```elixir
defmodule MyServer do
  @some_name URI.parse("https://example.com")

  IO.inspect(@some_name)
end
```


# Bahaviour
- Is an interface
- A behaviour module defines a set of functions and macros (referred to as callbacks) that callback modules implementing that behaviour must export. This `interface` identifies the specific part of the component.
- If we use a behaviour but don't to implement all of the required functions, a compile time warning will be raised.

## Defining a behaviour

```elixir
defmodule MyBehaviour do
  @callback init(state :: term) :: {:ok, new_state :: term} | {:error, reason :: term}
  @callback perform(args :: term, state :: term) ::
              {:ok, result :: term, new_state :: term}
              | {:error, reason :: term, new_state :: term}
end
```

- Here we’ve defined `init/1` as accepting any value and returning a tuple of either `{:ok, state}` or `{:error, reason}`
- A `perform/2` function will receive some arguments and a state, and it will return `{:ok, result, state}` or `{:error, reason, state}`

## Using behaviours

```elixir
defmodule Compressor do
  @behaviour MyBehaviour

  def init(opts), do: {:ok, opts}

  def perform(payload, opts) do
    payload
    |> compress
    |> respond(opts)
  end

  defp compress({name, files}), do: :zip.create(name, files)

  defp respond({:ok, path}, opts), do: {:ok, path, opts}
  defp respond({:error, reason}, opts), do: {:error, reason, opts}
end
```

# Protocols
- Protocols are a means of achieving polymorphism in Elixir.
- Allows us to execute a function dynamically based on the value’s type. 

## Implementing a Protocol

Elixir has a lot of built in Protocols, for example the String.Chars protocol is responsible for the to_string/1 function

```elixir
to_string(5)
# "5"
to_string(12.4)
# "12.4"
to_string("foo")
# "foo"
```

But 

`to_string({:foo})` give us a protocol error:
`(Protocol.UndefinedError) protocol String.Chars not implemented for {:foo}`

so let’s create an implementation of it. We use `defimpl` with our protocol, and provide the :for option, and our type. Let’s take a look at how it might look:

```elixir
defimpl String.Chars, for: Tuple do
  def to_string(tuple) do
    interior =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end
```

## Create a Protocol

```elixir
defprotocol Utility do
  @spec type(t) :: String.t()
  def type(value)
end

defimpl Utility, for: BitString do
  def type(_value), do: "string"
end

defimpl Utility, for: Integer do
  def type(_value), do: "integer"
end
```

## use it
```
import AsAtom
```