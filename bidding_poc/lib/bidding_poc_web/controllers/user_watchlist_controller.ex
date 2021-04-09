defmodule BiddingPocWeb.UserWatchlistController do
  use BiddingPocWeb, :controller

  alias BiddingPoc.Database.{UserWatchedCategory}

  def index(conn, %{"user_id" => user_id}) do
    user_categories =
      user_id
      |> String.to_integer()
      |> UserWatchedCategory.get_user_categories()

    conn
    |> put_status(:ok)
    |> json(user_categories)
  end
end
