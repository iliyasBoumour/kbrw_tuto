defmodule ErrorRouter do
  use Ewebmachine.Builder.Resources
  resources_plugs()

  resource "/error/:status" do
    %{status: elem(Integer.parse(status), 0)}
  after
    plug(ApiCommon)

    finish_request(do: {:halt, state.status})
  end
end
