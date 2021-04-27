defmodule BiddingPoc.NotificationHubServer do
  use GenServer

  alias BiddingPoc.AuctionPublisher

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

  # TODO: handle auctions events (process them using tasks)

  @impl true
  def handle_info(:after_init, state) do
    AuctionPublisher.subscribe_auctions_topic()

    {:noreply, state}
  end
end
