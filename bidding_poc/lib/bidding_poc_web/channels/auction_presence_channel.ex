defmodule BiddingPocWeb.AuctionPresenceChannel do
  use BiddingPocWeb, :channel

  import BiddingPocWeb.SocketHelpers

  alias BiddingPocWeb.Presence
  alias BiddingPoc.AuctionManager
  alias BiddingPoc.AuctionPublisher
  alias BiddingPoc.Database.{UserInAuction}

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
  def handle_in("toggle_follow", _paylaod, socket) do
    new_socket =
      AuctionManager.toggle_follow_auction(get_auction_id(socket), get_user_id(socket))
      |> case do
        {:ok, status} when status in [:following, :not_following] ->
          put_user_status(
            socket,
            case status do
              :not_following -> :nothing
              x -> x
            end
          )

        {:error, :joined} ->
          socket
      end

    update_presence_user_status(new_socket)

    {:reply, {:ok, get_user_status(new_socket)}, new_socket}
  end

  # not used now
  def handle_in("get_auction_users", _payload, socket) do
    {:reply, {:ok, get_auction_users(socket)}, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    user_id = get_user_id(socket)
    auction_id = get_auction_id(socket)

    new_socket =
      case UserInAuction.get_user_status(auction_id, user_id) do
        {:error, :not_found} ->
          put_user_status(socket, :nothing)

        {:ok, :following} ->
          put_user_status(socket, :following)

        {:ok, :joined} ->
          put_user_status(socket, :joined)
      end

    setup_presence(new_socket)

    setup_subscriptions(new_socket)

    push_auction_users(new_socket)

    {:noreply, new_socket}
  end

  # This is for toggle_follow implementation in FaF way (not done so now)
  def handle_info({:user_status_changed, _status}, socket) do
    new_socket = socket
    # |> put_user_status(status)
    # |> update_presence_user_status()

    {:noreply, new_socket}
  end

  def handle_info({event, payload}, socket)
      when event in [:new_auction_user, :auction_user_left] do
    push(
      socket,
      Atom.to_string(event),
      case event do
        :auction_user_left ->
          %{id: payload}
        _ -> payload
      end
    )

    {:noreply, socket}
  end

  defp push_auction_users(socket) do
    push(socket, "auction_users", %{users: get_auction_users(socket)})
  end

  defp get_auction_users(socket) do
    socket
    |> get_auction_id()
    |> AuctionManager.get_auction_users()
    |> Enum.map(&Map.from_struct/1)
  end

  defp setup_subscriptions(socket) do
    AuctionPublisher.subscribe_auction_user_presence(get_auction_id(socket), get_user_id(socket))
    AuctionPublisher.subscribe_auction_presence(get_auction_id(socket))
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
