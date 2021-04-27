defmodule BiddingPocWeb.AuctionsChannel do
  use BiddingPocWeb, :channel

  require Logger

  alias BiddingPoc.Database.{AuctionItem, AuctionItemCategory, UserWatchedCategory, UserInAuction}

  alias BiddingPoc.AuctionItem, as: AuctionItemContext
  alias BiddingPoc.{AuctionManager, UserManager}
  alias BiddingPoc.AuctionPublisher

  @impl true
  def join("auction:lobby", _payload, socket) do
    send(self(), :after_join)

    {
      :ok,
      socket
    }
  end

  @impl true
  def handle_in("create_auction", auction_item_params, socket) do
    user_id = socket.assigns.user.id

    auction_item_params
    |> AuctionManager.create_auction(user_id)
    |> case do
      {:ok, auction_item} = res ->
        # broadcast_from(socket, "item_added", auction_item)

        UserInAuction.add_user_to_auction(auction_item.id, user_id, false)

        {:reply, res, socket}

      {:error, _} = error ->
        {:reply, error, socket}
    end
  end

  def handle_in("delete_auction", %{"auction_id" => auction_id}, socket) do
    auction_id
    |> AuctionManager.remove_auction(get_user_id(socket))
    |> case do
      {:ok, _deleted_item} ->
        {:reply, :ok, socket}

      {:error, reason} = error when reason in [:forbidden, :not_found, :user_not_found] ->
        {:reply, error, socket}
    end
  end

  def handle_in("get_auction_items", params, socket) do
    items = AuctionItemContext.get_auction_items(params)

    {:reply, {:ok, items}, socket}
  end

  def handle_in("get_auction_categories", _payload, socket) do
    {:reply, {:ok, AuctionItemCategory.get_categories()}, socket}
  end

  @impl true
  def handle_info({:item_added, %AuctionItem{} = auction_item}, socket) do
    if user_interested_in_auction_item?(socket, auction_item) do
      push(socket, "item_added", auction_item)
    end

    {:noreply, socket}
  end

  def handle_info({:item_removed, %AuctionItem{} = auction_item}, socket) do
    if user_interested_in_auction_item?(socket, auction_item) do
      push(socket, "item_removed", auction_item)
    end

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
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
