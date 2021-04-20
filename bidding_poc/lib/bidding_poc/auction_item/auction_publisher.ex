defmodule BiddingPoc.AuctionPublisher do
  def broadcast_item_removed(socket, item_id) do

  end

  def broadcast_bidding_started(item_id) do
    Phoenix.PubSub.broadcast(AuctionItemPubSub, "auction_item:#{item_id}", :bidding_started)
  end

  def broadcast_bid_placed(item_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      "bidding:#{item_bid.item_id}",
      {:bid_placed, Map.from_struct(item_bid)}
    )
  end

  def broadcast_auction_average_bid_changed(new_average_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      "auctions:lobby",
      {:average_bid, new_average_bid}
    )
  end

  def broadcast_item_added(auction_item) do
    Phoenix.PubSub.broadcast(BiddingPoc.AuctionItemPubSub, "auctions:lobby", {:item_added, auction_item})
  end

  def subscribe_auction_bidding(item_id) do
    Phoenix.PubSub.subscribe(AuctionItemPubSub, "bidding:#{item_id}")
  end
end
