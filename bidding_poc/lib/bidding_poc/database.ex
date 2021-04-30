use Amnesia

alias BiddingPoc.Common

defdatabase BiddingPoc.Database do
  deftable(UserFollowedCategory)
  deftable(AuctionItem)
  deftable(AuctionBid)

  deftable User, [{:id, autoincrement}, :username, :display_name, :password, :is_admin],
    type: :set,
    index: [:username] do
    @type t() :: %User{
            id: pos_integer() | nil,
            username: String.t(),
            display_name: String.t(),
            password: String.t(),
            is_admin: boolean()
          }

    require Logger
    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__, except: [:password])

    alias BiddingPoc.Database.{UserFollowedCategory}

    @spec create_user(binary(), binary(), binary()) :: {:ok, t()} | {:error, :exists}
    def create_user(username, display_name, password, is_admin \\ false) do
      Amnesia.transaction do
        username
        |> get_by_username()
        |> case do
          {:ok, %User{}} ->
            {:error, :exists}

          {:error, :not_found} ->
            result =
              to_user(username, display_name, password, is_admin)
              |> write()

            Logger.debug("User: #{username} was created")

            {:ok, result}
        end
      end
    end

    @spec update_user(pos_integer(), binary(), binary(), binary(), boolean()) ::
            {:ok, t()} | {:error, :not_found}
    def update_user(user_id, username, display_name, password, is_admin)
        when is_number(user_id) and is_binary(username) and is_binary(password) and
               is_boolean(is_admin) do
      Amnesia.transaction do
        user_id
        |> get_by_id()
        |> case do
          {:error, :not_found} = error ->
            error

          {:ok, %User{} = current_user} ->
            updated_user =
              current_user
              |> Map.merge(%{
                username: username,
                display_name: display_name,
                password: password,
                is_admin: is_admin
              })
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

    @spec get_by_id(pos_integer() | atom()) :: {:ok, t()} | {:error, :not_found}
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

    def get_by_id(:initial_bid) do
      {
        :ok,
        %User{
          display_name: "Initial bid",
          username: "initial_bid",
          is_admin: false
        }
      }
    end

    def get_by_id(:system) do
      {
        :ok,
        %User{
          display_name: "System",
          username: "system",
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

            delete_user_categories(user_id)
            AuctionItem.delete_user_auctions(user_id)
            AuctionBid.delete_user_bids(user_id)

            Logger.debug("User: #{user_id} deleted")

            :ok
        end
      end
    end

    @spec get_users(binary, pos_integer(), pos_integer()) :: [t()]
    def get_users(search, page \\ 0, page_size \\ 10)
        when is_binary(search) and is_number(page) and is_number(page_size) do
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

    @spec get_all_users :: [t()]
    def get_all_users() do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.map(&parse_tuple/1)
        |> Enum.sort_by(& &1.username)
      end
    end

    def from_params(params) do
      %{
        "username" => username,
        "display_name" => display_name,
        "password" => password,
        "is_admin" => is_admin
      } = params

      to_user(Map.get(params, "id"), username, display_name, password, is_admin)
    end

    defp delete_user_categories(user_id) do
      user_id
      |> UserFollowedCategory.get_user_categories()
      |> Enum.map(&Map.get(:id, &1))
      |> Enum.each(&UserFollowedCategory.delete/1)

      Logger.debug("User's (#{user_id}) followed categories deleted")

      user_id
    end

    defp to_user(id \\ nil, username, display_name, password, is_admin) do
      %User{
        id: id,
        username: username,
        display_name: display_name,
        password: password,
        is_admin: is_admin
      }
    end

    defp parse_tuple({mod, id, username, display_name, password, is_admin}) do
      struct!(mod,
        id: id,
        username: username,
        display_name: display_name,
        password: password,
        is_admin: is_admin
      )
    end
  end

  deftable(UserFollowedCategory, [{:id, autoincrement}, :user_id, :category_id, :prefered_price],
    type: :set,
    index: [:user_id, :category_id]
  ) do
    @type t() :: %UserFollowedCategory{
            id: pos_integer(),
            user_id: pos_integer(),
            category_id: pos_integer(),
            prefered_price: pos_integer() | nil
          }

    require Logger
    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    @spec follow_category(pos_integer(), binary(), nil | pos_integer()) ::
            {:ok, t()} | :already_followed
    def follow_category(user_id, category_id, prefered_price)
        when is_number(user_id) and
               is_number(category_id) and
               (is_number(prefered_price) or prefered_price == nil) do
      Amnesia.transaction do
        cond do
          category_followed_by_user?(category_id, user_id) ->
            :already_followed

          true ->
            result =
              to_auction(user_id, category_id, prefered_price)
              |> write()

            Logger.debug("Category: #{category_id} now followed by user: #{user_id}")

            {:ok, result}
        end
      end
    end

    @spec remove_followed_category(pos_integer(), pos_integer()) :: :ok | {:error, :not_found}
    def remove_followed_category(category_id, user_id) do
      Amnesia.transaction do
        match(user_id: user_id, category_id: category_id)
        |> Amnesia.Selection.values()
        |> case do
          [%UserFollowedCategory{id: id_to_delete}] ->
            delete(id_to_delete)

            Logger.debug("User (#{user_id}) removed followed category: #{category_id}")

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

    @spec category_followed_by_user?(pos_integer(), pos_integer()) :: boolean()
    def category_followed_by_user?(category_id, user_id) do
      Amnesia.transaction do
        match(category_id: category_id, user_id: user_id)
        |> Amnesia.Selection.values()
        |> Enum.any?()
      end
    end

    defp to_auction(user_id, category_id, prefered_price) do
      %UserFollowedCategory{
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

    @doc """
    Returns categories sorted alphabetically
    """
    @spec get_categories :: [t()]
    def get_categories() do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.sort_by(&elem(&1, 2), :asc)
        |> Enum.map(&parse_from_tuple/1)
      end
    end

    @spec(delete_category(number()) :: :ok, {:error, :not_found | :used})
    def delete_category(category_id) do
      Amnesia.transaction do
        with {:category, category} when not is_nil(category) <- {:category, read(category_id)},
             {:auctions, []} <- {:auctions, AuctionItem.get_category_auctions(category_id, 0, 1)} do
          delete(category_id)

          :ok
        else
          {:category, nil} ->
            {:error, :not_found}

          {:auctions, _linked_auctions} ->
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
      :minimum_bid_step,
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

    alias BiddingPoc.Database.{User, AuctionBid, UserInAuction}

    require Logger
    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    @spec create_auction(t()) :: {:ok, t()} | {:error, :id_filled | :title_used}
    @doc """
    Writes auction item in transaction
    """
    def create_auction(%AuctionItem{id: nil, title: title} = auction, user_id)
        when is_number(user_id) do
      Amnesia.transaction do
        match(title: title)
        |> Amnesia.Selection.values()
        |> case do
          [] ->
            result =
              auction
              |> Map.put(:user_id, user_id)
              |> Map.put(:inserted_at, DateTime.now!(Common.timezone()))
              |> write()

            Logger.debug("Auction item: #{auction.title} created by user: #{user_id}")

            {:ok, result}

          _ ->
            {:error, :title_used}
        end
      end
    end

    def create_auction(%AuctionItem{id: id}) when is_number(id) do
      {:error, :id_filled}
    end

    def get_all() do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.map(&parse_auction_item_record/1)
      end
    end

    @spec get_last_auctions(number(), number()) :: [t()]
    def get_last_auctions(search \\ nil, cateogry_id \\ nil, skip \\ 0, take \\ 10)
        when is_number(skip) and is_number(take) do
      Amnesia.transaction do
        foldl([], &[&1 | &2])
        |> Enum.sort(fn l, r ->
          l_inserted_at = elem(l, 9)
          r_inserted_at = elem(r, 9)

          if l_inserted_at && r_inserted_at do
            DateTime.compare(l_inserted_at, r_inserted_at) in [:gt, :eq]
          else
            true
          end
        end)
        |> Stream.map(&parse_auction_item_record/1)
        |> Stream.filter(fn auction ->
          if(search, do: auction.title =~ search, else: true) &&
            if cateogry_id, do: auction.category_id == cateogry_id, else: true
        end)
        |> Stream.drop(skip)
        |> Stream.take(take)
        |> Enum.to_list()
      end
    end

    @spec get_by_id(pos_integer()) :: {:ok, t()} | {:error, :not_found}
    @doc """
    Reads auction auction in transaction
    """
    def get_by_id(auction_id) when is_number(auction_id) do
      Amnesia.transaction do
        read(auction_id)
      end
      |> case do
        nil -> {:error, :not_found}
        found -> {:ok, found}
      end
    end

    @spec with_data(pos_integer()) ::
            {:ok, t()} | {:error, :auction_not_found | :user_not_found | :category_not_found}
    def with_data(auction_id) when is_number(auction_id) do
      Amnesia.transaction do
        with {:auction, {:ok, auction}} <- {:auction, get_by_id(auction_id)},
             {:user, {:ok, user}} <- {:user, User.get_by_id(auction.user_id)},
             {:category, {:ok, category}} <-
               {:category, AuctionItemCategory.get_by_id(auction.category_id)} do
          auction_with_additional_info =
            auction
            |> Map.put(:username, user.username)
            |> Map.put(:category, category.title)

          {:ok, auction_with_additional_info}
        else
          {:auction, {:error, :not_found}} ->
            {:error, :auction_not_found}

          {:user, {:error, :not_found}} ->
            {:error, :user_not_found}

          {:category, {:error, :not_found}} ->
            {:error, :category_not_found}
        end
      end
    end

    @spec get_user_auctions(pos_integer()) :: [t()]
    def get_user_auctions(user_id) when is_number(user_id) do
      Amnesia.transaction do
        match(user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    @spec get_category_auctions(pos_integer(), pos_integer(), pos_integer()) :: [t()]
    def get_category_auctions(category_id, skip \\ 0, take \\ 10)
        when is_number(category_id) and is_number(skip) and is_number(take) do
      Amnesia.transaction do
        stream()
        |> Stream.filter(&(&1.category_id == category_id))
        |> Stream.drop(skip)
        |> Stream.take(take)
        |> Enum.to_list()
      end
    end

    @spec update_auction(t(), pos_integer() | atom()) ::
            {:ok, t()} | {:error, :not_found | :user_not_found | :forbidden}
    def update_auction(%AuctionItem{} = auction_item, user_id)
        when is_number(user_id) or is_atom(user_id) do
      Amnesia.transaction do
        with {:user, {:ok, user}} <- {:user, User.get_by_id(user_id)},
             {:auction, {:ok, found}} <- {:auction, get_by_id(auction_item.id)},
             {:worthy, true} <- {:worthy, user_id == found.user_id or user.is_admin} do
          {:ok, write(auction_item)}
        else
          {:user, {:error, :not_found}} ->
            {:error, :user_not_found}

          {:auction, {:error, :not_found} = error} ->
            error

          {:worthy, false} ->
            {:error, :forbidden}
        end
      end
    end

    @spec place_bid(pos_integer(), pos_integer() | atom(), pos_integer()) ::
            {:ok, AuctionBid.t()}
            | {:error, :not_found | :small_bid | :bidding_ended | :auction_postponed}
    def place_bid(auction_id, user_id, amount)
        when is_number(auction_id) and (is_atom(user_id) or is_number(user_id)) and
               is_number(amount) do
      Amnesia.transaction do
        auction = read(auction_id)

        if auction == nil do
          {:error, :not_found}
        else
          case auction_bidding_status(auction) do
            {:ok, :ongoing} ->
              case try_add_bid(auction.id, user_id, auction.minimum_bid_step, amount) do
                {:ok, _} = result ->
                  Logger.debug("Bid placed for auction: #{auction_id} by user: #{user_id}")
                  result

                {:error, :small_bid} = error ->
                  error
              end

            {:ok, :postponed} ->
              {:error, :auction_postponed}

            {:ok, :ended} ->
              {:error, :bidding_ended}
          end
        end
      end
    end

    @spec user_id_authorized?(pos_integer(), pos_integer() | atom()) ::
            boolean() | {:error, :not_found | :user_not_found}
    def user_id_authorized?(auction_id, user_id)
        when is_number(auction_id) and (is_number(user_id) or is_atom(user_id)) do
      Amnesia.transaction do
        user_owner? =
          auction_id
          |> get_by_id()
          |> case do
            {:ok, %{user_id: ^user_id}} -> {:ok, true}
            {:ok, _} -> {:ok, false}
            {:error, :not_found} = error -> error
          end

        case user_owner? do
          {:ok, true} ->
            true

          {:ok, false} ->
            user_id
            |> User.get_by_id()
            |> case do
              {:ok, %User{is_admin: is_admin}} ->
                is_admin

              {:error, :not_found} ->
                {:error, :user_not_found}
            end

          {:error, :not_found} = error ->
            error
        end
      end
    end

    @spec delete_auction(pos_integer()) :: {:ok, t()} | {:error, :not_found}
    def delete_auction(auction_id) when is_number(auction_id) do
      Amnesia.transaction do
        existing = read(auction_id)

        if existing == nil do
          {:error, :not_found}
        else
          AuctionBid.delete_auction_bids(auction_id)
          UserInAuction.delete_auction_users(auction_id)

          delete(auction_id)
          {:ok, existing}
        end
      end
    end

    @spec delete_user_auctions(pos_integer()) :: :ok
    def delete_user_auctions(user_id) when is_number(user_id) do
      user_id
      |> get_user_auctions()
      |> Enum.map(& &1.id)
      |> Enum.each(&delete_auction/1)
    end

    defp parse_auction_item_record(
           {AuctionItem, id, user_id, title, category_id, start_price, minimum_bid_step,
            bidding_start, bidding_end, inserted_at}
         ) do
      %AuctionItem{
        id: id,
        user_id: user_id,
        title: title,
        category_id: category_id,
        start_price: start_price,
        minimum_bid_step: minimum_bid_step,
        bidding_end: bidding_end,
        bidding_start: bidding_start,
        inserted_at: inserted_at
      }
    end

    defp try_add_bid(auction_id, user_id, minimum_bid_step, amount) do
      if AuctionBid.is_amount_highest?(auction_id, minimum_bid_step, amount) do
        new_bind =
          AuctionBid.new_bid(auction_id, user_id, amount)
          |> AuctionBid.write()

        {:ok, new_bind}
      else
        {:error, :small_bid}
      end
    end

    @spec auction_bidding_status(t()) ::
            {:ok, :ended | :ongoing | :postponed} | {:error, binary(), t()}
    defp auction_bidding_status(auction) do
      now = DateTime.now!(Common.timezone())
      bidding_start_comparison = DateTime.compare(auction.bidding_start, now)

      cond do
        DateTime.compare(auction.bidding_end, now) in [:lt, :eq] ->
          {:ok, :ended}

        bidding_start_comparison in [:lt, :eq] ->
          {:ok, :ongoing}

        bidding_start_comparison == :gt ->
          {:ok, :postponed}

        true ->
          {:error, "bidding_start or bidding_end prop has invalid value...", auction}
      end
    end
  end

  deftable(
    AuctionBid,
    [{:id, autoincrement}, :user_id, :auction_id, :inserted_at, :amount],
    type: :ordered_set,
    index: [:auction_id, :amount]
  ) do
    @type cents() :: pos_integer()

    @type t() :: %AuctionBid{
            id: pos_integer(),
            user_id: pos_integer(),
            auction_id: pos_integer(),
            inserted_at: DateTime.t(),
            amount: cents()
          }

    require Logger

    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    @spec write_bid(t()) :: :ok
    def write_bid(bid) do
      Amnesia.transaction do
        write(bid)

        :ok
      end
    end

    @spec get_user_bids(pos_integer()) :: [t()]
    def get_user_bids(user_id) when is_number(user_id) do
      Amnesia.transaction do
        match(user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    @spec get_user_auction_bids(pos_integer(), pos_integer()) :: [t()]
    def get_user_auction_bids(auction_id, user_id) when is_number(user_id) do
      Amnesia.transaction do
        match(auction_id: auction_id, user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    def get_auction_bids(auction_id) when is_number(auction_id) do
      Amnesia.transaction do
        match(auction_id: auction_id)
        |> Amnesia.Selection.values()
      end
    end

    @spec with_data(list(t())) :: list(t())
    def with_data(auction_bids) when is_list(auction_bids) do
      Amnesia.transaction do
        auction_bids
        |> Enum.map(fn bid ->
          with {:user, {:ok, user}} <- {:user, get_user_from_bid(bid)} do
            updated_bid =
              bid
              |> Map.put(:user_display_name, user.display_name)

            updated_bid
          else
            {:user, {:error, :not_found}} ->
              Logger.error("Could not find username for auction bid", bid: bid)
              bid
          end
        end)
      end
    end

    @spec is_amount_highest?(pos_integer(), pos_integer(), pos_integer()) :: boolean()
    def is_amount_highest?(auction_id_param, minimum_bid_step, amount_param)
        when is_number(auction_id_param) and is_number(amount_param) do
      Amnesia.transaction do
        where(auction_id == auction_id_param and amount + minimum_bid_step > amount_param)
        |> Amnesia.Selection.values()
        |> Enum.empty?()
      end
    end

    @spec get_auction_highest_bid(pos_integer(), pos_integer()) :: [t()]
    def get_auction_highest_bid(auction_id, highest_count \\ 1)
        when is_number(auction_id) and is_number(highest_count) do
      Amnesia.transaction do
        match(auction_id: auction_id)
        |> Amnesia.Selection.values()
        |> Enum.sort_by(& &1.amount, :desc)
        |> Enum.take(highest_count)
      end
    end

    @spec delete_user_bids(pos_integer()) :: :ok
    def delete_user_bids(user_id) when is_number(user_id) do
      user_id
      |> get_user_bids()
      |> Enum.map(& &1.id)
      |> Enum.each(&delete/1)
    end

    @spec delete_auction_bids(pos_integer()) :: :ok
    def delete_auction_bids(auction_id) when is_number(auction_id) do
      Amnesia.transaction do
        match(auction_id: auction_id)
        |> Amnesia.Selection.values()
        |> Enum.map(& &1.id)
        |> Enum.each(&delete/1)
      end
    end

    @spec new_bid(pos_integer() | nil, pos_integer() | atom(), pos_integer()) :: t()
    @doc """
    Returns new struct with given data
    """
    def new_bid(auction_id, user_id, amount)
        when is_number(auction_id) and (is_number(user_id) or is_atom(user_id)) and
               is_number(amount) do
      %AuctionBid{
        auction_id: auction_id,
        user_id: user_id,
        amount: amount,
        inserted_at: DateTime.now!(Common.timezone())
      }
    end

    defp get_user_from_bid(%AuctionBid{user_id: user_id}) do
      User.get_by_id(user_id)
    end
  end

  deftable UserInAuction, [{:id, autoincrement}, :user_id, :auction_id, :joined],
    index: [:user_id, :auction_id] do
    @moduledoc """
    This table holds informations on users joined in auctions
    """

    @type t() :: %UserInAuction{
            id: pos_integer() | nil,
            user_id: pos_integer(),
            auction_id: pos_integer(),
            joined: boolean()
          }

    require Protocol
    Protocol.derive(Jason.Encoder, __MODULE__)

    @spec add_user_to_auction(pos_integer(), pos_integer()) :: {:ok, t()} | {:error, :exists}
    def add_user_to_auction(auction_id, user_id, join \\ true)
        when is_number(user_id) and is_number(auction_id) do
      Amnesia.transaction do
        match(user_id: user_id, auction_id: auction_id)
        |> Amnesia.Selection.values()
        |> case do
          [] ->
            result =
              new_user_in_auction(user_id, auction_id, join)
              |> write()

            {:ok, result}

          [%{joined: ^join} = found] ->
            {:ok, found}

          [found] ->
            updated =
              found
              |> Map.put(:joined, join)
              |> write()

            {:ok, updated}
        end
      end
    end

    @spec remove_user_from_auction(pos_integer(), pos_integer()) ::
            {:ok, :removed | :bidding_left} | {:error, :not_found | :already_bidded}
    def remove_user_from_auction(auction_id, user_id)
        when is_number(auction_id) and is_number(user_id) do
      Amnesia.transaction do
        match(auction_id: auction_id, user_id: user_id)
        |> Amnesia.Selection.values()
        |> case do
          [] ->
            {:error, :not_found}

          [%{id: id, joined: false}] ->
            delete(id)
            {:ok, :removed}

          [%{joined: true} = x] ->
            case AuctionBid.get_auction_highest_bid(auction_id) do
              [%{user_id: ^user_id}] ->
                {:error, :already_bidded}

              _ ->
                x
                |> Map.put(:joined, false)
                |> write()

                {:ok, :bidding_left}
            end
        end
      end
    end

    @spec delete_auction_users(pos_integer()) :: :ok
    def delete_auction_users(auction_id) when is_number(auction_id) do
      Amnesia.transaction do
        match(auction_id: auction_id)
        |> Amnesia.Selection.values()
        |> Enum.map(& &1.id)
        |> Enum.each(&delete/1)
      end
    end

    @spec toggle_followed_auction(pos_integer(), pos_integer()) ::
            {:ok, :following | :not_following} | {:error, :joined}
    def toggle_followed_auction(auction_id, user_id)
        when is_number(auction_id) and is_number(user_id) do
      Amnesia.transaction do
        match(auction_id: auction_id, user_id: user_id)
        |> Amnesia.Selection.values()
        |> case do
          [] ->
            {:ok, _} = add_user_to_auction(auction_id, user_id, false)
            {:ok, :following}

          [%{id: id, joined: false}] ->
            delete(id)
            {:ok, :not_following}

          [%{joined: true}] ->
            {:error, :joined}
        end
      end
    end

    @spec user_in_auction?(pos_integer(), pos_integer()) :: boolean()
    def user_in_auction?(auction_id, user_id) when is_number(auction_id) and is_number(user_id) do
      Amnesia.transaction do
        match(auction_id: auction_id, user_id: user_id)
        |> Amnesia.Selection.values()
        |> Enum.any?()
      end
    end

    @spec get_auction_users(pos_integer()) :: [{:ok, User.t()} | {:error, :not_found}]
    def get_auction_users(auction_id) when is_number(auction_id) do
      Amnesia.transaction do
        match(auction_id: auction_id)
        |> Amnesia.Selection.values()
        |> Enum.map(&User.get_by_id(&1.user_id))
      end
    end

    @spec get_user_auctions(pos_integer()) :: [t()]
    def get_user_auctions(user_id) when is_number(user_id) do
      Amnesia.transaction do
        match(user_id: user_id)
        |> Amnesia.Selection.values()
      end
    end

    @spec get_user_status(pos_integer(), pos_integer()) ::
            {:ok, :following | :joined} | {:error, :not_found}
    def get_user_status(auction_id, user_id) when is_number(auction_id) and is_number(user_id) do
      Amnesia.transaction do
        match(auction_id: auction_id, user_id: user_id)
        |> Amnesia.Selection.values()
        |> case do
          [] ->
            {:error, :not_found}

          [%{joined: false}] ->
            {:ok, :following}

          [%{joined: true}] ->
            {:ok, :joined}
        end
      end
    end

    defp new_user_in_auction(user_id, auction_id, join) do
      %UserInAuction{
        user_id: user_id,
        auction_id: auction_id,
        joined: join
      }
    end
  end
end
