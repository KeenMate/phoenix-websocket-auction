defmodule PubSubTestWeb.Router do
  use PubSubTestWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", PubSubTestWeb do
    pipe_through :api
  end
end
