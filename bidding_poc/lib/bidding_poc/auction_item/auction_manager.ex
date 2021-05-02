defmodule BiddingPoc.AuctionManager do
  require Logger

  alias BiddingPoc.Database.{AuctionItem, UserInAuction, User}
  alias BiddingPoc.DateHelpers
  alias BiddingPoc.AuctionItemServer
  alias BiddingPoc.AuctionItemSupervisor
  alias BiddingPoc.AuctionPublisher

  @spec create_auction(map(), pos_integer()) ::
          {:ok, AuctionItem.t()} | {:error, :id_filled | :title_used}
  def create_auction(params, user_id) do
    params
    |> new_auction_from_params!()
    |> AuctionItem.create_auction(user_id)
    |> case do
      {:ok, new_auction} = result ->
        start_auction_item_server(new_auction.id, true)
        result

      {:error, :id_filled} = error ->
        Logger.error("Auction item id was filled")
        error

      {:error, :title_used} = error ->
        error
    end
  end

  @spec get_auctions(map()) :: [AuctionItem.t()]
  def get_auctions(params) do
    search = Map.get(params, "search")
    category_id = Map.get(params, "category_id")
    skip = Map.get(params, "skip")
    take = Map.get(params, "take")

    AuctionItem.get_last_auctions(search, nil, category_id, skip, take)
  end

  @spec get_user_auctions(pos_integer() | nil, map()) :: [AuctionItem.t()]
  def get_user_auctions(user_id, params \\ %{}) do
    search = Map.get(params, "search")
    category_id = Map.get(params, "category_id")
    skip = Map.get(params, "skip")
    take = Map.get(params, "take")

    AuctionItem.get_last_auctions(search, user_id, category_id, skip, take)
  end

  @spec get_auction_users(pos_integer()) :: [%{:__struct__ => atom(), user_status: atom()}]
  def get_auction_users(auction_id) do
    UserInAuction.get_auction_users(auction_id)
    |> Stream.filter(&(elem(&1, 0) == :ok))
    |> Stream.map(&elem(&1, 1))
    |> Stream.map(&put_user_status_for_user(&1, auction_id))
    |> Enum.to_list()
  end

  @spec update_auction(map(), pos_integer()) ::
          {:ok, AuctionItem.t()} | {:error, :forbidden | :not_found | :user_not_found}
  def update_auction(params, user_id) do
    params
    |> new_auction_from_params!()
    |> AuctionItem.update_auction(user_id)
    |> case do
      {:ok, updated} = result ->
        AuctionPublisher.broadcast_auction_updated(updated)
        result

      {:error, :forbidden} = error ->
        Logger.error(
          "Attempted to update auction by forbidden user. user_id: #{inspect(user_id)}"
        )

        error

      {:error, :user_not_found} = error ->
        Logger.warn("Attempted to update auction by missing user. user_id: #{inspect(user_id)}")
        error

      {:error, :not_found} = error ->
        Logger.warn("Attempted to update auction that was not found. params: #{inspect(params)}")
        error
    end
  end

  @spec toggle_follow_auction(pos_integer(), pos_integer()) :: Task.t()
  @doc """
  This functions toggles the follow relation between auction and user.
  """
  def toggle_follow_auction(auction_id, user_id) do
    UserInAuction.toggle_followed_auction(auction_id, user_id)
    |> case do
      {:ok, status} = result ->
        AuctionPublisher.broadcast_auction_user_status_changed(
          auction_id,
          user_id,
          case status do
            :not_following -> :nothing
            x -> x
          end
        )

        broadcast_auction_user_changed(auction_id, user_id, status)

        result

      other -> other
    end
  end

  def join_auction(auction_id, user_id) do
    UserInAuction.add_user_to_auction(auction_id, user_id)
    |> case do
      {:ok, %{joined: true}} = result ->
        broadcast_auction_user_changed(auction_id, user_id, :joined)

        result

      {:error, :exists} = error ->
        error
    end
  end

  def leave_auction(auction_id, user_id) do
    UserInAuction.remove_user_from_auction(auction_id, user_id)
    |> case do
      {:ok, status} = result ->
        case status do
          :bidding_left ->
            broadcast_auction_user_changed(auction_id, user_id, :following)

          :removed ->
            broadcast_auction_user_changed(auction_id, user_id, :not_following)
        end

        result

      other ->
        other
    end
  end

  @spec place_bid(pos_integer(), pos_integer() | :system, pos_integer()) ::
          :ok | {:error, :process_not_alive}
  def place_bid(auction_id, user_id, amount) do
    if auction_item_server_alive?(auction_id) do
      AuctionItemServer.place_bid(auction_id, user_id, amount)
    else
      # TODO: Maybe call DB function to attempt to store bid
      {:error, :process_not_alive}
    end
  end

  @spec delete_auction(pos_integer(), pos_integer()) ::
          {:error, :forbidden | :not_found | :user_not_found} | {:ok, AuctionItem.t()}
  def delete_auction(auction_id, user_id) do
    auction_id
    |> AuctionItem.user_id_authorized?(user_id)
    |> case do
      true ->
        auction_id
        |> AuctionItem.delete_auction()
        |> case do
          {:ok, deleted} = result ->
            AuctionPublisher.broadcast_auction_deleted(deleted)
            result

          {:error, :not_found} = error ->
            Logger.warn("Attempted to remove nonexisting auction item",
              auction_id: inspect(auction_id)
            )

            error
        end

      false ->
        {:error, :forbidden}

      {:error, _} = error ->
        error
    end
  end

  @spec new_auction_from_params!(map()) :: AuctionItem.t()
  def new_auction_from_params!(params) do
    %AuctionItem{
      title: params["title"],
      category_id: params["category_id"],
      start_price: params["start_price"],
      minimum_bid_step: params["minimum_bid_step"],
      bidding_start: DateHelpers.parse_iso_datetime!(params["bidding_start"]),
      bidding_end: DateHelpers.parse_iso_datetime!(params["bidding_end"])
    }
  end

  def start_auction_item_server(auction_id, initially_started) do
    DynamicSupervisor.start_child(
      AuctionItemSupervisor,
      auction_item_server_spec(auction_id, initially_started)
    )
  end

  def auction_item_server_spec(auction_id, initialy_started) do
    {AuctionItemServer, %{auction_id: auction_id, initialy_started: initialy_started}}
  end

  defp put_user_status_for_user(%User{} = user, auction_id) do
    user_status =
      case UserInAuction.get_user_status(auction_id, user.id) do
        {:error, :not_found} ->
          :nothing

        {:ok, status} ->
          status
      end

    Map.put(user, :user_status, user_status)
  end

  defp broadcast_auction_user_changed(auction_id, user_id, status) do
    case status do
      x when x in [:following, :joined] ->
        case User.get_by_id(user_id) do
          {:ok, found} ->
            user_with_status = put_user_status_for_user(found, auction_id)
            AuctionPublisher.broadcast_new_auction_user(auction_id, Map.from_struct(user_with_status))
          {:error, :not_found} ->
            Logger.error("Could not find user based on channel's user_id: #{inspect(user_id)}")
        end

      :not_following ->
        AuctionPublisher.broadcast_auction_user_left(auction_id, user_id)
    end
  end

  defp auction_item_server_alive?(auction_id) do
    Registry.lookup(Registry.AuctionItemRegistry, auction_id)
    |> case do
      [] -> false
      [_] -> true
    end
  end
end
