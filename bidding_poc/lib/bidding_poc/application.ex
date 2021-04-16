defmodule BiddingPoc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BiddingPocWeb.Telemetry,
      {Registry, name: Registy.AuctionItemRegisty, keys: :unique},
      {DynamicSupervisor, strategy: :one_for_one, name: BiddingPoc.AuctionItemSupervisor},
      # Start the PubSub system
      {Phoenix.PubSub, name: BiddingPoc.PubSub},
      # Auction item related events
      {Phoenix.PubSub, name: BiddingPoc.AuctionItemPubSub},
      {Phoenix.PubSub, name: BiddingPoc.UserPubSub},
      # {Phoenix.PubSub, name: BiddingPoc.UserPubSub},
      BiddingPocWeb.Presence,
      # BiddingPocWeb.BiddingPostponeServer,
      # Start the Endpoint (http/https)
      BiddingPocWeb.Endpoint
      # Start a worker by calling: BiddingPoc.Worker.start_link(arg)
      # {BiddingPoc.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BiddingPoc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BiddingPocWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
