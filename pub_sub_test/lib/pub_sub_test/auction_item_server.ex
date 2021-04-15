defmodule PubSubTest.AuctionItemServer do
  use GenServer

  alias Phoenix.PubSub
  alias PubSubTest.AuctionItemPubSub

  def start_link(item_id) do
    GenServer.start_link(__MODULE__, item_id, name: __MODULE__)
  end

  def init(item_id) do
    send(self(), :after_init)

    {:ok, item_id}
  end

  def handle_cast({:place_bid, bid}, %{item_id: id} = state) do
    Process.sleep(1500)
    PubSub.broadcast(AuctionItemPubSub, "auction_item:" <> id, {:bid_placed, bid})
    {:noreply, state}
  end

  def handle_info(:after_init, %{item_id: id} = state) do
    PubSub.subscribe(AuctionItemPubSub, "auction_item:" <> id)

    {:noreply, state}
  end
end