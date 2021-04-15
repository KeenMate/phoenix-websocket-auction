defmodule BiddingPocWeb.DummyChannel do
  use BiddingPocWeb, :channel

  def join("dummy:", _, socket) do
    send(self(), :after_join)

    {:ok, socket}
  end

  def join("dummy:blocking", _, socket) do
    send(self(), :after_join_blocking)

    {:ok, socket}
  end

  def handle_in("get", _, socket) do
    Process.sleep(15000)

    {:reply, {:ok, 123}, socket}
  end

  def handle_info(:tick, socket) do
    push(socket, "tick", %{})
    :erlang.send_after(500, self(), :tick)

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    :erlang.send_after(500, self(), :tick)

    {:noreply, socket}
  end

  def handle_info(:after_join_blocking, socket) do
    # Process.sleep(999999999)

    {:noreply, socket}
  end
end