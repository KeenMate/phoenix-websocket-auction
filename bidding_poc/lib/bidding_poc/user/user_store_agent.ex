defmodule BiddingPoc.UserStoreAgent do
  use Agent

  def start_link(arg) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    Agent.start_link(fn -> arg end, name: via_tuple(arg.user_id))
  end

  def via_tuple(user_id) do
    {:via, Registry, {Registry.UserStoreRegistry, user_id}}
  end

  def get_current_auction(user_id) do
    user_id
    |> via_tuple()
    |> Agent.get(&Map.get(&1, :current_auction))
  end

  def set_current_auction(user_id, item_id) do
    user_id
    |> via_tuple()
    |> Agent.update(&Map.put(&1, :current_auction, item_id))
  end

  def clear_current_auction(user_id) do
    set_current_auction(user_id, nil)
  end
end
