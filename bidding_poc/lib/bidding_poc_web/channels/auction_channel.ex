defmodule BiddingPocWeb.AuctionChannel do
  use BiddingPocWeb, :channel

  require Logger

  alias BiddingPoc.Database.{AuctionItem, AuctionItemCategory, UserWatchedCategory, UserInAuction}

  alias BiddingPoc.AuctionItem, as: AuctionItemContext
  alias BiddingPoc.{AuctionManager, UserManager}
  alias BiddingPoc.AuctionPublisher
  alias BiddingPocWeb.Presence

  @impl true
  def join("auction:" <> item_id, _payload, socket) do
    send(self(), :after_join)

    {
      :ok,
      socket
    }
  end

  @impl true
  def handle_in("join_bidding", _payload, socket) do
    {:noreply, socket}
  end

  def handle_in("leave_bidding", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:bidding_started, %AuctionItem{} = auction_item}, socket) do
    Logger.debug("[PES]: Catched bidding started")

    if user_interested_in_auction_item?(socket, auction_item) do
      push(socket, "bidding_started", auction_item)
    end

    {:noreply, socket}
  end

  def handle_info({:bidding_ended, %AuctionItem{} = auction_item}, socket) do
    if user_interested_in_auction_item?(socket, auction_item) do
      push(socket, "bidding_ended", auction_item)
    end

    {:noreply, socket}
  end

  def handle_info({:average_bid, _}, socket) do
    # TODO: send average bid
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user.id, %{})

    AuctionPublisher.subscribe_auctions_topic()

    {:noreply, socket}
  end

  @impl true
  def terminate(reason, _socket) do
    Logger.debug("Terminating, #{inspect(reason)}")
    :ok
  end

  defp user_interested_in_auction_item?(socket, auction_item) do
    user_id = get_user_id(socket)

    UserManager.is_auction_currently_viewed?(user_id, auction_item.id) ||
      category_watched_by_user?(user_id, auction_item) ||
      UserInAuction.user_in_auction?(auction_item.id, user_id)
  end

  defp category_watched_by_user?(user_id, auction_item) do
    auction_item
    |> Map.get(:category_id)
    |> UserWatchedCategory.category_watched_by_user?(user_id)
  end

  defp get_user_id(%{assigns: %{user: %{id: user_id}}}), do: user_id
end
