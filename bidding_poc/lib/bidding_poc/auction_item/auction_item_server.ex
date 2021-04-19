defmodule BiddingPoc.AuctionItemServer do
  @moduledoc """
  This server is used for operations with the auction itself and users
  """
  use GenServer

  require Logger

  alias BiddingPoc.Common
  alias BiddingPoc.Database.{AuctionItem, ItemBid}
  alias BiddingPoc.UserPubSub

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: via_tuple(arg.item_id))
  end

  def via_tuple(item_id) do
    {:via, Registry, {Registry.AuctionItemRegistry, item_id}}
  end

  @impl true
  def init(arg) do
    send(self(), {:after_init, Map.get(arg, :initialy_started, false)})

    {
      :ok,
      %{
        item_id: arg.item_id
      }
    }
  end

  @spec place_bid(pos_integer(), pos_integer(), pos_integer()) :: :ok
  def place_bid(item_id, user_id, amount)
      when is_number(item_id) and is_number(user_id) and is_number(amount) do
    GenServer.cast(via_tuple(item_id), {:place_bid, user_id, amount})
  end

  @impl true
  def handle_cast({:place_bid, user_id, amount}, %{item_id: item_id} = state)
      when is_number(user_id) and is_number(amount) do
    new_state =
      AuctionItem.place_bid(item_id, user_id, amount)
      |> case do
        {:ok, bid} ->
          after_bid_placed(state, user_id, bid)

        {:error, :small_bid} = error ->
          broadcast_bid_placed_error(user_id, error)
          state

        {:error, :not_found} = error ->
          broadcast_bid_placed_error(user_id, error)
          state

        {:error, :bidding_ended} = error ->
          broadcast_bid_placed_error(user_id, error)
          state

        {:error, :item_postponed} = error ->
          broadcast_bid_placed_error(user_id, error)
          state
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:bidding_started, %{item_id: item_id} = state) do
    Phoenix.PubSub.broadcast(AuctionItemPubSub, "auction_item:#{item_id}", :bidding_started)

    {:noreply, state}
  end

  def handle_info({:after_init, initialy_started}, state) do
    state.item_id
    |> AuctionItem.get_by_id()
    |> case do
      {:ok, item} ->
        item
        |> register_bidding_started()
        |> register_bidding_ended()
        |> broadcast_item_added(initialy_started)

        {
          :noreply,
          state
          |> Map.put(:item, item)
        }

      {:error, :not_found} ->
        Logger.error(
          "Attempted to start auction item server with auction item id that was not found in database",
          item_id: inspect(state.item_id)
        )

        {:stop, {:error, :not_found}, state}
    end
  end

  defp after_bid_placed(state, user_id, item_bid) do
    send_user_bid_placed(user_id, item_bid)

    [enhanced_bid] = ItemBid.with_data([item_bid])

    state
    |> broadcast_bid_placed(enhanced_bid)
    |> update_average_bidding(item_bid)

    # TODO: Broadcast avarage bidding to yet to be created channel for "my auctions"
    |> broadcast_bid_average_changed()
  end

  defp send_user_bid_placed(user_id, item_bid) do
    Phoenix.PubSub.broadcast(UserPubSub, "user:#{user_id}", {:bid_placed, item_bid})
  end

  defp broadcast_bid_placed_error(user_id, error) do
    Phoenix.PubSub.broadcast(UserPubSub, "user:#{user_id}", {:bid_place, error})
  end

  defp update_average_bidding(state, item_bid) do
    tmp_state =
      state
      |> Map.update(:bids_count, 1, &(&1 + 1))
      |> Map.update(:bids_sum, item_bid.amount, &(&1 + item_bid.amount))

    tmp_state
    |> Map.put(:bids_average, tmp_state.bids_sum / tmp_state.bids_count)
  end

  defp register_bidding_started(%AuctionItem{} = item) do
    now = DateTime.now!(Common.timezone())
    start = item.bidding_start

    if DateTime.compare(start, now) == :gt do
      :erlang.send_after(DateTime.diff(start, now, :second) * 1000, self(), :bidding_started)
    end

    item
  end

  defp register_bidding_ended(%AuctionItem{} = item) do
    now = DateTime.now!(Common.timezone())
    ended = item.bidding_end

    if DateTime.compare(ended, now) == :gt do
      :erlang.send_after(DateTime.diff(ended, now, :second) * 1000, self(), :bidding_ended)
    end

    item
  end

  defp broadcast_bid_average_changed(state) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      "auctions:lobby",
      {:average_bid, state.bids_average}
    )

    state
  end

  defp broadcast_bid_placed(state, item_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      "bidding:#{state.item_id}",
      {:bid_placed, Map.from_struct(item_bid)}
    )

    state
  end

  defp broadcast_item_added(_, false), do: :ok

  defp broadcast_item_added(item, _) do
    Phoenix.PubSub.broadcast(BiddingPoc.AuctionItemPubSub, "auctions:lobby", {:item_added, item})
  end
end
