defmodule BiddingPoc.UserPublisher do
  alias BiddingPoc.UserPubSub

  alias BiddingPoc.Database.{AuctionBid, AuctionItem}

  # BROADCASTS

  @spec send_bid_placed_success(pos_integer(), AuctionBid.t()) :: :ok | {:error, any()}
  def send_bid_placed_success(user_id, auction_bid) do
    Phoenix.PubSub.broadcast(UserPubSub, user_topic(user_id), {:bid_placed, auction_bid})
  end

  @spec send_place_bid_error(pos_integer(), pos_integer(), any()) :: :ok | {:error, any()}
  def send_place_bid_error(user_id, auction_id, error) do
    Phoenix.PubSub.broadcast(UserPubSub, user_topic(user_id), {:bid_place, auction_id, error})
  end

  @spec send_bid_overbidded(pos_integer(), AuctionBid.t()) :: :ok | {:error, any()}
  def send_bid_overbidded(user_id, bid) do
    Phoenix.PubSub.broadcast(UserPubSub, user_topic(user_id), {:bid_overbidded, bid})
  end

  @spec send_bidding_started(pos_integer(), AuctionItem.t()) :: :ok | {:error, any()}
  def send_bidding_started(user_id, auction) do
    Phoenix.PubSub.broadcast(UserPubSub, user_topic(user_id), {:bidding_started, auction})
  end

  @spec send_bidding_ended(pos_integer(), AuctionItem.t()) :: :ok | {:error, any()}
  def send_bidding_ended(user_id, auction) do
    Phoenix.PubSub.broadcast(UserPubSub, user_topic(user_id), {:bidding_ended, auction})
  end

  @spec send_auction_relation_changed(pos_integer(), pos_integer(), :added | :removed) :: :ok | {:error, any()}
  def send_auction_relation_changed(user_id, auction_id, change) do
    Phoenix.PubSub.broadcast(UserPubSub, user_topic(user_id), {:auction_relation_changed, auction_id, change})
  end

  # SUBSCRIPTIONS

  def subscribe_user_pubsub(user_id) do
    Phoenix.PubSub.subscribe(UserPubSub, user_topic(user_id))
  end

  # TOPICS

  def user_topic(user_id) do
    "user:#{user_id}"
  end
end
