defmodule BiddingPocWeb.AuctionItemController do
  use BiddingPocWeb, :controller

  require Logger

  alias BiddingPoc.Database.{AuctionItem, AuctionItemCategory, AuctionBid}
  alias BiddingPoc.AuctionManager

  def index(conn, params) do
    skip =
      params
      |> Map.get("skip", "0")
      |> String.to_integer()

    take =
      params
      |> Map.get("take", "10")
      |> String.to_integer()

    conn
    |> put_status(:ok)
    |> json(
      AuctionItem.get_last_items(skip, take)
      |> Enum.map(&Map.from_struct/1)
    )
  end

  def create(conn, auction_item_params) do
    user_id = conn.assigns.user_id

    auction_item_params
    |> AuctionManager.create_auction(user_id)
    |> case do
      {:ok, auction_item} ->
        conn
        |> put_status(:created)
        |> json(auction_item |> Map.from_struct())

      {:error, :id_filled} ->
        conn
        |> put_status(500)
        |> json(error_message_response("Known but unexpected situation occured"))

      {:error, :title_used} ->
        conn
        |> put_status(500)
        |> json(error_message_response("This title has been used"))
    end
  end

  def show(conn, %{"id" => auction_id}) do
    parsed_auction_id = String.to_integer(auction_id)

    with {:ok, auction} <- AuctionItem.get_by_id(parsed_auction_id),
         {:ok, biddings} <- AuctionBid.get_item_bids(parsed_auction_id) do
      conn
      |> put_status(:ok)
      |> json(%{
        auction: Map.from_struct(auction),
        biddings: Enum.take(biddings, 10)
      })
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(user_id_not_found_msg())

      {:error, _} ->
        conn
        |> put_status(500)
        |> json(error_message_response("Error occured while getting data for auction item"))
    end
  end

  def delete(conn, %{"id" => auction_id}) do
    # TODO: Needs permission check

    auction_id
    |> String.to_integer()
    |> AuctionItem.delete_auction()

    conn
    |> put_status(:ok)
    |> json(%{})
  end

  def categories(conn, _) do
    conn
    |> put_status(:ok)
    |> json(AuctionItemCategory.get_categories())
  end

  defp user_id_not_found_msg() do
    error_message_response("User with given id was not found")
  end

  defp error_message_response(message) do
    %{reason: message}
  end
end
