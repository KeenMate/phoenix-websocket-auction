defmodule BiddingPocWeb.UserSocket do
  use Phoenix.Socket

  alias Phoenix.Token
  alias BiddingPoc.Database.{User}
  alias BiddingPoc.UserManager

  channel "dummy:*", BiddingPocWeb.DummyChannel

  channel "users:lobby", BiddingPocWeb.UsersChannel
  channel "user:*", BiddingPocWeb.UserChannel
  channel "auction:lobby", BiddingPocWeb.AuctionsChannel
  channel "bidding:*", BiddingPocWeb.BiddingChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    with {:ok, user_id} when is_number(user_id) <- verify_token(socket, token),
         {:ok, user} <- User.get_by_id(user_id) do
      ensure_user_store_started(user_id)

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

  defp ensure_user_store_started(user_id) do
    unless UserManager.user_store_alive?(user_id) do
      UserManager.start_user_store(user_id)
    end
  end

  defp verify_token(socket, token) do
    Token.verify(socket, "user.auth", token)
  end

  defp get_user_id(%{assigns: %{user: %{id: user_id}}}), do: user_id
end
