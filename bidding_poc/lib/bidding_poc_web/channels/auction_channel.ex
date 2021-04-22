defmodule BiddingPocWeb.AuctionChannel do
  use BiddingPocWeb, :channel

  require Logger

  alias BiddingPoc.Database.{AuctionItem, AuctionItemCategory, UserWatchedCategory}

  alias BiddingPoc.AuctionItem, as: AuctionItemContext
  alias BiddingPoc.AuctionManager
  alias BiddingPoc.AuctionPublisher
  alias BiddingPocWeb.Presence

  @impl true
  def join("auction:lobby", _payload, socket) do
    send(self(), :after_join)

    {
      :ok,
      socket
      |> assign_watched_items([])
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

        {:added, socket_with_new_watched_items} = toggle_watched_item(socket, auction_item.id)

        {:reply, res, socket_with_new_watched_items}

      {:error, _} = error ->
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

  def handle_in("toggle_watch_item", %{"item_id" => item_id}, socket) do
    {operation, new_watched_ids} =
      socket
      |> get_socket_watched_items()
      |> toggle_watched_item(item_id)

    {
      :reply,
      operation,
      assign_watched_items(socket, new_watched_ids)
    }
  end

  def handle_in("delete_auction", %{"item_id" => item_id}, socket) do
    item_id
    |> AuctionManager.remove_auction(get_user_id(socket))
    |> case do
      {:ok, _deleted_item} ->
        {:reply, :ok, socket}

      {:error, reason} = error when reason in [:forbidden, :not_found, :user_not_found] ->
        {:reply, error, socket}
    end
  end

  @impl true
  def handle_info({:item_added, %AuctionItem{} = item}, socket) do
    if user_interested_in_item?(socket, item) do
      push(socket, "item_added", item)
    end

    {:noreply, socket}
  end

  def handle_info({:item_removed, %AuctionItem{} = item}, socket) do
    Logger.debug("Item removed")
    if user_interested_in_item?(socket, item) do
      push(socket, "item_removed", item)
    end

    {:noreply, socket}
  end

  def handle_info({:bidding_started, %AuctionItem{} = item}, socket) do
    if is_item_watched?(socket, item.id) do
      push(socket, "bidding_started", item)
    end

    {:noreply, socket}
  end

  def handle_info({:bidding_ended, %AuctionItem{} = item}, socket) do
    if is_item_watched?(socket, item.id) do
      push(socket, "bidding_ended", item)
    end

    {:noreply, socket}
  end

  def handle_info({:average_bid, _}, socket) do
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user.id, %{})

    AuctionPublisher.subscribe_auctions_lobby()

    {:noreply, socket}
  end

  defp user_interested_in_item?(socket, item) do
    user_id = get_user_id(socket)

    is_item_watched?(socket, item.id) ||
      item
      |> Map.get(:category_id)
      |> UserWatchedCategory.category_watched_by_user?(user_id)
  end

  defp is_item_watched?(socket, item_id) do
    socket
    |> get_socket_watched_items()
    |> Enum.member?(item_id)
  end

  defp toggle_watched_item(socket, item_id) do
    watched = get_socket_watched_items(socket)

    if Enum.member?(watched, item_id) do
      filtered = Enum.filter(watched, &(&1 != item_id))

      {:removed, assign_watched_items(socket, filtered)}
    else
      {:added, assign_watched_items(socket, [item_id | watched])}
    end
  end

  defp get_socket_watched_items(socket) do
    socket
    |> Map.get(:assigns, %{})
    |> Map.get(:watched_item_ids, [])
  end

  defp assign_watched_items(socket, watched) do
    assign(socket, :watched_item_ids, watched)
  end

  defp get_user_id(%{assigns: %{user: %{id: user_id}}}), do: user_id
end
