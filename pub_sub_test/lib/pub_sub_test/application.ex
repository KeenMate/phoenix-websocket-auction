defmodule PubSubTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      PubSubTestWeb.Endpoint,
      {Phoenix.PubSub, name: PubSubTest.AuctionItemPubSub},
      {PubSubTest.AuctionItemServer, [999]},
      {PubSubTest.User, [999]}
      # Starts a worker by calling: PubSubTest.Worker.start_link(arg)
      # {PubSubTest.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PubSubTest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PubSubTestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
