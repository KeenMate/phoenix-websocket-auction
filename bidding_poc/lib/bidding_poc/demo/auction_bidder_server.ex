defmodule BiddingPoc.AuctionBidderServer do
  use GenServer

  require Logger

  alias BiddingPoc.AuctionManager

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
      state.auction_ids
      |> Enum.filter(fn _ -> :random.uniform() < @place_bid_chance end)
      |> Enum.reduce(Map.get(state, :bids, %{}), &place_bid_for_auction(&1, &2, state))

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

  defp place_bid_for_auction(_auction_id, {:error, :process_not_alive} = error, _state) do
    error
  end

  defp place_bid_for_auction(auction_id, bids, state) do
    place_bid(auction_id, bids, state.user_id, state.name)
  end

  defp place_bid(auction_id, bids, user_id, name) do
    log_debug(name, "Placing bid for #{auction_id}")

    {new_bid, new_bids} = get_new_bid(auction_id, bids)

    AuctionManager.place_bid(auction_id, user_id, new_bid)
    |> case do
      :ok ->
        new_bids

      {:error, :process_not_alive} = error ->
        error
    end
  end

  defp get_new_bid(auction_id, bids) do
    last_bid = Map.get(bids, auction_id, 100)

    new_bid = trunc(:random.uniform(100) + last_bid)

    {new_bid, Map.put(bids, auction_id, new_bid)}
  end

  defp register_elapse_event() do
    delay = trunc(:random.uniform() * 5000)

    :erlang.send_after(delay, self(), :elapsed)
  end

  defp log_debug(name, msg, opts \\ []) do
    Logger.debug("[AuctionBidderServer][#{name}] #{msg}", opts)
  end
end
