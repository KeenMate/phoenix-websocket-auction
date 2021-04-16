defmodule BiddingPoc.AuctionItem do
  require Logger

  alias BiddingPoc.Database.{AuctionItem}
  alias BiddingPoc.AuctionItemSupervisor
  alias BiddingPoc.AuctionItemServer

  def create_auction_item(params, owner_id) when is_number(owner_id) do
    params
    |> AuctionItem.new_item_from_params!()
    |> AuctionItem.write_item(owner_id)
    |> case do
      {:ok, new_item} = res ->
        star_auction_item_server(new_item.id)
        res
      {:error, :id_filled} ->
        Logger.error("Auction item id was filled")
        :error
    end
  end

  @spec place_bid(pos_integer(), pos_integer(), pos_integer()) :: :ok | {:error, :process_not_alive}
  def place_bid(item_id, user_id, amount) do
    if auction_item_server_alive?(item_id) do
      AuctionItemServer.place_bid(item_id, user_id, amount)
    else
      # TODO: Maybe call DB function to attempt to store bid
      {:error, :process_not_alive}
    end
  end

  def get_auction_items(params) do
    search = Map.get(params, "search")
    category_id = Map.get(params, "category_id")
    skip = Map.get(params, "skip")
    take = Map.get(params, "take")

    AuctionItem.get_last_items(search, category_id, skip, take)
  end

  def auction_item_server_spec(item_id, initialy_started) do
    {AuctionItemServer, %{item_id: item_id, initialy_started: initialy_started}}
  end

  defp star_auction_item_server(item_id) do
    DynamicSupervisor.start_child(AuctionItemSupervisor, auction_item_server_spec(item_id, true))
  end


  defp auction_item_server_alive?(item_id) do
    Registry.lookup(Registy.AuctionItemRegisty, AuctionItemServer.via_tuple(item_id))
    |> case do
      [] -> false
      [_ | []] -> true
    end
  end
end
