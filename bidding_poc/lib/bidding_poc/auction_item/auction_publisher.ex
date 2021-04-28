defmodule BiddingPoc.AuctionPublisher do
  # TODO: This is not OK.. This app should not rely on Phoenix...

  alias BiddingPoc.Database.{AuctionBid, AuctionItem}

  # BROADCASTS

  @spec broadcast_auction_created(AuctionItem.t()) :: :ok | {:error, any}
  def broadcast_auction_created(auction_item) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:auction_added, auction_item}
    )
  end

  @spec broadcast_auction_deleted(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_auction_deleted(auction_item) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:auction_deleted, auction_item}
    )
  end

  @spec broadcast_auction_updated(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_auction_updated(auction_item) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_item_topic(auction_item.id),
      {:detail_updated, auction_item}
    )
  end

  @spec broadcast_bidding_started(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_bidding_started(auction) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:bidding_started, auction}
    )
  end

  @spec broadcast_bidding_ended(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_bidding_ended(auction) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:bidding_ended, auction}
    )
  end

  @spec broadcast_bid_placed(AuctionBid.t()) :: :ok | {:error, any}
  def broadcast_bid_placed(auction_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_item_topic(auction_bid.auction_id),
      {:bid_placed, auction_bid}
    )
  end

  def broadcast_auction_average_bid_changed(new_average_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:average_bid, new_average_bid}
    )
  end

  def broadcast_auction_user_status_changed(auction_id, user_id, status) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionUserStatusPubSub,
      user_auction_presence(auction_id, user_id),
      {:user_status_changed, status}
    )
  end

  # SUBSCRIPTIONS

  def subscribe_auction_topic(auction_id) do
    Phoenix.PubSub.subscribe(BiddingPoc.AuctionItemPubSub, auction_item_topic(auction_id))
  end

  def subscribe_auctions_topic() do
    Phoenix.PubSub.subscribe(BiddingPoc.AuctionItemPubSub, auctions_topic())
  end

  def subscribe_auction_user_presence(auction_id, user_id) do
    Phoenix.PubSub.subscribe(
      BiddingPoc.AuctionUserStatusPubSub,
      user_auction_presence(auction_id, user_id)
    )
  end

  # TOPICS

  def auctions_topic() do
    "auctions"
  end

  def auction_item_topic(auction_id) do
    "auction:#{auction_id}"
  end

  def user_auction_presence(auction_id, user_id) do
    "auction_presence:#{auction_id}:#{user_id}"
  end
end
