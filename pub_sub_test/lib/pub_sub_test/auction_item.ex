defmodule PubSubTest.AuctionItem do
  alias PubSubTest.{AuctionItemSupervisor, Auctions, AuctionItemServer}

  def create_auction(title) do
    %{id: item_id} = Auctions.create_auction(title)

    DynamicSupervisor.start_child(AuctionItemSupervisor, {AuctionItemServer, item_id})
  end
end
