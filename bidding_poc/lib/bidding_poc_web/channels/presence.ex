defmodule BiddingPocWeb.Presence do
  use Phoenix.Presence,
  otp_app: :bidding_poc,
  pubsub_server: BiddingPoc.PubSub
end
