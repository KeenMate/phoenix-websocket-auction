defmodule BiddingPoc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BiddingPocWeb.Telemetry,
      Supervisor.child_spec({Registry, name: Registry.AuctionItemRegistry, keys: :unique}, id: AuctionItemRegistry),
      Supervisor.child_spec({Registry, name: Registry.UserStoreRegistry, keys: :unique}, id: UserStoreRegistry),
      Supervisor.child_spec({DynamicSupervisor, strategy: :one_for_one, name: BiddingPoc.AuctionItemSupervisor}, id: AuctionItemSupervisor),
      Supervisor.child_spec({DynamicSupervisor, strategy: :one_for_one, name: BiddingPoc.UserStoreSupervisor}, id: UserStoreSupervisor),
      # Start the PubSub system
      {Phoenix.PubSub, name: BiddingPoc.PubSub},
      # Auction item related events
      Supervisor.child_spec({Phoenix.PubSub, name: BiddingPoc.AuctionItemPubSub},
        id: BiddingPoc.AuctionItemPubSub
      ),
      Supervisor.child_spec({Phoenix.PubSub, name: BiddingPoc.UserPubSub},
        id: BiddingPoc.UserPubSub
      ),
      # {Phoenix.PubSub, name: BiddingPoc.UserPubSub},
      BiddingPocWeb.Presence,
      {BiddingPoc.StartAuctionServersTask, []},
      # Start the Endpoint (http/https)
      BiddingPocWeb.Endpoint
      # Start a worker by calling: BiddingPoc.Worker.start_link(arg)
      # {BiddingPoc.Worker, arg}
    ]

    initialize_amnesia()

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

  defp initialize_amnesia() do
    Amnesia.start()

    BiddingPoc.Database.create!(memory: [node()])
    :ok = BiddingPoc.Database.wait(15000)

    BiddingPoc.DataPopulation.insert_users()
    BiddingPoc.DataPopulation.insert_categories()
  end
end
