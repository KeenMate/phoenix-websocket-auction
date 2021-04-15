defmodule PubSubTest.User do
  use GenServer

  require Logger

  alias PubSubTest.AuctionItemServer

  def start_link(item_id) do
    GenServer.start_link(__MODULE__, item_id, name: __MODULE__)
  end

  def init(item_id) do
    send(self(), :after_init)

    {:ok, item_id}
  end

  def handle_info({:bid_placed, bid}, %{item_id: id} = state) do
    Logger.info("Bid was placed")

    {:noreply, state}
  end

  def handle_info(:place_bid, state) do
    GenServer.cast(AuctionItemServer, {:place_bid, 123})

    {:noreply, state}
  end

  def handle_info(:after_init, %{item_id: id} = state) do
    PubSub.subscribe(AuctionItemPubSub, "auction_item:" <> id)

    :erlang.send_after(1000, self(), :place_bid)

    {:noreply, state}
  end
end