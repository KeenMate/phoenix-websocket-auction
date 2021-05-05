# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :bidding_poc, BiddingPocWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "szUoYl7SmCGXUjdJ0uGydzCea/JswdnzRtAfz5ZfoSANfCgQOcsKeCIOT399x/ul",
  render_errors: [view: BiddingPocWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: BiddingPoc.PubSub,
  live_view: [signing_salt: "PzIJw9V3"],
  force_ssl: [hsts: true]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

File.exists?("config/.local.exs") && import_config(".local.exs")
