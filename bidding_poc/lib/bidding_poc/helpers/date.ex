defmodule BiddingPoc.DateHelpers do
  def parse_iso_datetime!(datetime) when is_binary(datetime) do
    {:ok, parsed, _} = DateTime.from_iso8601(datetime)
    parsed
  end

  def parse_iso_datetime!(nil), do: nil
end
