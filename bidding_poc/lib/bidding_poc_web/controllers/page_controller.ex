defmodule BiddingPocWeb.PageController do
  use BiddingPocWeb, :controller

  def index(conn, _params) do
    html(conn, File.read!("priv/static/index.html"))
  end
end
