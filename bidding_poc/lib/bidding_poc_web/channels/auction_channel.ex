defmodule BiddingPocWeb.AuctionChannel do
  use BiddingPocWeb, :channel

  alias BiddingPoc.Database.{AuctionItem, AuctionItemCategory, UserWatchedCategory}

  alias BiddingPoc.AuctionItem, as: AuctionItemContext
  alias BiddingPocWeb.Presence

  intercept ~w(
    auction_started
    auction_ended
    item_added
    item_removed
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
    |> AuctionItemContext.create_auction_item(user_id)
    |> case do
      {:ok, auction_item} ->
        broadcast_from(socket, "item_added", auction_item)

        new_watched_items =
          socket
          |> get_socket_watched_items()
          |> toggle_watched_item(auction_item.id)

        socket_with_new_watched_items = assign_watched_items(socket, new_watched_items)

        {:reply, {:ok, auction_item}, socket_with_new_watched_items}

      {:error, :id_filled} = error ->
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
    if is_interesting_item?(item, get_user_id(socket)) do
      push(socket, event, item)
    end

    {:noreply, socket}
  end

  def handle_out(event, %{item_id: item_id} = payload, socket)
      when event in ~w(auction_started auction_ended) do
    watched = get_socket_watched_items(socket)

    new_watched =
      if is_item_watched?(watched, item_id) do
        push(socket, event, payload)

        update_watched_if_auction_ended(event, watched, item_id)
      else
        watched
      end

    {:noreply, assign_watched_items(socket, new_watched)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user.id, %{})

    {:noreply, socket}
  end

  defp update_watched_if_auction_ended("auction_started", watched, _), do: watched

  defp update_watched_if_auction_ended("auction_ended", watched, item_id) do
    {:removed, new_watched} = toggle_watched_item(watched, item_id)
    new_watched
  end

  defp assign_watched_items(socket, watched) do
    assign(socket, :watched_item_ids, watched)
  end

  defp is_interesting_item?(item, user_id) do
    item
    |> Map.get(:category)
    |> UserWatchedCategory.category_watched_by_user?(user_id)
  end

  defp is_item_watched?(watched, item_id) do
    Enum.member?(watched, item_id)
  end

  defp toggle_watched_item(watched, item_id) do
    if Enum.member?(watched, item_id) do
      {:removed, Enum.filter(watched, &(&1 != item_id))}
    else
      {:added, [item_id | watched]}
    end
  end

  defp get_socket_watched_items(socket) do
    socket
    |> Map.get(:assigns, %{})
    |> Map.get(:watched_item_ids, [])
  end

  defp get_user_id(%{assigns: %{user: %{id: user_id}}}), do: user_id
end
