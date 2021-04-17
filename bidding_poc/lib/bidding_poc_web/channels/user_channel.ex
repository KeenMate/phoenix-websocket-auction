defmodule BiddingPocWeb.UserChannel do
  use BiddingPocWeb, :channel

  alias BiddingPoc.UserPubSub

  def join("user:" <> user_id, _payload, socket) do
    current_user_id = get_user_id(socket)

    user_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, %{reason: "Invalid user_id"}}

      {^current_user_id, _} ->
        send(self(), :after_join)

        {:ok, socket}
    end
  end

  def handle_info({:bid_placed, item_bid_id}, socket) do
    push(socket, "place_bid_success", item_bid_id)

    {:noreply, socket}
  end

  def handle_info({:bid_place, {:error, reason}}, socket) do
    push(socket, "place_bid_error", reason)

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    Phoenix.PubSub.subscribe(UserPubSub, "user:#{get_user_id(socket)}")

    {:noreply, socket}
  end

  defp get_user_id(socket) do
    socket.assigns.user.id
  end
end
