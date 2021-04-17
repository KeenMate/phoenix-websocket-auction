defmodule BiddingPoc.StartAuctionServersTask do
  use Task

  require Logger

  alias BiddingPoc.Common
  alias BiddingPoc.Database.{AuctionItem}
  alias BiddingPoc.AuctionItem, as: AuctionItemCtx

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    Logger.debug("Attempting to start auctions")

    AuctionItem.get_all()
    |> Stream.filter(&auction_item_running?/1)
    |> Stream.map(&start_auction_item_server/1)
    |> Enum.to_list()

    :ok
  end

  defp start_auction_item_server(auction_item) do
    Logger.debug("Starting auction #{auction_item.id}")
    BiddingPoc.star_auction_item_server(auction_item.id, false)
  end

  defp auction_item_running?(auction_item) do
    now = DateTime.now!(Common.timezone())

    DateTime.compare(auction_item.bidding_start, now) in [:lt, :eq] and
      DateTime.compare(auction_item.bidding_end, now) == :gt
  end
end
