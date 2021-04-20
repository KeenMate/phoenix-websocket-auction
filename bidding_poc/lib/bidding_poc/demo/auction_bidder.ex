defmodule BiddingPoc.AuctionBidder do
  alias BiddingPoc.AuctionBidderServer, as: BidderServer
  alias BiddingPoc.Database.ItemBid

  def start_bidders(item_ids, count) do
    bids =
      item_ids
      |> Stream.map(fn item_id ->
        {item_id, ItemBid.get_item_highest_bid(item_id)}
      end)
      |> Stream.filter(&Enum.any?(elem(&1, 1)))
      |> Stream.map(fn {item_id, [bid]} -> {item_id, bid.amount} end)
      |> Enum.into(%{})

    1..count
    |> Stream.map(fn idx ->
      %{
        item_ids: item_ids,
        bids: bids,
        user_id: trunc(:random.uniform(50) + 10),
        name: "Bidder #{idx}"
      }
    end)
    |> Stream.map(&BidderServer.start_link/1)
    |> Enum.to_list()
  end
end
