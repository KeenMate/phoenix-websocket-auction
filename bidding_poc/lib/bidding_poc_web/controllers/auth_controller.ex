defmodule BiddingPocWeb.AuthController do
  use BiddingPocWeb, :controller

  alias Phoenix.Token
  alias BiddingPoc.Database.User

  def login(conn, %{"username" => username, "password" => password}) do
    case User.authenticate_user(username, password) do
      {:ok, user} ->
        user_to_return = Map.drop(user, [:password])
        token = Token.sign(conn, "user.auth", user.id)

        conn
        |> put_status(:ok)
        |> json(%{user: user_to_return, token: token})

      {:error, :not_found} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{reason: "Unauthorized"})
    end
  end
end
