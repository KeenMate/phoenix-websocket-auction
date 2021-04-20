defmodule BiddingPocWeb.Router do
  use BiddingPocWeb, :router

  alias BiddingPocWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug Plugs.VerifyAuthToken
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BiddingPocWeb do
    pipe_through :api

    post "/user", UserController, :create

    scope "/auth" do
      post "/login", AuthController, :login
    end
  end

  scope "/api", BiddingPocWeb do
    pipe_through [:api, :auth]

    scope "/auctions" do
      get "/categories", AuctionItemController, :categories

      resources "/", AuctionItemController, only: [:index, :create, :show, :update, :delete]
    end

    resources "/user", UserController, only: [:show, :delete] do
      resources "/watchlist", UserWatchlistController, only: [:index, :create, :update, :delete]
    end

    get "/me", MeController, :index

    options "/*path", EmptyController, :options
  end

  scope "/", BiddingPocWeb do
    get "/", PageController, :index
  end
end
