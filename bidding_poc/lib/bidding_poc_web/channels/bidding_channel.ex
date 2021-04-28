defmodule BiddingPocWeb.BiddingChannel do
  use BiddingPocWeb, :channel

  require Logger

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.Database.{AuctionItem, UserInAuction, AuctionBid}
  alias BiddingPoc.AuctionManager
  alias BiddingPoc.AuctionPublisher
  alias BiddingPoc.UserStoreAgent
  alias BiddingPocWeb.Presence

  @impl true
  def join("bidding:" <> auction_id, _payload, socket) do
    auction_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, :invalid_auction_id}

      {parsed_auction_id, _} ->
        parsed_auction_id
        |> AuctionItem.member?()
        |> if do
          send(self(), :after_join)

          {
            :ok,
            put_auction_id(socket, parsed_auction_id)
          }
        else
          {:error, :not_found}
        end
    end
  end

  @impl true
  def handle_in("place_bid", %{"amount" => amount}, socket) when is_number(amount) do
    auction_id = get_auction_id(socket)
    user_id = get_user_id(socket)

    AuctionManager.place_bid(auction_id, user_id, amount)
    |> case do
      :ok ->
        {:reply, :ok, socket}

      {:error, :process_not_alive} = error ->
        {:reply, error, socket}
    end
  end

  @impl true
  def handle_info({:bid_placed, auction_bid}, socket) do
    push(socket, "bid_placed", Map.from_struct(auction_bid))

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    user_id = get_user_id(socket)
    auction_id = get_auction_id(socket)

    new_socket =
      case UserInAuction.get_user_status(auction_id, user_id) do
        {:error, :not_found} ->
          assign(socket, :user_status, "nothing")

        {:ok, :following} ->
          assign(socket, :user_status, "following")

        {:ok, :joined} ->
          assign(socket, :user_status, "joined")
      end

    # setup_presence(new_socket)

    # send init data to client
    new_socket
    |> push_auction_item()
    |> push_auction_item_biddings()
    |> subscribe_to_auction_item_pubsub()

    UserStoreAgent.set_current_auction(user_id, auction_id)

    {:noreply, new_socket}
  end

  @impl true
  def terminate({:shutdown, _}, socket) do
    UserStoreAgent.clear_current_auction(get_user_id(socket))
    :ok
  end

  defp subscribe_to_auction_item_pubsub(socket) do
    socket
    |> get_auction_id()
    |> AuctionPublisher.subscribe_auction_topic()

    socket
  end

  # defp setup_presence(socket) do
  #   user_id = get_user_id(socket)

  #   push(socket, "presence_state", get_item_users(socket))

  #   Presence.track(socket, user_id, %{
  #     id: user_id,
  #     username: socket.assigns.user.username,
  #     display_name: socket.assigns.user.display_name,
  #     user_status: socket.assigns.user_status
  #   })
  # end

  defp push_auction_item(socket) do
    socket
    |> get_auction_id()
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
      |> AuctionBid.with_data()
      |> Enum.map(&Map.from_struct/1)

    push(socket, "biddings", %{biddings: biddings})
    socket
  end

  defp get_item_biddings(socket) do
    socket
    |> get_auction_id()
    |> AuctionBid.get_item_bids()
  end
end
