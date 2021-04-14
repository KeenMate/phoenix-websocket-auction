defmodule BiddingPocWeb.Presence do
  use Phoenix.Presence,
  otp_app: :bidding_poc,
  pubsub_server: BiddingPoc.PubSub

  require Logger

  # @impl true
  # def fetch("bidding:" <> tem_id, presences) do
  #   Logger.info("Fetching presence(#{tem_id}): #{inspect(presences)}")

  #   presences
  #   |> Map.keys()
  #   |>

  #   presences
  # end

  # def fetch(_topic, presences), do: presences
end
