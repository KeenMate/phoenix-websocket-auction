defmodule BiddingPoc.AuctionBidderServer do
  use GenServer

  require Logger

  @place_bid_chance 0.7

  def start_link(arg) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init(arg) do
    send(self(), :after_init)

    {:ok, arg}
  end

  @impl true
  def handle_info(:elapsed, state) do
    new_bids =
      state.item_ids
      |> Enum.filter(fn _ -> :random.uniform() < @place_bid_chance end)
      |> Enum.reduce(Map.get(state, :bids, %{}), &place_bid(&1, &2, state.user_id, state.name))

    register_elapse_event()
    {
      :noreply,
      state
      |> Map.put(:bids, new_bids)
    }
  end

  def handle_info(:after_init, state) do
    register_elapse_event()
    {:noreply, state}
  end

  defp place_bid(item_id, bids, user_id, name) do
    log_debug(name, "Placing bid for #{item_id}")

    {new_bid, new_bids} = get_new_bid(item_id, bids)

    BiddingPoc.place_bid(item_id, user_id, new_bid)
    |> case do
      :ok ->
        new_bids
    end
  end

  defp get_new_bid(item_id, bids) do
    last_bid = Map.get(bids, item_id, 100)

    new_bid = trunc(:random.uniform(100) + last_bid)

    {new_bid, Map.put(bids, item_id, new_bid)}
  end

  defp register_elapse_event() do
    delay = trunc(:random.uniform() * 5000)

    :erlang.send_after(delay, self(), :elapsed)
  end

  defp log_debug(name, msg, opts \\ []) do
    Logger.debug("[AuctionBidderServer][#{name}] #{msg}", opts)
  end
end
