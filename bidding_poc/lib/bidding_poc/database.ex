use Amnesia

alias BiddingPoc.Common

defdatabase BiddingPoc.Database do
  deftable(UserWatchedCategory)
  deftable(AuctionItem)
  deftable(ItemBid)

  deftable User, [{:id, autoincrement}, :username, :password, :is_admin],
    type: :set,
    index: [:username] do
    @type t() :: %User{
            id: pos_integer() | nil,
            username: String.t(),
            password: String.t(),
            is_admin: boolean()
          }

    require Logger
    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__, except: [:password])

    @spec create_user(binary(), binary()) :: {:ok, t()} | {:error, :exists}
    def create_user(username, password) do
      Amnesia.transaction do
        username
        |> get_by_username()
        |> case do
          {:ok, %User{}} ->
            {:error, :exists}

          {:error, :not_found} ->
            result =
              to_new_user(username, password)
              |> write()

            Logger.debug("User: #{username} was created")

            {:ok, result}
        end
      end
    end

    @spec update_user(number(), binary(), binary(), boolean()) :: {:ok, t()} | {:error, :not_found}
    def update_user(user_id, username, password, is_admin) when is_number(user_id) and is_binary(username) and is_binary(password) and is_boolean(is_admin) do
      Amnesia.transaction do
        user_id
        |> get_by_id()
        |> case do
          {:error, :not_found} = error ->
            error

          {:ok, %User{} = current_user} ->
            updated_user =
              current_user
              |> Map.merge(%{username: username, password: password, is_admin: is_admin})
              |> write()

            {:ok, updated_user}
        end
      end
    end

    @spec get_by_username(binary()) :: {:ok, t()} | {:error, :not_found}
    def get_by_username(username) do
      Amnesia.transaction do
        match(username: username)
        |> Amnesia.Selection.values()
        |> case do
          [] ->
            {:error, :not_found}
          [%User{} = user] ->
            {:ok, user}
        end
      end
    end

    @spec get_by_id(number() | :system) :: {:ok, t()} | {:error, :not_found}
    @doc """
    Returns user with given ID without its password
    """
    def get_by_id(user_id) when is_number(user_id) do
      Amnesia.transaction do
        read(user_id)
      end
      |> case do
        nil ->
          {:error, :not_found}

        found ->
          {:ok, found}
      end
    end

    def get_by_id(:system) do
      {
        :ok,
        %User{
          username: "System",
          is_admin: true
        }
      }
    end

    @spec authenticate_user(binary(), binary()) :: {:ok, t()} | {:error, :not_found}
    def authenticate_user(username, password) do
      Amnesia.transaction do
        match(username: username, password: password)
        |> Amnesia.Selection.values()
        |> case do
          [] -> {:error, :not_found}
          [matched] -> {:ok, matched}
        end
      end
    end

    @spec promote_admin(number(), boolean()) :: any
    def promote_admin(user_id, is_admin) do
      Amnesia.transaction do
        user_id
        |> get_by_id()
        |> case do
          {:error, :not_found} = error ->
            error

          {:ok, found} ->
            updated =
              found
              |> Map.put(:is_admin, is_admin)
              |> write()

            {:ok, updated}
        end
      end
    end

    @spec delete_user(pos_integer()) :: :ok | {:error, :not_found}
    def delete_user(user_id) do
      Amnesia.transaction do
        cond do
          not member?(user_id) ->
            {:error, :not_found}

          true ->
            delete(user_id)

            user_id
            |> delete_user_categories()
            |> delete_user_auction_items()
            |> delete_user_biddings()

            Logger.debug("User: #{user_id} deleted")

            :ok
        end
      end
    end

    def get_users(search, page \\ 0, page_size \\ 10) when is_binary(search) and is_number(page) and is_number(page_size) do
      Amnesia.transaction do
        get_all_users()
        |> Stream.filter(fn user ->
          user.username =~ search
        end)
        |> Stream.drop(page * page_size)
        |> Stream.take(page_size)
        |> Enum.to_list()
      end
    end

    @spec get_all_users :: Stream.t()
    def get_all_users() do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.map(&parse_tuple/1)
        |> Enum.sort_by(&(&1.username))
      end
    end

    def from_params(%{"username" => username, "password" => password}) do
      to_new_user(username, password)
    end

    defp delete_user_biddings(user_id) do
      user_id
      |> ItemBid.get_user_bids()
      |> Enum.map(&Map.get(&1, :id))
      |> Enum.map(&ItemBid.delete/1)

      Logger.debug("User's (#{user_id}) bids deleted")

      user_id
    end

    defp delete_user_auction_items(user_id) do
      user_id
      |> AuctionItem.get_user_items()
      |> Enum.map(&Map.get(:id, &1))
      |> Enum.each(&AuctionItem.delete/1)

      Logger.debug("User's (#{user_id}) auction items deleted")

      user_id
    end

    defp delete_user_categories(user_id) do
      user_id
      |> UserWatchedCategory.get_user_categories()
      |> Enum.map(&Map.get(:id, &1))
      |> Enum.each(&UserWatchedCategory.delete/1)

      Logger.debug("User's (#{user_id}) watched categories deleted")

      user_id
    end

    defp to_new_user(username, password) do
      %User{
        username: username,
        password: password,
        is_admin: false
      }
    end

    defp parse_tuple({mod, id, username, password, is_admin}) do
      struct!(mod, id: id, username: username, password: password, is_admin: is_admin)
    end
  end

  deftable(UserWatchedCategory, [{:id, autoincrement}, :user_id, :category_id, :prefered_price],
    type: :set,
    index: [:user_id, :category_id]
  ) do
    @type t() :: %UserWatchedCategory{
            id: pos_integer(),
            user_id: pos_integer(),
            category_id: pos_integer(),
            prefered_price: pos_integer() | nil
          }

    require Logger
    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    @spec add_category(pos_integer(), binary(), nil | pos_integer()) ::
            {:ok, t()} | :already_watched
    def add_category(user_id, category_id, prefered_price)
        when is_number(user_id) and
               is_number(category_id) and
               (is_number(prefered_price) or prefered_price == nil) do
      Amnesia.transaction do
        cond do
          category_watched_by_user?(category_id, user_id) ->
            :already_watched

          true ->
            result =
              to_item(user_id, category_id, prefered_price)
              |> write()

            Logger.debug("Category: #{category_id} now watched by user: #{user_id}")

            {:ok, result}
        end
      end
    end

    @spec remove_user_category(pos_integer(), pos_integer()) :: :ok | {:error, :not_found}
    def remove_user_category(category_id, user_id) do
      Amnesia.transaction do
        match(user_id: user_id, category_id: category_id)
        |> Amnesia.Selection.values()
        |> case do
          [%UserWatchedCategory{id: id_to_delete}] ->
            delete(id_to_delete)

            Logger.debug("User (#{user_id}) removed watched category: #{category_id}")

            :ok

          [] ->
            {:error, :not_found}
        end
      end
    end

    @spec get_user_categories(pos_integer()) :: [t()]
    def get_user_categories(user_id) do
      Amnesia.transaction do
        match(user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    @spec category_watched_by_user?(pos_integer(), pos_integer()) :: boolean()
    def category_watched_by_user?(category_id, user_id) do
      Amnesia.transaction do
        match(user_id: user_id, category_id: category_id)
        |> Map.get(:values)
        |> Enum.any?()
      end
    end

    defp to_item(user_id, category_id, prefered_price) do
      %UserWatchedCategory{
        user_id: user_id,
        category_id: category_id,
        prefered_price: prefered_price
      }
    end
  end

  deftable(AuctionItemCategory, [{:id, autoincrement}, :title], type: :set, index: [:title]) do
    @type t() :: %AuctionItemCategory{
            id: pos_integer() | nil,
            title: String.t()
          }

    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    alias BiddingPoc.Database.{AuctionItem}

    @spec create_category(binary()) :: {:ok, t()} | {:error, :exists, t()}
    def create_category(title) when is_binary(title) do
      case get_by_title(title) do
        {:error, :not_found} ->
          Amnesia.transaction do
            new_category =
              %AuctionItemCategory{
                title: title
              }
              |> write()

            {:ok, new_category}
          end

        {:ok, existing} ->
          {:error, :exists, existing}
      end
    end

    @spec get_by_id(pos_integer()) :: {:ok, t()} | {:error, :not_found}
    def get_by_id(category_id) when is_number(category_id) do
      Amnesia.transaction do
        category_id
        |> read()
        |> case do
          nil ->
            {:error, :not_found}

          found ->
            {:ok, found}
        end
      end
    end

    @spec get_by_title(binary()) :: {:ok, t()} | {:error, :not_found}
    def get_by_title(title) when is_binary(title) do
      lowered_title = String.downcase(title)

      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Stream.filter(fn tuple ->
          tuple
          |> elem(2)
          |> String.downcase() == lowered_title
        end)
        |> Stream.map(&parse_from_tuple/1)
        |> Stream.take(1)
        |> Enum.to_list()
        |> case do
          [] ->
            {:error, :not_found}

          [single] ->
            {:ok, single}
        end
      end
    end

    @spec get_categories :: [t()]
    @doc """
    Returns categories sorted alphabetically
    """
    def get_categories() do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.sort_by(&elem(&1, 2), :asc)
        |> Enum.map(&parse_from_tuple/1)
      end
    end

    @spec delete_category(number()) :: :ok, {:error, :not_found | :used}
    def delete_category(category_id) do
      Amnesia.transaction do
        with {:category, category} when not is_nil(category) <- {:category, read(category_id)},
          {:items, []} <- {:items, AuctionItem.get_category_items(category_id, 0, 1)} do
          delete(category_id)

          :ok
        else
          {:category, nil} ->
            {:error, :not_found}

          {:items, _linked_items} ->
            {:error, :used}
        end
      end
    end

    defp parse_from_tuple({mod, id, title}) do
      struct!(mod, id: id, title: title)
    end
  end

  deftable(
    AuctionItem,
    [
      {:id, autoincrement},
      :user_id,
      :title,
      :category_id,
      :start_price,
      :bidding_start,
      :bidding_end,
      :inserted_at
    ],
    type: :set,
    index: [:user_id, :category_id]
  ) do
    @type t() :: %AuctionItem{
            id: pos_integer() | nil,
            user_id: pos_integer(),
            title: String.t(),
            category_id: pos_integer() | nil,
            start_price: pos_integer(),
            bidding_end: DateTime.t(),
            bidding_start: DateTime.t(),
            inserted_at: DateTime.t()
          }

    alias BiddingPoc.Database.{User, ItemBid}

    require Logger
    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    @spec write_item(t()) :: {:ok, t()} | {:error, :id_filled}
    @doc """
    Writes auction item in transaction
    """
    def write_item(%AuctionItem{id: nil} = item, user_id) when is_number(user_id) do
      Amnesia.transaction do
        result =
          item
          |> Map.put(:user_id, user_id)
          |> Map.put(:inserted_at, DateTime.now!(Common.timezone))
          |> write()

        Logger.debug("Auction item: #{item.title} created by user: #{user_id}")

        {:ok, result}
      end
    end

    def write_item(%AuctionItem{id: id}) when is_number(id) do
      {:error, :id_filled}
    end

    def get_all() do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.map(&parse_auction_item_record/1)
      end
    end

    @spec get_last_items(number(), number()) :: [t()]
    def get_last_items(search \\ nil, cateogry_id \\ nil, skip \\ 0, take \\ 10) when is_number(skip) and is_number(take) do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.sort(fn l, r ->
          l_inserted_at = elem(l, 8)
          r_inserted_at = elem(r, 8)

          if l_inserted_at && r_inserted_at do
            DateTime.compare(l_inserted_at, r_inserted_at) in [:gt, :eq]
          else
            true
          end
        end)
        |> Stream.map(&parse_auction_item_record/1)
        |> Stream.filter(fn item ->
          (if search, do: item.title =~ search, else: true) && (if cateogry_id, do: item.category_id == cateogry_id, else: true)
        end)
        |> Stream.drop(skip)
        |> Stream.take(take)
        |> Enum.to_list()
      end
    end

    @spec get_by_id(pos_integer()) :: {:ok, t()} | {:error, :not_found}
    @doc """
    Reads auction item in transaction
    """
    def get_by_id(item_id) when is_number(item_id) do
      Amnesia.transaction do
        read(item_id)
      end
      |> case do
        nil -> {:error, :not_found}
        found -> {:ok, found}
      end
    end

    @spec with_data(pos_integer()) :: {:ok, t()} | {:error, :item_not_found | :user_not_found | :category_not_found}
    def with_data(item_id) when is_number(item_id) do
      Amnesia.transaction do
        with {:item, {:ok, item}} <- {:item, get_by_id(item_id)},
         {:user, {:ok, user}} <- {:user, User.get_by_id(item.user_id)},
         {:category, {:ok, category}} <- {:category, AuctionItemCategory.get_by_id(item.category_id)} do
          item_with_additional_info =
            item
            |> Map.put(:username, user.username)
            |> Map.put(:category, category.title)

          {:ok, item_with_additional_info}
        else
          {:item, {:error, :not_found}} ->
            {:error, :item_not_found}
          {:user, {:error, :not_found}} ->
            {:error, :user_not_found}
          {:category, {:error, :not_found}} ->
            {:error, :category_not_found}
        end
      end
    end

    @spec get_user_items(pos_integer()) :: [t()]
    def get_user_items(user_id) when is_number(user_id) do
      Amnesia.transaction do
        match(user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    # @spec get_categories :: [binary()]
    # def get_categories() do
    #   Amnesia.transaction do
    #     stream()
    #     |> Enum.map(&(&1.category))
    #     |> Enum.uniq()
    #   end
    # end

    @spec get_category_items(pos_integer(), pos_integer(), pos_integer()) :: [t()]
    def get_category_items(category_id, skip \\ 0, take \\ 10)
        when is_number(category_id) and is_number(skip) and is_number(take) do
      Amnesia.transaction do
        stream()
        |> Stream.filter(&(&1.category_id == category_id))
        |> Stream.drop(skip)
        |> Stream.take(take)
        |> Enum.to_list()
      end
    end

    @spec place_bid(pos_integer(), pos_integer(), pos_integer()) ::
            {:ok, ItemBid.t()}
            | {:error, :not_found | :small_bid | :bidding_ended | :item_postponed}
    def place_bid(item_id, user_id, amount)
        when is_number(item_id) and is_number(user_id) and is_number(amount) do
      Amnesia.transaction do
        item = read(item_id)

        if item == nil do
          {:error, :not_found}
        else
          case item_bidding_status(item) do
            {:ok, :ongoing} ->
              case try_add_bid(item.id, user_id, amount) do
                {:ok, _} = res ->
                  Logger.debug("Bid placed for item: #{item_id} by user: #{user_id}")
                  res

                {:error, :small_bid} = error ->
                  error
              end
            {:ok, :postponed} ->
              {:error, :item_postponed}
            {:ok, :ended} ->
              {:error, :bidding_ended}
          end
        end
      end
    end

    @spec delete_item(number) :: :ok
    def delete_item(item_id) when is_number(item_id) do
      Amnesia.transaction do
        delete(item_id)

        :ok
      end
    end

    @spec new_item_from_params!(map()) :: t()
    def new_item_from_params!(params) do
      %AuctionItem{
        title: params["title"],
        category_id: params["category_id"],
        start_price: params["start_price"],
        bidding_start: parse_iso_datetime!(params["bidding_start"]),
        bidding_end: parse_iso_datetime!(params["bidding_end"]),
      }
    end

    def user_id_authorized?(item_id, user_id) when is_number(item_id) and is_number(user_id) do
      Amnesia.transaction do
        user_owner? =
          item_id
          |> read()
          |> Map.get(:user_id) == user_id

        if user_owner? do
          true
        else
          user_id
          |> User.get_by_id()
          |> case do
            {:ok, %User{is_admin: is_admin}} ->
              is_admin
            {:error, :not_found} ->
              false
          end
        end
      end
    end

    defp parse_auction_item_record(
           {AuctionItem, id, user_id, title, category_id, start_price, bidding_start, bidding_end, inserted_at}
         ) do
      %AuctionItem{
        id: id,
        user_id: user_id,
        title: title,
        category_id: category_id,
        start_price: start_price,
        bidding_end: bidding_end,
        bidding_start: bidding_start,
        inserted_at: inserted_at
      }
    end

    defp parse_iso_datetime!(datetime) when is_binary(datetime) do
      {:ok, parsed, _} = DateTime.from_iso8601(datetime)
      parsed
    end

    defp parse_iso_datetime!(nil), do: nil

    defp try_add_bid(item_id, user_id, amount) do
      if ItemBid.is_amount_highest?(item_id, amount) do
        new_bind =
          ItemBid.new_bid(item_id, user_id, amount)
          |> ItemBid.write()

        {:ok, new_bind}
      else
        {:error, :small_bid}
      end
    end

    @spec item_bidding_status(t()) :: {:ok, :ended | :onngoing | :postponed} | {:error, binary(), t()}
    defp item_bidding_status(item) do
      now = DateTime.now!(Common.timezone())
      bidding_start_comparison = DateTime.compare(item.bidding_start, now)

      cond do
        DateTime.compare(item.bidding_end, now) in [:lt, :eq] ->
          {:ok, :ended}

        bidding_start_comparison in [:lt, :eq] ->
          {:ok, :ongoing}

        bidding_start_comparison == :gt ->
          {:ok, :postponed}

        true ->
          {:error, "bidding_start or bidding_end prop has invalid value...", item}
      end
    end
  end

  deftable(
    ItemBid,
    [{:id, autoincrement}, :user_id, :item_id, :inserted_at, :amount],
    type: :ordered_set,
    index: [:item_id, :amount]
  ) do
    @type cents() :: pos_integer()

    @type t() :: %ItemBid{
            id: pos_integer(),
            user_id: pos_integer(),
            item_id: pos_integer(),
            inserted_at: DateTime.t(),
            amount: cents()
          }

    require Logger

    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    def get_user_bids(user_id) when is_number(user_id) do
      Amnesia.transaction do
        match(user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    def get_item_bids(item_id) when is_number(item_id) do
      Amnesia.transaction do
        match(item_id: item_id)
        |> Amnesia.Selection.values()
      end
    end

    @spec with_data(list(t())) :: list(t())
    def with_data(item_bids) when is_list(item_bids) do
      Amnesia.transaction do
        item_bids
        |> Enum.map(fn bid ->
          with {:user, {:ok, user}} <- {:user, get_user_from_bid(bid)} do
            updated_bid =
              bid
              |> Map.put(:username, user.username)
              updated_bid
          else
            {:user, {:error, :not_found}} ->
              Logger.error("Could not find username for item bid", bid: bid)
              bid
          end
        end)
      end
    end

    @spec is_amount_highest?(pos_integer(), pos_integer()) :: boolean()
    def is_amount_highest?(item_id_param, amount_param) when is_number(item_id_param) and is_number(amount_param) do
      Amnesia.transaction do
        where(item_id == item_id_param and amount >= amount_param)
        |> Amnesia.Selection.values()
        |> Enum.empty?()
      end
    end

    @spec get_item_highest_bid(pos_integer(), pos_integer()) :: [t()]
    def get_item_highest_bid(item_id, highest_count \\ 1)
        when is_number(item_id) and is_number(highest_count) do
      Amnesia.transaction do
        match(item_id: item_id)
        |> Amnesia.Selection.values()
        |> Enum.sort_by(& &1.amount, :desc)
        |> Enum.take(highest_count)
      end
    end

    @spec new_bid(pos_integer(), pos_integer(), pos_integer()) :: t()
    @doc """
    Returns new struct with given data
    """
    def new_bid(item_id, user_id, amount) do
      %ItemBid{
        item_id: item_id,
        user_id: user_id,
        amount: amount,
        inserted_at: DateTime.now!(Common.timezone())
      }
    end

    defp get_user_from_bid(%ItemBid{user_id: user_id}) do
      User.get_by_id(user_id)
    end
  end

  deftable UserInAuction, [{:id, autoincrement}, :user_id, :auction_item_id],
    index: [:user_id, :auction_item_id] do
    @moduledoc """
    This table holds informations on users joined in auctions
    """

    @type t() :: %UserInAuction{
            id: pos_integer() | nil,
            user_id: pos_integer(),
            auction_item_id: pos_integer()
          }

    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    @spec add_user_to_auction(pos_integer(), pos_integer()) :: {:ok, t()} | {:error, :exists}
    def add_user_to_auction(user_id, auction_item_id)
        when is_number(user_id) and is_number(auction_item_id) do
      Amnesia.transaction do
        match(user_id: user_id, auctino_item_id: auction_item_id)
        |> Amnesia.Selection.values()
        |> case do
          [] ->
            result =
              new_user_in_auction(user_id, auction_item_id)
              |> write()

            {:ok, result}

          x when is_list(x) ->
            {:error, :exists}
        end
      end
    end

    @spec user_in_auction?(pos_integer(), pos_integer()) :: boolean()
    def user_in_auction?(item_id, user_id) when is_number(item_id) and is_number(user_id) do
      Amnesia.transaction do
        match(item_id: item_id, user_id: user_id)
        |> Amnesia.Selection.values()
        |> Enum.any?()
      end
    end

    def get_users_for_auction(auction_item_id) when is_number(auction_item_id) do
      Amnesia.transaction do
        match(auction_item_id: auction_item_id)
        |> Amnesia.Selection.values()
      end
    end

    def get_auctions_for_user(user_id) when is_number(user_id) do
      Amnesia.transaction do
        match(user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    defp new_user_in_auction(user_id, auction_item_id) do
      %UserInAuction{
        user_id: user_id,
        auction_item_id: auction_item_id
      }
    end
  end
end
