defmodule BiddingPocWeb.UserController do
  use BiddingPocWeb, :controller

  alias Phoenix.Token
  alias BiddingPoc.Database.{User}

  def create(conn, %{
        "username" => username,
        "display_name" => display_name,
        "password" => password
      }) do
    case User.create_user(username, display_name, password) do
      {:ok, new_user} ->
        user_to_return =
          new_user
          |> Map.drop([:password])

        conn
        |> put_status(:created)
        |> json(%{user: user_to_return, token: sign_auth_token(conn, user_to_return.id)})

      {:error, :exists} ->
        conn
        |> put_status(:conflict)
        |> json(error_message_response("User with given username already exists"))
    end
  end

  def show(conn, %{"id" => user_id}) do
    user_id
    |> String.to_integer()
    |> User.get_by_id()
    |> case do
      {:ok, user} ->
        conn
        |> put_status(:ok)
        |> json(Map.from_struct(user))

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(user_id_not_found_msg())
    end
  end

  # def update(conn, %{"id" => user_id} = user_params) do
  #   converted_user = User.from_params(user_params)

  #   user_id
  #   |> String.to_integer()
  #   |> User.update_user(converted_user)
  #   |> case do
  #     {:ok, updated_user} ->
  #       conn
  #       |> put_status(:ok)
  #       |> json(updated_user)

  #     {:error, :not_found} ->
  #       conn
  #       |> put_status(:not_found)
  #       |> json(user_id_not_found_msg())
  #   end
  # end

  def delete(conn, %{"id" => user_id}) do
    user_id
    |> String.to_integer()
    |> User.delete_user()
    |> case do
      :ok ->
        conn
        |> put_status(:ok)
        |> json(%{})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(user_id_not_found_msg())
    end
  end

  defp sign_auth_token(conn, user_id) do
    Token.sign(conn, "user.auth", user_id)
  end

  defp user_id_not_found_msg() do
    error_message_response("User with given id was not found")
  end

  defp error_message_response(message) do
    %{reason: message}
  end
end
