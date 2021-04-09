defmodule BiddingPocWeb.EmptyController do
  use BiddingPocWeb, :controller

  def options(conn, _) do
    send_resp(conn, 200, "OK")
  end
end
