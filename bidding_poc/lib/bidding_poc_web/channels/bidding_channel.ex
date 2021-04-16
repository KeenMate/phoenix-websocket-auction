defmodule BiddingPocWeb.BiddingChannel do
  use BiddingPocWeb, :channel

  require Logger

  alias BiddingPoc.Database.{AuctionItem, UserInAuction, ItemBid}
  alias BiddingPoc.AuctionItem, as: AuctionItemCtx
  alias BiddingPoc.AuctionItemPubSub
  alias BiddingPocWeb.Presence

  @impl true
  def join("bidding:" <> item_id, _payload, socket) do
    item_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, %{reason: "invalid item_id"}}

      {parsed_item_id, _} ->
        parsed_item_id
        |> AuctionItem.member?()
        |> if do
          send(self(), :after_join)

          socket_with_item_id = put_item_id(socket, parsed_item_id)
          {
            :ok,
            socket_with_item_id
            |> put_user_joined(user_joined?(socket_with_item_id))
          }
        else
          {:error, %{reason: "invalid item_id"}}
        end
    end
  end

  @impl true
  def handle_in("join_bidding", _payload, socket) do
    item_id = get_item_id(socket)
    user_id = get_user_id(socket)

    UserInAuction.add_user_to_auction(user_id, item_id)

    new_socket =
      socket
      |> broadcast_user_joined()
      |> update_presence_user_joined()
      |> put_user_joined(true)

    {:reply, :ok, new_socket}
  end

  def handle_in("place_bid", %{"amount" => amount}, socket) when is_number(amount) do
    item_id = get_item_id(socket)
    user_id = get_user_id(socket)

    AuctionItemCtx.place_bid(item_id, user_id, amount)
    |> case do
      :ok ->
        {:reply, :ok, socket}
      {:error, :process_not_alive} ->
        {:reply, :error, socket}
    end

    # item_id = get_item_id(socket)
    # user_id = get_user_id(socket)

    # item_id
    # |> AuctionItem.place_bid(user_id, amount)
    # |> case do
    #   {:ok, item_bid} ->
    #     [bid_with_data] = ItemBid.with_data([item_bid])
    #     bid_with_data = Map.from_struct(bid_with_data)

    #     broadcast_placed_bid(socket, bid_with_data)

    #     {:reply, {:ok, bid_with_data}, socket}

    #   {:error, reason} ->
    #     {:reply, {:error, response_from_place_bid_error(reason)}, socket}
    # end
  end

  @impl true
  def handle_info({:bid_placed, item_bid_id}, socket) do
    push(socket, "place_bid_success", item_bid_id)

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    setup_presence(socket)

    # send init data to client
    socket
    |> push_auction_item()
    |> push_auction_item_biddings()
    |> subscribe_to_auction_item_pubsub()

    {:noreply, socket}
  end

  defp subscribe_to_auction_item_pubsub(socket) do
    Phoenix.PubSub.subscribe(AuctionItemPubSub, "bidding:#{get_item_id(socket)}")
    socket
  end

  defp setup_presence(socket) do
    user_id = get_user_id(socket)

    push(socket, "presence_state", get_item_users(socket))

    Presence.track(socket, user_id, %{
      id: user_id,
      username: socket.assigns.user.username,
      user_joined: socket.assigns.user_joined
    })
  end

  defp push_auction_item(socket) do
    socket
    |> get_item_id()
    |> AuctionItem.with_data()
    |> case do
      {:ok, %AuctionItem{} = item_with_data} ->
        updated_item_with_data =
          item_with_data
          |> Map.put(:user_joined, user_joined?(socket))

        push(socket, "auction_item", Map.from_struct(updated_item_with_data))
      {:error, reason} when reason in [:item_not_found, :user_not_found, :category_not_found] ->
        Logger.error("Unexpected error occured while loading auction item that has an active ws channel")
    end

    socket
  end

  defp push_auction_item_biddings(socket) do
    biddings =
      socket
      |> get_item_biddings()
      |> ItemBid.with_data()
      |> Enum.map(&Map.from_struct/1)

    push(socket, "biddings", %{biddings: biddings})
    socket
  end

  defp get_item_biddings(socket) do
    socket
    |> get_item_id()
    |> ItemBid.get_item_bids()
  end

  defp get_item_users(socket) do
    Presence.list(socket)
  end

  defp broadcast_user_joined(socket) do
    broadcast_from(socket, "user_joined", Map.get(socket.assigns, :user))
    socket
  end

  # defp broadcast_placed_bid(socket, bid) do
  #   broadcast_from(socket, "bid_placed", bid)
  # end

  # defp response_from_place_bid_error(:not_found) do
  #   error_reason_map("Item not found")
  # end

  defp response_from_place_bid_error(:small_bid) do
    error_reason_map("Insufficient bid entered")
  end

  defp response_from_place_bid_error(:bidding_ended) do
    error_reason_map("Bidding for this item has ended")
  end

  defp response_from_place_bid_error(:item_postponed) do
    error_reason_map("Bidding for this item is postponed")
  end

  defp error_reason_map(reason) do
    %{
      reason: reason
    }
  end

  defp user_joined?(socket) do
    UserInAuction.user_in_auction?(get_item_id(socket), get_user_id(socket))
  end

  defp update_presence_user_joined(socket) do
    Presence.update(socket, get_user_id(socket), fn meta ->
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

  defp get_user_id(socket) do
    socket
    |> Map.get(:assigns)
    |> Map.get(:user, %{})
    |> Map.get(:id)
  end

  # defp get_current_user(socket) do
  #   socket.assigns
  #   |> Map.get(:user_id)
  #   |> User.get_by_id()
  # end
end
