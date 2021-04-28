defmodule BiddingPocWeb.AuctionPresenceChannel do
  use BiddingPocWeb, :channel

  import BiddingPocWeb.SocketHelpers

  alias BiddingPocWeb.Presence
  alias BiddingPoc.Database.{UserInAuction}
  alias BiddingPoc.AuctionPublisher

  @impl true
  def join("auction_presence:" <> auction_id, _payload, socket) do
    send(self(), :after_join)

    auction_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, :invalid_auction_id}

      {parsed_auction_id, _} ->
        {
          :ok,
          socket
          |> put_auction_id(parsed_auction_id)
          |> put_user_status(:nothing)
        }
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    user_id = get_user_id(socket)
    auction_id = get_auction_id(socket)
    setup_presence(socket)

    new_socket =
      case UserInAuction.get_user_status(auction_id, user_id) do
        {:error, :not_found} ->
          put_user_status(socket, :nothing)

        {:ok, :following} ->
          put_user_status(socket, :following)

        {:ok, :joined} ->
          put_user_status(socket, :joined)
      end

    AuctionPublisher.subscribe_auction_topic(get_auction_id(new_socket))

    {:noreply, new_socket}
  end

  defp setup_presence(socket) do
    user_id = get_user_id(socket)

    push(socket, "presence_state", Presence.list(socket))

    Presence.track(socket, user_id, %{
      id: user_id,
      username: socket.assigns.user.username,
      display_name: socket.assigns.user.display_name,
      user_status: socket.assigns.user_status
    })
  end
end
