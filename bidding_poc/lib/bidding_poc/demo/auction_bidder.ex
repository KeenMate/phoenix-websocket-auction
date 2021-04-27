defmodule BiddingPoc.AuctionBidder do
  alias BiddingPoc.AuctionBidderServer, as: BidderServer
  alias BiddingPoc.Database.ItemBid

  def start_bidders(auction_ids, count) do
    bids =
      auction_ids
      |> Stream.map(fn auction_id ->
        {auction_id, ItemBid.get_item_highest_bid(auction_id)}
      end)
      |> Stream.filter(&Enum.any?(elem(&1, 1)))
      |> Stream.map(fn {auction_id, [bid]} -> {auction_id, bid.amount} end)
      |> Enum.into(%{})

    1..count
    |> Stream.map(fn idx ->
      %{
        auction_ids: auction_ids,
        bids: bids,
        user_id: trunc(:random.uniform(50) + 10),
        name: "Bidder #{idx}"
      }
    end)
    |> Stream.map(&BidderServer.start_link/1)
    |> Enum.to_list()
  end
end
