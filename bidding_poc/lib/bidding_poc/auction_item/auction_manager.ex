defmodule BiddingPoc.AuctionManager do
  require Logger

  alias BiddingPoc.Database.{AuctionItem}
  alias BiddingPoc.DateHelpers
  alias BiddingPoc.AuctionItemServer
  alias BiddingPoc.AuctionItemSupervisor
  alias BiddingPoc.AuctionPublisher

  @spec create_auction(map(), pos_integer()) :: {:ok, AuctionItem.t()} | {:error, :id_filled | :title_used}
  def create_auction(params, user_id) do
    params
    |> new_item_from_params!()
    |> BiddingPoc.AuctionItem.create_auction_item(user_id)
    |> case do
      {:ok, new_item} = res ->
        star_auction_item_server(new_item.id, true)
        res

      {:error, :id_filled} = error ->
        Logger.error("Auction item id was filled")
        error

      {:error, :title_used} = error ->
        error
    end
  end

  @spec new_item_from_params!(map()) :: AuctionItem.t()
  def new_item_from_params!(params) do
    %AuctionItem{
      title: params["title"],
      category_id: params["category_id"],
      start_price: params["start_price"],
      bidding_start: DateHelpers.parse_iso_datetime!(params["bidding_start"]),
      bidding_end: DateHelpers.parse_iso_datetime!(params["bidding_end"])
    }
  end

  @spec remove_auction(pos_integer(), pos_integer()) :: {:error, :forbidden | :not_found | :user_not_found} | {:ok, AuctionItem.t()}
  def remove_auction(item_id, user_id) do
    item_id
    |> AuctionItem.user_id_authorized?(user_id)
    |> case do
      true ->
        item_id
        |> AuctionItem.delete_item()
        |> case do
          {:ok, deleted} = res ->
            AuctionPublisher.broadcast_item_removed(deleted)
            res
          {:error, :not_found} = error ->
            Logger.warn("Attempted to remove nonexisting auction item", item_id: inspect(item_id))
            error
        end

      false ->
        {:error, :forbidden}

      {:error, _} = error ->
        error
    end
  end

  @spec place_bid(pos_integer(), pos_integer() | :system, pos_integer()) ::
          :ok | {:error, :process_not_alive}
  def place_bid(item_id, user_id, amount) do
    if auction_item_server_alive?(item_id) do
      AuctionItemServer.place_bid(item_id, user_id, amount)
    else
      # TODO: Maybe call DB function to attempt to store bid
      {:error, :process_not_alive}
    end
  end

  defp auction_item_server_alive?(item_id) do
    Registry.lookup(Registry.AuctionItemRegistry, item_id)
    |> case do
      [] -> false
      [_] -> true
    end
  end

  def star_auction_item_server(item_id, initially_started) do
    DynamicSupervisor.start_child(
      AuctionItemSupervisor,
      auction_item_server_spec(item_id, initially_started)
    )
  end

  def auction_item_server_spec(item_id, initialy_started) do
    {AuctionItemServer, %{item_id: item_id, initialy_started: initialy_started}}
  end
end
