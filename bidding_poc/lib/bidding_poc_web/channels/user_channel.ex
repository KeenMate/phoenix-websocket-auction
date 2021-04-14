defmodule BiddingPocWeb.UserChannel do
  def join("user:" <> user_id, _payload, socket) do
    current_user_id = socket.assigns.user.id

    user_id
    |> Integer.parse()
    |> case do
      :error ->
        {:error, %{reason: "Invalid user_id"}}

      {^current_user_id, _} ->
        {:ok, socket}
    end
  end
end
