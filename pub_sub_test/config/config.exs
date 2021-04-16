# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :pub_sub_test, PubSubTestWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "KhURNKbytEbAAXJjCUPcObeGXUq9HQdtiirFnDOniZ9eAYTit7z0h6k2Dkw6jAlS",
  render_errors: [view: PubSubTestWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: PubSubTest.PubSub,
  live_view: [signing_salt: "HAMvtVM3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
