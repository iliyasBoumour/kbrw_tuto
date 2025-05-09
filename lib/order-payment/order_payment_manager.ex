defmodule OrderPaymentManager do
  alias OrderPaymentProcessesTable, as: Table

  @payment_steps [
    init: {:next_action, :process_payment},
    processing: {:next_action, :payment_success},
    done: {:next_action, :no_action}
  ]

  def pay(order) do
    action = get_next_action(order)

    get_pid_for_order(order)
    |> GenServer.call(action)
  end

  def delete_process_for_order(order) do
    order |> payment_process_name() |> Table.delete()
  end

  defp get_next_action(order) do
    current_state = String.to_atom(order["status"]["state"])

    case Keyword.fetch(@payment_steps, current_state) do
      :error -> :init_payment
      {:ok, {:next_action, action}} -> action
    end
  end

  def get_pid_for_order(order) do
    server_name = payment_process_name(order)

    pid_from_table = Table.read(server_name)

    case pid_from_table do
      nil ->
        start_new_payment_process(server_name, order)

      _ ->
        if Process.alive?(pid_from_table),
          do: pid_from_table,
          else: start_new_payment_process(server_name, order)
    end
  end

  defp payment_process_name(order), do: String.to_atom("OrderPayment_" <> order["id"])

  defp start_new_payment_process(server_name, order) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        Formation.DynamicSupervisor,
        OrderPaymentProcess.child_spec(order)
      )

    Table.create({server_name, pid})
    pid
  end
end
