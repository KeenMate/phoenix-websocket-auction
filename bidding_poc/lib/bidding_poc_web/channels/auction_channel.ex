defmodule BiddingPocWeb.AuctionChannel do
  use BiddingPocWeb, :channel

  alias BiddingPoc.Database.{AuctionItem, AuctionItemCategory, UserWatchedCategory}

  alias BiddingPoc.AuctionItem, as: AuctionItemContext
  alias BiddingPocWeb.Presence

  intercept ~w(
    auction_started
    auction_ended
    # item_added
    # item_removed
    )

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
    |> AuctionItem.new_item_from_params!()
    |> BiddingPoc.create_auction(user_id)
    |> case do
      {:ok, auction_item} = res ->
        # broadcast_from(socket, "item_added", auction_item)

        {:added, socket_with_new_watched_items} = toggle_watched_item(socket, auction_item.id)

        {:reply, res, socket_with_new_watched_items}

      :error = error ->
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
    user = socket.assigns.user

    if AuctionItem.user_id_authorized?(item_id, user.id) do
      :ok = AuctionItem.delete_item(item_id)

      broadcast_from(socket, "item_removed", item_id)

      {:reply, :ok, socket}
    else
      {:reply, {:error, :forbidden}, socket}
    end
  end

  @impl true
  def handle_out(
        event,
        %AuctionItem{} = item,
        socket
      )
      when event in ~w(item_added item_removed) do
    if user_interested_in_item?(socket, item) do
      push(socket, event, item)
    end

    {:noreply, socket}
  end

  def handle_out(event, %{item_id: item_id} = payload, socket)
      when event in ~w(auction_started auction_ended) do
    new_socket =
      if is_item_watched?(socket, item_id) do
        push(socket, event, payload)

        update_watched_by_event(socket, event, item_id)
      else
        socket
      end

    {:reply, payload, new_socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user.id, %{})

    {:noreply, socket}
  end

  defp update_watched_by_event(socket, "auction_started", _), do: socket

  defp update_watched_by_event(socket, "auction_ended", item_id) do
    {:removed, new_socket} = toggle_watched_item(socket, item_id)
    new_socket
  end

  defp user_interested_in_item?(socket, item) do
    user_id = get_user_id(socket)

    item
    |> Map.get(:category)
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
