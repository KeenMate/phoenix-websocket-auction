defmodule BiddingPoc.AuctionManager do
  require Logger

  alias BiddingPoc.Database.{AuctionItem}
  alias BiddingPoc.DateHelpers
  alias BiddingPoc.AuctionItemServer
  alias BiddingPoc.AuctionItemSupervisor
  alias BiddingPoc.AuctionPublisher

  def create_auction(params, user_id) do
    params
    |> new_item_from_params!()
    |> BiddingPoc.AuctionItem.create_auction_item(user_id)
    |> case do
      {:ok, new_item} = res ->
        star_auction_item_server(new_item.id, true)
        res

      {:error, :id_filled} ->
        Logger.error("Auction item id was filled")
        :error
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

  def remove_auction(socket, item_id, user_id) do
    if AuctionItem.user_id_authorized?(item_id, user_id) do
      :ok = AuctionItem.delete_item(item_id)

      AuctionPublisher.broadcast_item_removed(socket, item_id)

      :ok
    else
      {:error, :forbidden}
    end
  end

  @spec place_bid(pos_integer(), pos_integer(), pos_integer()) ::
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
