defmodule BiddingPoc.AuctionPublisher do
  # TODO: This is not OK.. This app should not rely on Phoenix...

  alias BiddingPoc.Database.{AuctionBid, AuctionItem, User}

  # BROADCASTS

  @spec broadcast_auction_created(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_auction_created(auction) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:auction_added, auction}
    )
  end

  @spec broadcast_auction_deleted(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_auction_deleted(auction) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auctions_topic(),
      {:auction_deleted, auction}
    )
  end

  @spec broadcast_auction_updated(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_auction_updated(auction) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_topic(auction.id),
      {:detail_updated, auction}
    )
  end

  @spec broadcast_bidding_started(AuctionItem.t()) :: :ok | {:error, any()}
  def broadcast_bidding_started(auction) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_topic(auction.id),
      {:bidding_started, auction}
    )
  end

  @spec broadcast_bidding_ended(pos_integer()) :: :ok | {:error, any()}
  def broadcast_bidding_ended(auction_id) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_topic(auction_id),
      :bidding_ended
    )
  end

  @spec broadcast_bid_placed(AuctionBid.t()) :: :ok | {:error, any()}
  def broadcast_bid_placed(auction_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_bidding_topic(auction_bid.auction_id),
      {:bid_placed, auction_bid}
    )
  end

  @spec broadcast_auction_average_bid_changed(float(), pos_integer()) :: :ok | {:error, any()}
  def broadcast_auction_average_bid_changed(auction_id, new_average_bid) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionItemPubSub,
      auction_topic(auction_id),
      {:average_bid, new_average_bid}
    )
  end

  @spec broadcast_auction_user_status_changed(pos_integer(), pos_integer(), :following | :nothing | :joined) :: :ok | {:error, any}
  def broadcast_auction_user_status_changed(auction_id, user_id, status) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionUserStatusPubSub,
      user_auction_presence_topic(auction_id, user_id),
      {:user_status_changed, status}
    )
  end

  @spec broadcast_new_auction_user(pos_integer(), User.t() | map()) :: :ok | {:error, any}
  def broadcast_new_auction_user(auction_id, user) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionUserStatusPubSub,
      auction_presence_topic(auction_id),
      {:new_auction_user, user}
    )
  end

  @spec broadcast_new_auction_user(pos_integer(), pos_integer()) :: :ok | {:error, any}
  def broadcast_auction_user_left(auction_id, user_id) do
    Phoenix.PubSub.broadcast(
      BiddingPoc.AuctionUserStatusPubSub,
      auction_presence_topic(auction_id),
      {:auction_user_left, user_id}
    )
  end

  # SUBSCRIPTIONS

  def subscribe_auction_topic(auction_id) do
    Phoenix.PubSub.subscribe(BiddingPoc.AuctionItemPubSub, auction_topic(auction_id))
  end

  def unsubscribe_auction_topic(auction_id) do
    Phoenix.PubSub.unsubscribe(BiddingPoc.AuctionItemPubSub, auction_topic(auction_id))
  end

  def subscribe_auction_bidding_topic(auction_id) do
    Phoenix.PubSub.subscribe(BiddingPoc.AuctionItemPubSub, auction_bidding_topic(auction_id))
  end

  def subscribe_auctions_topic() do
    Phoenix.PubSub.subscribe(BiddingPoc.AuctionItemPubSub, auctions_topic())
  end

  def subscribe_auction_user_presence_topic(auction_id, user_id) do
    Phoenix.PubSub.subscribe(
      BiddingPoc.AuctionUserStatusPubSub,
      user_auction_presence_topic(auction_id, user_id)
    )
  end

  def subscribe_auction_presence(auction_id) do
    Phoenix.PubSub.subscribe(
      BiddingPoc.AuctionUserStatusPubSub,
      auction_presence_topic(auction_id)
    )
  end

  # TOPICS

  def auctions_topic() do
    "auctions"
  end

  def auction_topic(auction_id) do
    "auction:#{auction_id}"
  end

  def auction_bidding_topic(auction_id) do
    "auction_bidding:#{auction_id}"
  end

  def user_auction_presence_topic(auction_id, user_id) do
    "auction_presence:#{auction_id}:#{user_id}"
  end

  def auction_presence_topic(auction_id) do
    "auction_presence:#{auction_id}"
  end
end
