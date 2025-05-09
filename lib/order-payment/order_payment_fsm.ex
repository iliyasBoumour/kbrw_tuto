defmodule OrderPaymentFsm do
  use ExFSM

  deftrans init({:process_payment, []}, order) do
    {:next_state, :processing, order}
  end

  deftrans processing({:payment_success, []}, order) do
    {:next_state, :done, order}
  end

  defbypass init_payment(_, order) do
    {:next_state, :init, order}
  end

  defbypass no_action(_, order) do
    {:keep_state, order}
  end

  defimpl ExFSM.Machine.State, for: Map do
    def state_name(order), do: String.to_atom(order["status"]["state"])

    def set_state_name(order, name),
      do: put_in(order, ["status", "state"], Atom.to_string(name))

    def handlers(_order), do: [OrderPaymentFsm]
  end
end
