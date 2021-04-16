defmodule PubSubTest.User do
  @moduledoc """
  This GenServer acts as a WebSocket channel
  """

  use GenServer

  require Logger

  alias PubSubTest.{AuctionItemServer, PubSub}

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: via_tuple(arg.user_id))
  end

  def via_tuple(user_id) do
    {:via, Registry, {PubSubTest.Registy, {:user, user_id}}}
  end

  def init(arg) do
    send(self(), :after_init)

    {:ok, arg}
  end

  def place_bid(user_id, amount) do
    GenServer.cast(via_tuple(user_id), {:place_bid, amount})
  end

  def handle_cast({:place_bid, amount}, state) do
    AuctionItemServer.place_bid(state.item_id, state.user_id, amount)

    {:noreply, state}
  end

  def handle_info({:place_bid, :ok}, %{user_id: id, item_id: item_id} = state) do
    Logger.debug("[User][#{id}] Bid successfully placed for item: #{item_id}")

    {:noreply, state}
  end

  def handle_info({:place_bid, :error, :not_started}, %{user_id: id, item_id: item_id} = state) do
    Logger.debug("[User][#{id}] Bid was not placed for item: #{item_id}")

    {:noreply, state}
  end

  def handle_info({:bid_placed, bid}, %{user_id: id, item_id: item_id} = state) do
    Logger.debug("[User][#{id}] Bid was placed: #{bid} for item: #{item_id}")

    {:noreply, state}
  end

  def handle_info(:after_init, %{user_id: id, item_id: item_id} = state) do
    Phoenix.PubSub.subscribe(PubSub, "user:#{id}")
    Phoenix.PubSub.subscribe(PubSub, "auction_item:#{item_id}")

    {:noreply, state}
  end
end
