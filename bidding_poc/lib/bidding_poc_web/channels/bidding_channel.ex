defmodule BiddingPocWeb.BiddingChannel do
  use BiddingPocWeb, :channel

  require Logger

  alias BiddingPoc.Database.{AuctionItem, UserInAuction, ItemBid}
  alias BiddingPoc.AuctionManager
  alias BiddingPoc.AuctionPublisher
  alias BiddingPoc.UserStoreAgent
  alias BiddingPocWeb.Presence

  @impl true
  def join("bidding:" <> item_id, _payload, socket) do
    item_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, :invalid_item_id}

      {parsed_item_id, _} ->
        parsed_item_id
        |> AuctionItem.member?()
        |> if do
          send(self(), :after_join)

          socket_with_item_id = put_item_id(socket, parsed_item_id)

          {
            :ok,
            socket_with_item_id
            |> put_user_status(get_user_status(socket_with_item_id))
          }
        else
          # %{reason: "invalid item_id"}
          {:error, :not_found}
        end
    end
  end

  @impl true
  def handle_in("join_bidding", _payload, socket) do
    item_id = get_item_id(socket)
    user_id = get_user_id(socket)

    UserInAuction.add_user_to_auction(item_id, user_id)

    new_socket =
      socket
      |> put_user_status(:joined)
      |> update_presence_user_status()

    {:reply, :ok, new_socket}
  end

  def handle_in("leave_bidding", _payload, socket) do
    item_id = get_item_id(socket)
    user_id = get_user_id(socket)

    UserInAuction.remove_user_from_auction(item_id, user_id)
    |> case do
      {:error, :not_found} = error ->
        {:reply, error, socket}

      {:error, :already_bidded} = error ->
        {:reply, error, socket}

      {:ok, :removed} = result ->
        new_socket =
          socket
          |> put_user_status(:nothing)
          |> update_presence_user_status()

        {:reply, result, new_socket}

      {:ok, :bidding_left} = result ->
        new_socket =
          socket
          |> put_user_status(:watching)
          |> update_presence_user_status()

        {:reply, result, new_socket}
    end
  end

  def handle_in("toggle_watch", _payload, socket) do
    UserInAuction.toggle_watched_auction(get_item_id(socket), get_user_id(socket))
    |> case do
      {:error, :joined} = error ->
        {:reply, error, socket}

      {:ok, :watching} = res ->
        new_socket =
          socket
          |> put_user_status(:watching)
          |> update_presence_user_status()

        {:reply, res, new_socket}

      {:ok, :not_watching} = res ->
        new_socket =
          socket
          |> put_user_status(:nothing)
          |> update_presence_user_status()

        {:reply, res, new_socket}
    end
  end

  def handle_in("place_bid", %{"amount" => amount}, socket) when is_number(amount) do
    item_id = get_item_id(socket)
    user_id = get_user_id(socket)

    AuctionManager.place_bid(item_id, user_id, amount)
    |> case do
      :ok ->
        {:reply, :ok, socket}

      {:error, :process_not_alive} = error ->
        {:reply, error, socket}
    end
  end

  @impl true
  def handle_info({:bid_placed, item_bid}, socket) do
    push(socket, "bid_placed", Map.from_struct(item_bid))

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    user_id = get_user_id(socket)
    item_id = get_item_id(socket)

    new_socket =
      case UserInAuction.get_user_status(item_id, user_id) do
        {:error, :not_found} ->
          assign(socket, :user_status, "nothing")

        {:ok, :watching} ->
          assign(socket, :user_status, "watching")

        {:ok, :joined} ->
          assign(socket, :user_status, "joined")
      end

    setup_presence(new_socket)

    # send init data to client
    new_socket
    |> push_auction_item()
    |> push_auction_item_biddings()
    |> subscribe_to_auction_item_pubsub()

    UserStoreAgent.set_current_auction(user_id, item_id)

    {:noreply, new_socket}
  end

  @impl true
  def terminate({:shutdown, _}, socket) do
    UserStoreAgent.clear_current_auction(get_user_id(socket))
    :ok
  end

  defp subscribe_to_auction_item_pubsub(socket) do
    socket
    |> get_item_id()
    |> AuctionPublisher.subscribe_auction_item()

    socket
  end

  defp setup_presence(socket) do
    user_id = get_user_id(socket)

    push(socket, "presence_state", get_item_users(socket))

    Presence.track(socket, user_id, %{
      id: user_id,
      username: socket.assigns.user.username,
      display_name: socket.assigns.user.display_name,
      user_status: socket.assigns.user_status
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
          |> Map.put(:user_status, get_user_status(socket))

        push(socket, "auction_item", Map.from_struct(updated_item_with_data))

      {:error, reason} when reason in [:item_not_found, :user_not_found, :category_not_found] ->
        Logger.error(
          "Unexpected error occured while loading auction item that has an active ws channel"
        )
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

  defp get_user_status(socket) do
    UserInAuction.get_user_status(get_item_id(socket), get_user_id(socket))
    |> case do
      {:ok, status} ->
        status

      {:error, :not_found} ->
        :nothing
    end
  end

  defp update_presence_user_status(socket) do
    Presence.update(
      socket,
      get_user_id(socket),
      &Map.put(&1, :user_status, socket.assigns.user_status)
    )

    socket
  end

  defp put_user_status(socket, value) when value in [:watching, :joined, :nothing] do
    assign(socket, :user_status, value)
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
end
