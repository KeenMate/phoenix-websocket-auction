defmodule BiddingPocWeb.BiddingChannel do
  use BiddingPocWeb, :channel

  require Logger

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.Database.{AuctionItem, AuctionBid}
  alias BiddingPoc.AuctionManager
  alias BiddingPoc.AuctionPublisher

  @impl true
  def join("bidding:" <> auction_id, _payload, socket) do
    auction_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, :invalid_auction_id}

      {parsed_auction_id, _} ->
        parsed_auction_id
        |> AuctionItem.member?()
        |> if do
          send(self(), :after_join)

          {
            :ok,
            put_auction_id(socket, parsed_auction_id)
          }
        else
          {:error, :not_found}
        end
    end
  end

  @impl true
  def handle_in("place_bid", %{"amount" => amount}, socket) when is_number(amount) do
    auction_id = get_auction_id(socket)
    user_id = get_user_id(socket)

    AuctionManager.place_bid(auction_id, user_id, amount)
    |> case do
      :ok ->
        {:reply, :ok, socket}

      {:error, :process_not_alive} = error ->
        {:reply, error, socket}
    end
  end

  def handle_in("get_bids", _payload, socket) do
    auction_bids =
      socket
      |> get_auction_id()
      |> AuctionBid.get_auction_bids()
      |> AuctionBid.with_data()
      |> Enum.map(&Map.from_struct/1)

    {:reply, {:ok, auction_bids}, socket}
  end

  @impl true
  def handle_info({:bid_placed, auction_bid}, socket) do
    push(socket, "bid_placed", Map.from_struct(auction_bid))

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    subscribe_to_auction_item_pubsub(socket)

    {:noreply, socket}
  end

  defp subscribe_to_auction_item_pubsub(socket) do
    socket
    |> get_auction_id()
    |> AuctionPublisher.subscribe_auction_bidding_topic()

    socket
  end
end
