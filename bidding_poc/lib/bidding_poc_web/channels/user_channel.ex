defmodule BiddingPocWeb.UserChannel do
  use BiddingPocWeb, :channel

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.UserPublisher

  def join("user:" <> user_id, _payload, socket) do
    current_user_id = get_user_id(socket)

    user_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, :invalid_user_id}

      {^current_user_id, _} ->
        send(self(), :after_join)

        {:ok, socket}
    end
  end

  def handle_info({:bid_placed, auction_bid}, socket) do
    push(socket, "place_bid_success", Map.from_struct(auction_bid))

    {:noreply, socket}
  end

  def handle_info({:bid_place, {:error, reason}}, socket) when is_atom(reason) do
    push(socket, "place_bid_error", %{reason: Atom.to_string(reason)})

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    UserPublisher.subscribe_user_pubsub(get_user_id(socket))

    {:noreply, socket}
  end
end
