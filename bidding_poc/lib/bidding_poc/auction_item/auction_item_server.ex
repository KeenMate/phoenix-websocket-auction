defmodule BiddingPoc.AuctionItemServer do
  @moduledoc """
  This server is used for operations with the auction itself and users
  """
  use GenServer

  require Logger

  alias BiddingPoc.Common
  alias BiddingPoc.Database.{AuctionItem, AuctionBid}
  alias BiddingPoc.AuctionPublisher
  alias BiddingPoc.UserPublisher

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: via_tuple(arg.auction_id))
  end

  def via_tuple(auction_id) do
    {:via, Registry, {Registry.AuctionItemRegistry, auction_id}}
  end

  @impl true
  def init(arg) do
    send(self(), {:after_init, Map.get(arg, :initialy_started, false)})

    {
      :ok,
      %{
        auction_id: arg.auction_id
      }
    }
  end

  @spec place_bid(pos_integer(), pos_integer() | atom(), pos_integer()) :: :ok
  def place_bid(auction_id, user_id, amount)
      when is_number(auction_id) and (is_atom(user_id) or is_number(user_id)) and is_number(amount) do
    GenServer.cast(via_tuple(auction_id), {:place_bid, user_id, amount})
  end

  @impl true
  def handle_cast({:place_bid, user_id, amount}, %{auction_id: auction_id} = state) do
    new_state =
      AuctionItem.place_bid(auction_id, user_id, amount)
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

        {:error, :auction_postponed} = error ->
          broadcast_bid_placed_error(user_id, error)
          state
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:bidding_started, %{auction: auction} = state) do
    place_bid(auction.id, :initial_bid, auction.start_price)
    AuctionPublisher.broadcast_bidding_started(auction.id)

    {:noreply, state}
  end

  def handle_info(:bidding_ended, %{auction: auction} = state) do
    AuctionPublisher.broadcast_bidding_ended(auction.id)
    {:noreply, state}
  end

  def handle_info({:after_init, initialy_started}, state) do
    state.auction_id
    |> AuctionItem.get_by_id()
    |> case do
      {:ok, auction} ->
        auction
        |> register_bidding_started(initialy_started)
        |> register_bidding_ended()
        |> broadcast_auction_created(initialy_started)

        {
          :noreply,
          state
          |> Map.put(:auction, auction)
        }

      {:error, :not_found} ->
        Logger.error(
          "Attempted to start auction item server with auction item id that was not found in database",
          auction_id: inspect(state.auction_id)
        )

        {:stop, {:error, :not_found}, state}
    end
  end

  defp after_bid_placed(state, user_id, auction_bid) do
    send_user_bid_placed(user_id, auction_bid)

    [enhanced_bid] = AuctionBid.with_data([auction_bid])

    broadcast_bid_placed(enhanced_bid)
    update_average_bidding(state, auction_bid)

    # TODO: Broadcast avarage bidding to yet to be created channel for "my auctions"
    |> broadcast_bid_average_changed()
  end

  defp send_user_bid_placed(user_id, auction_bid) do
    UserPublisher.send_bid_placed_success(user_id, auction_bid)
  end

  defp broadcast_bid_placed_error(user_id, error) do
    UserPublisher.send_place_bid_error(user_id, error)
  end

  defp update_average_bidding(state, auction_bid) do
    tmp_state =
      state
      |> Map.update(:bids_count, 1, &(&1 + 1))
      |> Map.update(:bids_sum, auction_bid.amount, &(&1 + auction_bid.amount))

    tmp_state
    |> Map.put(:bids_average, tmp_state.bids_sum / tmp_state.bids_count)
  end

  defp register_bidding_started(%AuctionItem{} = auction, initialy_started) do
    Logger.debug("[PES]: Registering bidding started reminder. process: #{inspect(self())}")

    now = DateTime.now!(Common.timezone())
    start = auction.bidding_start

    cond do
      DateTime.compare(start, now) == :gt ->
        :erlang.send_after(DateTime.diff(start, now, :millisecond), self(), :bidding_started)

      initialy_started ->
        send(self(), :bidding_started)

      true -> nil
    end

    auction
  end

  defp register_bidding_ended(%AuctionItem{} = auction) do
    now = DateTime.now!(Common.timezone())
    ended = auction.bidding_end

    if DateTime.compare(ended, now) == :gt do
      :erlang.send_after(DateTime.diff(ended, now, :millisecond), self(), :bidding_ended)
    end

    auction
  end

  defp broadcast_bid_average_changed(state) do
    AuctionPublisher.broadcast_auction_average_bid_changed(state.bids_average, state.auction_id)

    state
  end

  defp broadcast_bid_placed(auction_bid) do
    AuctionPublisher.broadcast_bid_placed(auction_bid)
  end

  defp broadcast_auction_created(_, false), do: :ok

  defp broadcast_auction_created(auction, _) do
    AuctionPublisher.broadcast_auction_created(auction)
  end
end
