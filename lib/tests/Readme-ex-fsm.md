# ExFSM

[Doc](https://github.com/kbrw/exfsm/blob/master/lib/exfsm.ex)

It's a module that define a finite state machine, based on a set of transition functions defined through the keyword `deftrans`

## deftrans

Allows us to define a transition handler

```elixir
defmodule Elixir.Handler do
  import ExFsm

  deftrans initial_state({:transition_event, []}, object) do
    {:next_state, :final_state, object}
  end

end
```

- `initial_state` is the state name
- `:transition_event` is the action name
- `object` is our machine
- `:final_state` is the next state that the fsm is gonna go to giving this action

## defbypass

it match the action whatever the current state and then you can either pass to another state

```elixir
{:next_state, :done, order}
```

or change only the state of the machine

```elixir
defbypass transition_event(_,object), do: {:keep_state, update_object(object)}
```

## fsm output (Handler.fsm)

```elixir
%{
    {state_name, event_name} => {exfsm_module,[dest_statename]}
}
```

# ExFSM.Machine

Is a module to simply use FSMs defined with ExFSM :

## `ExFSM.Machine.fsm/1`

Merge fsm from multiple handlers.

```elixir
defmodule Elixir.Door1 do
  use ExFSM

  deftrans closed({:open_door,_},s) do {:next_state,:opened,s} end
end

defmodule Elixir.Door2 do
  use ExFSM

  defbypass close_door(_,s), do: {:keep_state,Map.put(s,:doubleclosed,true)}

  deftrans opened({:close_door,_},s) do {:next_state,:closed,s} end
end

ExFSM.Machine.fsm([Door1,Door2])
# Output
# %{
#   {:closed,:open_door}=>{Door1,[:opened]},
#   {:opened,:close_door}=>{Door2,[:closed]}
# }
```

## `ExFSM.Machine.event/2`

Allows us to execute the correct handler from a state and action

## Usage

1. Define a structure implementing `ExFSM.Machine.State` in order to define:
   - how to extract handlers
   - how to extract state_name from state
   - how to apply state_name change
2. Then use `ExFSM.Machine.event/2` in order to execute transition.

### Example

```elixir
defmodule Elixir.DoorState do
  defstruct(handlers: [Door1,Door2], state: nil, doubleclosed: false)
end

defimpl ExFSM.Machine.State, for: DoorState do
  def handlers(d) do d.handlers end
  def state_name(d) do d.state end
  def set_state_name(d,name) do %{d|state: name} end
end
```

And now we can execute transitions

```elixir
struct(DoorState, state: :closed) |> ExFSM.Machine.event({:open_door,nil})
# {:next_state,%{__struct__: DoorState, handlers: [Door1,Door2],state: :opened, doubleclosed: false}}

struct(DoorState, state: :closed) |> ExFSM.Machine.event({:close_door,nil})
# {:next_state,%{__struct__: DoorState, handlers: [Door1,Door2],state: :closed, doubleclosed: true}}
```
