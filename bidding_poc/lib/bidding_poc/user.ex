defmodule BiddingPoc.User do
  alias BiddingPoc.Database.User

  @spec get_users(map()) :: [User.t()]
  def get_users(params) do
    search = Map.get(params, "search", nil)
    page = Map.get(params, "page", 0)
    page_size = Map.get(params, "pageSize", 10)

    User.get_users(search, page, page_size)
  end

  @spec get_user(pos_integer() | atom()) :: {:error, :not_found} | {:ok, User.t()}
  def get_user(user_id) do
    User.get_by_id(user_id)
  end

  @spec update_user(map()) :: {:error, :not_found} | {:ok, User.t()}
  def update_user(params) do
    %{
      "user_id" => user_id,
      "username" => username,
      "display_name" => display_name,
      "password" => password,
      "is_admin" => is_admin
    } = params

    User.update_user(user_id, username, display_name, password, is_admin)
  end

  @spec delete_user(pos_integer()) :: :ok | {:error, :not_found}
  def delete_user(user_id) do
    User.delete_user(user_id)
  end
end
