defmodule BiddingPocWeb.UserChannel do
  use BiddingPocWeb, :channel

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.{UserPublisher, AuctionPublisher}

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

  def handle_info({:bid_overbidded, bid}, socket) do
    push(socket, "bid_overbidded", bid)

    {:noreply, socket}
  end

  def handle_info({:bid_placed, auction_bid}, socket) do
    push(socket, "place_bid_success", Map.from_struct(auction_bid))

    {:noreply, socket}
  end

  def handle_info({:bid_place, auction_id, {:error, reason}}, socket) when is_atom(reason) do
    push(socket, "place_bid_error", %{auction_id: auction_id, reason: Atom.to_string(reason)})

    {:noreply, socket}
  end

  def handle_info({event, auction}, socket) when event in [:bidding_started, :bidding_ended] do
    if auction.id in get_auction_relations(socket) do
      push(socket, Atom.to_string(event), Map.from_struct(auction))
    end

    {:noreply, socket}
  end

  def handle_info({:auction_relation_changed, auction_id, change}, socket) do
    new_socket =
      case change do
        :added ->
          add_auction_relation(socket, auction_id)

        :removed ->
          remove_auction_relation(socket, auction_id)
      end

    {:noreply, new_socket}
  end

  def handle_info(:after_join, socket) do
    UserPublisher.subscribe_user_pubsub(get_user_id(socket))

    # TODO: load user auction relations

    {:noreply, socket}
  end

  def handle_info(_, socket) do
    # because there are some events from auction_topic from AuctionPubSub
    {:noreply, socket}
  end

  defp get_auction_relations(socket) do
    socket
    |> Map.get(:assigns, %{})
    |> Map.get(:auction_relations, [])
  end

  defp add_auction_relation(socket, auction_id) do
    relations = get_auction_relations(socket)

    new_relations =
      unless auction_id in relations do
        AuctionPublisher.subscribe_auction_topic(auction_id)

        [auction_id | relations]
      else
        relations
      end


    assign(socket, :auction_relations, new_relations)
  end

  defp remove_auction_relation(socket, auction_id) do
    AuctionPublisher.unsubscribe_auction_topic(auction_id)

    filtered =
      socket
      |> get_auction_relations()
      |> Enum.filter(& &1.id != auction_id)

    assign(socket, :auction_relations, filtered)
  end
end
