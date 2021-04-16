defmodule PubSubTest.Auctions do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{last_id: 0, items: %{}} end, name: __MODULE__)
  end

  def create_auction(title) do
    Agent.get_and_update(__MODULE__, fn state ->
      id = state.last_id + 1

      new_item = %{id: id, title: title}

      {
        new_item,
        state
        |> Map.put(:last_id, id)
        |> put_in([:items, id], new_item)
      }
    end)
  end
end
