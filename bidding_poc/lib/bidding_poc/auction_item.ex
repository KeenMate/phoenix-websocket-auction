defmodule BiddingPoc.AuctionItem do
  alias BiddingPoc.Database.{AuctionItem}

  def create_auction_item(params, owner_id) when is_number(owner_id) do
    params
    |> AuctionItem.new_item_from_params!()
    |> AuctionItem.write_item(owner_id)
  end

  def get_auction_items(params) do
    search = Map.get(params, "search")
    category_id = Map.get(params, "category_id")
    skip = Map.get(params, "skip")
    take = Map.get(params, "take")

    AuctionItem.get_last_items(search, category_id, skip, take)
  end
end