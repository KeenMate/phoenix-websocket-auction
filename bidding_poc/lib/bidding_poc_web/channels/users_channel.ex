defmodule BiddingPocWeb.UsersChannel do
  use BiddingPocWeb, :channel

  require Logger

  import BiddingPocWeb.SocketHelpers

  alias BiddingPoc.User

  def join("users:lobby", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("get_users", params, socket) do
    if is_admin?(socket) do
      {:reply, {:ok, User.get_users(params)}, socket}
    else
      {:reply, {:error, :forbidden}, socket}
    end
  end

  def handle_in("get_user", %{"user_id" => user_id}, socket) do
    {:reply, User.get_user(user_id), socket}
  end

  def handle_in("update_user", %{"user_id" => user_id} = params, socket) do
    if is_admin?(socket) or user_id == get_user_id(socket) do
      case User.update_user(params) do
        {:ok, user} ->
          {
            :reply,
            {:ok, user},
            socket
            |> assign(:user, user)
          }

        {:error, :not_found} = error ->
          Logger.error("Could not found user_id for updating the user")
          {:reply, error, socket}
      end
    else
      {:reply, {:error, :forbidden}, socket}
    end
  end

  def handle_in("delete_user", %{"user_id" => user_id}, socket) do
    with {:admin, true} <- {:admin, is_admin?(socket)},
      {:current_user, false} <- {:current_user, user_id != get_user_id(socket)} do
      user_id
      |> User.delete_user()
      |> case do
        :ok ->
          {:reply, :ok, socket}
        {:error, :not_found} = error ->
          {:reply, error, socket}
      end
    else
      {:admin, false} ->
        {:reply, {:error, :forbidden}, socket}
      {:current_user, true} ->
        {:reply, {:error, :current_user}, socket}
    end
  end

  defp is_admin?(socket) do
    socket.assigns.user.is_admin
  end
end
