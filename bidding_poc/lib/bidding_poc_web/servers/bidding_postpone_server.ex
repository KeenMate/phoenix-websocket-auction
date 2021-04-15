# defmodule BiddingPocWeb.BiddingPostponeServer do
#   use GenServer

#   require Logger

#   alias BiddingPoc.Database.{AuctionItem}
#   alias BiddingPoc.Common
#   alias BiddingPocWeb.Endpoint

#   def start_link(state) do
#     GenServer.start_link(__MODULE__, state, name: __MODULE__)
#   end

#   @impl true
#   def init(state) do
#     {:ok, state}
#   end

#   @impl true
#   def handle_cast({:register_postpone, item_id}, _from, state) when is_number(item_id) do
#     with {:item, {:ok, item}} <- {:item, AuctionItem.get_by_id(item_id)},
#          {:existing, false} <- {:existing, Map.has_key?(state, item_id)} do

#       :erlang.send_after(diff_bidding_start(found), self(), {:item_resumed, item_id})

#       new_state =
#         state
#         |> Map.put(item_id, found)

#       {:noreply, new_state}
#     else
#       {:item, {:error, :not_found}} ->
#         Logger.error("Attempted to postpone item that was not found", item_id: item_id)
        
#         {:noreply, state}

#       {:existing, true} ->
#         Logger.warn("Attempted to postpone item that is already postponed", item_id: item_id)
        
#         {:noreply, state}
#     end
#   end

#   @impl true
#   def handle_call(:get_postponed_items) do
#     # TODO: Not implemented
#   end

#   @impl true
#   def handle_info({:item_resumed, item_id}, state) when is_number(item_id) do
#     state
#     |> Map.has_key?(item_id)
#     |> if do
#       {item, new_state} = Map.pop(state, item_id)
#       # TODO: Notify item resumption
#       Endpoint.broadcast("bidding:" <> item_id, "auciton_started", item)

#       {:noreply, new_state}
#     end
#   end

#   defp diff_bidding_start(%AuctionItem{bidding_start: bidding_start}) do
#     DateTime.diff(bidding_start, DateTime.now!(Common.timezone), :millisecond)
#   end
# end