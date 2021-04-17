defmodule PubSubTest.AuctionItemServer do
  @moduledoc """
  This GenServer is for accepting auction item related events and process them
  """
  use GenServer

  require Logger

  alias PubSubTest.PubSub

  def start_link(item_id) do
    GenServer.start_link(__MODULE__, item_id, name: via_tuple(item_id))
  end

  def via_tuple(item_id) do
    {:via, Registry, {PubSubTest.Registy, {:item, item_id}}}
  end

  def init(item_id) do
    send(self(), :after_init)

    {:ok, %{item_id: item_id, started: false}}
  end

  def place_bid(item_id, user_id, amount) do
    GenServer.cast(via_tuple(item_id), {:place_bid, user_id, amount})
  end

  def handle_cast({:place_bid, user_id, _}, %{started: false} = state) do
    # This would be broadcasting message to websocket (using endpoint)
    Phoenix.PubSub.broadcast(PubSub, "user:#{user_id}", {:place_bid, :error, :not_started})
    {:noreply, state}
  end

  def handle_cast({:place_bid, user_id, amount}, %{item_id: id} = state) do
    Logger.debug("[AuctionItem][#{id}] Proccessing placing bid")
    Process.sleep(1500)

    Logger.debug("[AuctionItem][#{id}] Placed bid: #{amount}")

    Phoenix.PubSub.broadcast(PubSub, "user:#{user_id}", {:place_bid, :ok})
    Phoenix.PubSub.broadcast(PubSub, "auction_item:#{id}", {:bid_placed, amount})
    {:noreply, state}
  end

  def handle_info(:start_bidding, %{item_id: id} = state) do
    Logger.debug("[AuctionItem][#{id}] Bidding started")

    {:noreply, %{state | started: true}}
  end

  def handle_info(:after_init, state) do
    # Phoenix.PubSub.subscribe(PubSub, "auction_item:#{id}")

    Phoenix.PubSub.broadcast(PubSub, "user:#{1}", :something)

    :erlang.send_after(20000, self(), :start_bidding)

    {:noreply, state}
  end
end
