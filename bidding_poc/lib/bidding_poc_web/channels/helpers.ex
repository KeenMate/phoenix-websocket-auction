defmodule BiddingPocWeb.SocketHelpers do
  import Phoenix.Socket

  alias BiddingPocWeb.Presence

  def put_user_status(socket, value) when value in [:following, :joined, :nothing] do
    assign(socket, :user_status, value)
  end

  def update_presence_user_status(socket) do
    Presence.update(
      socket,
      get_user_id(socket),
      &Map.put(&1, :user_status, get_user_status(socket))
    )

    socket
  end

  def put_auction_id(socket, auction_id) do
    assign(socket, :auction_id, auction_id)
  end

  def get_user_status(socket) do
    socket
    |> Map.get(:assigns)
    |> Map.get(:user_status)
  end

  def get_user_id(%{assigns: %{user: %{id: user_id}}}), do: user_id

  def get_auction_id(socket) do
    socket
    |> Map.get(:assigns)
    |> Map.get(:auction_id)
  end
end
