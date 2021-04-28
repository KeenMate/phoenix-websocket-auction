defmodule BiddingPocWeb.AuctionChannel do
  use BiddingPocWeb, :channel

  require Logger

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.Database.{AuctionItem, UserFollowedCategory, UserInAuction}

  alias BiddingPoc.{UserManager}
  alias BiddingPoc.AuctionPublisher
  alias BiddingPocWeb.Presence

  @impl true
  def join("auction:" <> auction_id, _payload, socket) do
    send(self(), :after_join)

    auction_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, :invalid_auction_id}

      {parsed_auction_id, _} ->
        {
          :ok,
          socket
          |> put_auction_id(parsed_auction_id)
          |> put_user_status(:nothing)
        }
    end
  end

  @impl true
  def handle_in("get_auction", %{"auction_id" => auction_id}, socket) do
    {:reply, AuctionItem.get_by_id(auction_id), socket}
  end

  def handle_in("join_auction", _payload, socket) do
    auction_id = get_auction_id(socket)
    user_id = get_user_id(socket)

    UserInAuction.add_user_to_auction(auction_id, user_id)

    new_socket =
      socket
      |> put_user_status(:joined)
      |> update_presence_user_status()

    {:reply, :ok, new_socket}
  end

  def handle_in("leave_auction", _payload, socket) do
    auction_id = get_auction_id(socket)
    user_id = get_user_id(socket)

    UserInAuction.remove_user_from_auction(auction_id, user_id)
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
          |> put_user_status(:following)
          |> update_presence_user_status()

        {:reply, result, new_socket}
    end
  end

  def handle_in("toggle_follow", _payload, socket) do
    UserInAuction.toggle_followed_auction(get_auction_id(socket), get_user_id(socket))
    |> case do
      {:error, :joined} = error ->
        {:reply, error, socket}

      {:ok, :following} = res ->
        new_socket =
          socket
          |> put_user_status(:following)
          |> update_presence_user_status()

        {:reply, res, new_socket}

      {:ok, :not_following} = res ->
        new_socket =
          socket
          |> put_user_status(:nothing)
          |> update_presence_user_status()

        {:reply, res, new_socket}
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:bidding_started, %AuctionItem{} = auction_item}, socket) do
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
    auction_id = get_auction_id(socket)
    # {:ok, _} = Presence.track(socket, get_user_id(socket), %{})

    # new_socket =
    #   case UserInAuction.get_user_status(auction_id, user_id) do
    #     {:error, :not_found} ->
    #       put_user_status(socket, :nothing)

    #     {:ok, :following} ->
    #       put_user_status(socket, :following)

    #     {:ok, :joined} ->
    #       put_user_status(socket, :joined)
    #   end

    AuctionPublisher.subscribe_auction_topic(auction_id)

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
      category_followed_by_user?(user_id, auction_item) ||
      UserInAuction.user_in_auction?(auction_item.id, user_id)
  end

  defp category_followed_by_user?(user_id, auction_item) do
    auction_item
    |> Map.get(:category_id)
    |> UserFollowedCategory.category_followed_by_user?(user_id)
  end
end
