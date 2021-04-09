defmodule BiddingPocWeb.BiddingChannel do
  use BiddingPocWeb, :channel

  require Logger

  alias BiddingPoc.Database.{AuctionItem, UserInAuction, ItemBid}
  alias BiddingPocWeb.Presence

  @impl true
  def join("bidding:" <> item_id, _payload, socket) do
    if AuctionItem.member?(item_id) do
      send(self(), :after_join)

      {
        :ok,
        socket
        |> put_item_id(item_id)
      }
    else
      {:error, %{reason: "invalid item_id"}}
    end
  end

  @impl true
  def handle_in("join_bidding", _payload, socket) do
    %{user_id: user_id, item_id: item_id} = socket.assigns

    UserInAuction.add_user_to_auction(user_id, item_id)

    new_socket =
      socket
      |> broadcast_user_joined()
      |> update_presence_user_joined()
      |> put_user_joined(true)

    {:reply, :ok, new_socket}
  end

  def handle_in("place_bid", %{"amount" => amount}, socket) when is_number(amount) do
    %{user_id: user_id, item_id: item_id} = socket.assigns

    AuctionItem.place_bid(item_id, user_id, amount)
    |> case do
      {:ok, _item_bid} ->
        broadcast_placed_bid(socket, user_id, amount)

        {:reply, :ok, socket}

      {:error, _} = error ->
        {:reply, response_from_place_bid_error(error), socket}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", get_item_users(socket))

    Presence.track(socket, socket.assigns.user.id, %{
      id: socket.assigns.user.id,
      username: socket.assigns.user.username,
      joined: socket.assigns.user_joined
    })

    # send data to client
    push(socket, "auction_item", get_auction_item(socket))
    push(socket, "biddings", get_item_biddings(socket))

    {:noreply, socket}
  end

  defp get_item_biddings(socket) do
    socket
    |> get_item_id()
    |> ItemBid.get_item_bids()
  end

  defp get_auction_item(socket) do
    socket
    |> get_item_id()
    |> AuctionItem.get_by_id()
  end

  defp get_item_users(socket) do
    Presence.list(socket)
  end

  defp broadcast_user_joined(socket) do
    broadcast_from(socket, "user_joined", Map.get(socket.assigns, :user))
    socket
  end

  defp broadcast_placed_bid(socket, user_id, amount) do
    broadcast_from(socket, "bid_placed", %{amount: amount, user_id: user_id})
  end

  defp response_from_place_bid_error({:error, :not_found}) do
    error_reason_map("Item not found")
  end

  defp response_from_place_bid_error({:error, :small_bid}) do
    error_reason_map("Insufficient bid entered")
  end

  defp response_from_place_bid_error({:error, :bidding_ended}) do
    error_reason_map("Bidding for this item has ended")
  end

  defp response_from_place_bid_error({:error, :item_postponed}) do
    error_reason_map("Bidding for this item is postponed")
  end

  defp error_reason_map(reason) do
    %{
      reason: reason
    }
  end

  defp update_presence_user_joined(socket) do
    Presence.update(socket, socket.assigns.user.id, fn meta ->
      meta
      |> Map.put(:joined, socket.assigns.user_joined)
    end)

    socket
  end

  defp put_user_joined(socket, value) when is_boolean(value) do
    assign(socket, :user_joined, value)
  end

  defp put_item_id(socket, item_id) do
    assign(socket, :item_id, item_id)
  end

  defp get_item_id(socket) do
    socket
    |> Map.get(:assigns)
    |> Map.get(:item_id)
  end

  # defp get_current_user(socket) do
  #   socket.assigns
  #   |> Map.get(:user_id)
  #   |> User.get_by_id()
  # end
end
