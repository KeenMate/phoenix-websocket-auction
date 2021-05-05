defmodule BiddingPocWeb.AuctionsChannel do
  use BiddingPocWeb, :channel

  require Logger

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.Database.{AuctionItem, AuctionItemCategory, UserFollowedCategory, UserInAuction}

  alias BiddingPoc.{AuctionManager, UserManager}
  alias BiddingPoc.AuctionPublisher

  @impl true
  def join("auctions", _payload, socket) do
    send(self(), :after_join)

    {
      :ok,
      socket
    }
  end

  @impl true
  def handle_in("create_auction", auction_item_params, socket) do
    user_id = get_user_id(socket)

    auction_item_params
    |> AuctionManager.create_auction(user_id)
    |> case do
      {:ok, auction_item} = result ->
        # broadcast_from(socket, "auction_added", auction_item)

        UserInAuction.add_user_to_auction(auction_item.id, user_id, false)

        {:reply, result, socket}

      {:error, _} = error ->
        {:reply, error, socket}
    end
  end

  def handle_in("get_auctions", params, socket) do
    {:reply, {:ok, AuctionManager.get_auctions(params)}, socket}
  end

  def handle_in("get_my_auctions", params, socket) do
    {
      :reply,
      {
        :ok,
        AuctionManager.get_my_auctions_for_user(get_user_id(socket), params)
        |> Enum.map(&Map.from_struct/1)
      },
      socket
    }
  end

  def handle_in("get_user_auctions", %{"user_id" => user_id, "category_id" => category_id}, socket) do
    {
      :reply,
      {
        :ok,
        AuctionItem.get_user_auctions(user_id, category_id)
      },
      socket
    }
  end

  def handle_in("get_user_auctions_categories", %{"user_id" => user_id}, socket) do
    {
      :reply,
      {
        :ok,
        AuctionItemCategory.get_user_auctions_categories(user_id)
      },
      socket
    }
  end

  def handle_in("get_auction_categories", _payload, socket) do
    {:reply, {:ok, AuctionItemCategory.get_categories()}, socket}
  end

  def handle_in("update_auction", auction_item_params, socket) do
    user_id = get_user_id(socket)

    auction_item_params
    |> AuctionManager.update_auction(user_id)
    |> case do
      {:ok, auction_item} = result ->
        AuctionPublisher.broadcast_auction_updated(auction_item)

        {:reply, result, socket}

      {:error, _} = error ->
        {:reply, error, socket}
    end
  end

  def handle_in("delete_auction", %{"auction_id" => auction_id}, socket) do
    auction_id
    |> AuctionManager.delete_auction(get_user_id(socket))
    |> case do
      {:ok, _deleted_auction} ->
        {:reply, :ok, socket}

      {:error, _} = error ->
        {:reply, error, socket}
    end
  end

  @impl true
  def handle_info({:auction_added, %AuctionItem{} = auction_item}, socket) do
    if user_interested_in_auction?(socket, auction_item) do
      push(socket, "auction_added", auction_item)
    end

    {:noreply, socket}
  end

  def handle_info({:auction_deleted, %AuctionItem{} = auction_item}, socket) do
    if user_interested_in_auction?(socket, auction_item) do
      push(socket, "auction_deleted", auction_item)
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

  defp user_interested_in_auction?(socket, auction_item) do
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
