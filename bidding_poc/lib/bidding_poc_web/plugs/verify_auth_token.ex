defmodule BiddingPocWeb.Plugs.VerifyAuthToken do
  import Plug.Conn

  @auth_token_max_age 86400

  alias Phoenix.Token

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    max_age = Keyword.get(opts, :max_age, @auth_token_max_age)
    token = get_token(conn)

    if token do
      verify(conn, token, max_age)
    else
      unauthorized(conn)
    end
  end

  defp verify(conn, token, max_age) do
    Token.verify(conn, "user.auth", token, max_age: max_age)
    |> case do
      {:ok, user_id} ->
        conn
        |> assign(:user_id, user_id)

      {:error, reason} when reason in [:expired, :invalid] ->
        unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> send_resp(:unauthorized, "")
    |> halt()
  end

  defp get_token(%Plug.Conn{req_headers: req_headers} = conn) do
    req_headers
    |> Stream.map(fn
      {"authorization", "Bearer " <> token} ->
        token
      _ ->
        nil
    end)
    |> Stream.filter(&(&1 != nil))
    |> Stream.take(1)
    |> Enum.at(0, conn.params[:token])
  end
end
