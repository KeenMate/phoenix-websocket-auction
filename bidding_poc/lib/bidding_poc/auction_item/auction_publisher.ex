defmodule BiddingPoc.AuctionPublisher do
  alias BiddingPoc.Database.{ItemBid, AuctionItem}

  def broadcast_item_added(auction_item) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:item_added, auction_item}
    )
  end

  def broadcast_item_removed(auction_item) do
    # TODO: This is not OK.. This library should not rely on Phoenix...
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:item_removed, auction_item}
    )
  end

  @spec broadcast_bidding_started(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_bidding_started(item) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:bidding_started, item}
    )
  end

  @spec broadcast_bidding_ended(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_bidding_ended(item) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:bidding_ended, item}
    )
  end

  @spec broadcast_bid_placed(ItemBid.t()) :: :ok | {:error, any}
  def broadcast_bid_placed(item_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_item_topic(item_bid.item_id),
      {:bid_placed, item_bid}
    )
  end

  def broadcast_auction_average_bid_changed(new_average_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:average_bid, new_average_bid}
    )
  end

  def subscribe_auction_item(item_id) do
    Phoenix.PubSub.subscribe(BiddingPoc.AuctionItemPubSub, "auction_item:#{item_id}")
  end

  def subscribe_auctions_topic() do
    Phoenix.PubSub.subscribe(BiddingPoc.AuctionItemPubSub, auctions_topic())
  end

  def auctions_topic() do
    "auctions"
  end

  def auction_item_topic(auction_id) do
    "auction_item:#{auction_id}"
  end
end
