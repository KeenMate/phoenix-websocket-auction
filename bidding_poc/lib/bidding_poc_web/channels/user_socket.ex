defmodule BiddingPocWeb.UserSocket do
  use Phoenix.Socket

  alias Phoenix.Token
  alias BiddingPoc.Database.{User}

  channel "users:lobby", BiddingPocWeb.UsersChannel
  channel "auction:lobby", BiddingPocWeb.AuctionChannel
  channel "bidding:*", BiddingPocWeb.BiddingChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    with {:ok, user_id} when is_number(user_id) <- verify_token(socket, token),
         {:ok, user} <- User.get_by_id(user_id) do
      {
        :ok,
        socket
        |> assign(:user, user)
      }
    else
      _ ->
        :error
    end
  end

  @impl true
  def id(socket), do: "user:#{get_user_id(socket)}"

  defp verify_token(socket, token) do
    Token.verify(socket, "user.auth", token)
  end

  defp get_user_id(%{assigns: %{user: %{id: user_id}}}), do: user_id
end
