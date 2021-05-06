defmodule BiddingPocWeb.AuctionChannel do
  use BiddingPocWeb, :channel

  require Logger

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.Database.{AuctionItem, UserInAuction}

  alias BiddingPoc.{AuctionManager}
  alias BiddingPoc.AuctionPublisher
  alias BiddingPoc.UserStoreAgent

  @impl true
  def join("auction:" <> auction_id, payload, socket) do
    include_bid_placed = Map.get(payload, "include_bid_placed", false)

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
            socket
            |> put_auction_id(parsed_auction_id)
            |> put_include_bid_placed(include_bid_placed)
            |> put_user_status(:nothing)
          }
        else
          {:error, :not_found}
        end
    end
  end

  @impl true
  def handle_in("get_auction", %{"auction_id" => auction_id}, socket) do
    {:reply, AuctionItem.get_by_id(auction_id), socket}
  end

  def handle_in("join_auction", _payload, socket) do
    AuctionManager.join_auction(get_auction_id(socket), get_user_id(socket))
    |> case do
      {:ok, _} ->
        new_socket = put_user_status(socket, :joined)

        {:reply, :ok, new_socket}
    end
  end

  def handle_in("leave_auction", _payload, socket) do
    AuctionManager.leave_auction(get_auction_id(socket), get_user_id(socket))
    |> case do
      {:error, reason} = error when reason in [:not_found, :already_bidded] ->
        {:reply, error, socket}

      {:ok, status} = result ->
        new_socket =
          put_user_status(
            socket,
            case status do
              :removed -> :nothing
              :bidding_left -> :following
            end
          )

        {:reply, result, new_socket}
    end
  end

  def handle_in("toggle_follow", _payload, socket) do
    AuctionManager.toggle_follow_auction(get_auction_id(socket), get_user_id(socket))
    |> case do
      {:error, :joined} = error ->
        {:reply, error, socket}

      {:ok, status} ->
        new_socket =
          put_user_status(
            socket,
            case status do
              :following -> :following
              :not_following -> :nothing
            end
          )

        {:reply, {:ok, get_user_status(new_socket)}, new_socket}
    end
  end

  @impl true
  def handle_info({:bid_placed, auction_bid}, socket) do
    push(socket, "bid_placed", auction_bid)

    {:noreply, socket}
  end

  def handle_info({:average_bid, _}, socket) do
    # TODO: send average bid
    {:noreply, socket}
  end

  def handle_info({:auction_updated, new_auction}, socket) do
    # TODO: maybe call AuctionItem.with_data and put :user_status key (call push_auction_item/1)
    push(socket, "auction_updated", Map.from_struct(new_auction))

    {:noreply, socket}
  end

  def handle_info(:bidding_started, socket) do
    push(socket, "bidding_started", %{})

    {:noreply, socket}
  end

  def handle_info(:bidding_ended, socket) do
    push(socket, "bidding_ended", %{})

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    user_id = get_user_id(socket)
    auction_id = get_auction_id(socket)

    new_socket =
      case UserInAuction.get_user_status(auction_id, user_id) do
        {:ok, status} ->
          put_user_status(socket, status)

        {:error, :not_found} ->
          put_user_status(socket, :nothing)
      end

    push_auction_item(new_socket)

    UserStoreAgent.set_current_auction(user_id, auction_id)

    if bid_placed_included?(new_socket) do
      AuctionPublisher.subscribe_auction_bidding_topic(auction_id)
    end

    AuctionPublisher.subscribe_auction_topic(auction_id)

    {:noreply, new_socket}
  end

  @impl true
  def terminate({:shutdown, reason}, socket) do
    Logger.debug("Auction channel is shutting down with reason: #{inspect(reason)}")
    UserStoreAgent.clear_current_auction(get_user_id(socket))
    :ok
  end

  def terminate(:shutdown, socket) do
    Logger.warn("Auction channel is just shutting down")
    UserStoreAgent.clear_current_auction(get_user_id(socket))
    :ok
  end

  # defp user_interested_in_auction_item?(socket, auction_item) do
  #   user_id = get_user_id(socket)

  #   UserManager.is_auction_currently_viewed?(user_id, auction_item.id) ||
  #     category_followed_by_user?(user_id, auction_item) ||
  #     UserInAuction.user_in_auction?(auction_item.id, user_id)
  # end

  defp push_auction_item(socket) do
    socket
    |> get_auction_id()
    |> AuctionItem.with_data()
    |> case do
      {:ok, %AuctionItem{} = auction_with_data} ->
        updated_auction_with_data =
          auction_with_data
          |> Map.put(:user_status, get_user_status(socket))

        push(socket, "auction_data", Map.from_struct(updated_auction_with_data))

      {:error, reason}
      when reason in [:auction_not_found, :user_not_found, :category_not_found] ->
        Logger.error(
          "Unexpected error occured while loading auction item that has an active ws channel"
        )
    end

    socket
  end

  # defp category_followed_by_user?(user_id, auction_item) do
  #   auction_item
  #   |> Map.get(:category_id)
  #   |> UserFollowedCategory.category_followed_by_user?(user_id)
  # end

  defp bid_placed_included?(socket) do
    Map.get(socket.assigns, :include_bid_placed, false)
  end

  defp put_include_bid_placed(socket, include_bid_placed) do
    assign(socket, :include_bid_placed, include_bid_placed)
  end
end
