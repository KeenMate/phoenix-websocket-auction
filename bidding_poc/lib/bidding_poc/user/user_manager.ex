defmodule BiddingPoc.UserManager do
  alias BiddingPoc.UserStoreSupervisor
  alias BiddingPoc.UserStoreAgent

  @spec start_user_store(pos_integer()) :: {:ok, pid()} | {:error, any()}
  def start_user_store(user_id) do
    DynamicSupervisor.start_child(UserStoreSupervisor, {UserStoreAgent, %{user_id: user_id}})
  end

  def is_auction_currently_viewed?(user_id, item_id) do
    UserStoreAgent.get_current_auction(user_id) == item_id
  end

  @spec user_store_alive?(pos_integer()) :: boolean()
  def user_store_alive?(user_id) do
    Registry.lookup(Registry.UserStoreRegistry, user_id)
    |> case do
      [] -> false
      [_] -> true
    end
  end
end
