defmodule BiddingPocWeb.PageController do
  use BiddingPocWeb, :controller

  def index(conn, _params) do
    file =
      :code.priv_dir(:bidding_poc)
      |> Path.join("static/index.html")
      |> File.read!()

    html(conn, file)
  end
end
