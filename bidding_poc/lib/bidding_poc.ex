defmodule BiddingPoc do
  @moduledoc """
  BiddingPoc keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  require Logger

  alias BiddingPoc.AuctionItemServer
  alias BiddingPoc.AuctionItem
  alias BiddingPoc.Database
  alias BiddingPoc.AuctionItemSupervisor
  alias BiddingPoc.AuctionItemServer

  @spec create_auction(map(), pos_integer()) :: {:ok, Database.AuctionItem.t()}
  def create_auction(auction, owner_id) do
    auction
    |> AuctionItem.create_auction_item(owner_id)
    |> case do
      {:ok, new_item} = res ->
        star_auction_item_server(new_item.id, true)
        res

      {:error, :id_filled} ->
        Logger.error("Auction item id was filled")
        :error
    end
  end

  @spec place_bid(pos_integer(), pos_integer(), pos_integer()) ::
          :ok | {:error, :process_not_alive}
  def place_bid(item_id, user_id, amount) do
    if auction_item_server_alive?(item_id) do
      AuctionItemServer.place_bid(item_id, user_id, amount)
    else
      # TODO: Maybe call DB function to attempt to store bid
      {:error, :process_not_alive}
    end
  end

  defp auction_item_server_alive?(item_id) do
    Registry.lookup(Registry.AuctionItemRegistry, item_id)
    |> case do
      [] -> false
      [_] -> true
    end
  end

  def star_auction_item_server(item_id, initially_started) do
    DynamicSupervisor.start_child(
      AuctionItemSupervisor,
      auction_item_server_spec(item_id, initially_started)
    )
  end

  def auction_item_server_spec(item_id, initialy_started) do
    {AuctionItemServer, %{item_id: item_id, initialy_started: initialy_started}}
  end
end
