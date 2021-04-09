defmodule BiddingPocWeb.MeController do
  use BiddingPocWeb, :controller

  require Logger

  alias BiddingPoc.Database.User

  def index(%Plug.Conn{assigns: %{user_id: user_id}} = conn, _) do
    user_id
    |> User.get_by_id()
    |> case do
      {:ok, user} ->
        conn
        |> put_status(:ok)
        |> json(Map.from_struct(user))

      {:error, :not_found} ->
        Logger.warn("User was not found using the user_id from auth token")

        conn
        |> put_status(:not_found)
        |> json(error_message_response("User was not found for given user id"))
    end
  end

  def index(conn, _) do
    Logger.error("Could not find user_id in assigns (even though it passed token verification)")

    conn
    |> put_status(:unauthorized)
    |> json(error_message_response("Auth token not extracted"))
  end

  defp error_message_response(message) do
    %{reason: message}
  end
end
