defmodule BiddingPoc.UserPublisher do
  alias BiddingPoc.UserPubSub

  def send_bid_placed_success(user_id, auction_bid) do
    Phoenix.PubSub.broadcast(UserPubSub, "user:#{user_id}", {:bid_placed, auction_bid})
  end

  def send_place_bid_error(user_id, error) do
    Phoenix.PubSub.broadcast(UserPubSub, "user:#{user_id}", {:bid_place, error})
  end

  def subscribe_user_pubsub(user_id) do
    Phoenix.PubSub.subscribe(UserPubSub, "user:#{user_id}")
  end
end
