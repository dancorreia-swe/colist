defmodule Colist.Lists do
  @moduledoc """
  The Lists context.
  """

  import Ecto.Query, warn: false
  alias Colist.Repo

  alias Colist.Lists.List
  alias Colist.Lists.Item
  alias Colist.Lists.ItemVote

  @doc """
  Returns the list of lists.

  ## Examples

      iex> list_lists()
      [%List{}, ...]

  """
  def list_lists do
    Repo.all(List)
  end

  @doc """
  Gets a single list.

  Raises `Ecto.NoResultsError` if the List does not exist.

  ## Examples

      iex> get_list!(123)
      %List{}

      iex> get_list!(456)
      ** (Ecto.NoResultsError)

  """
  def get_list!(id), do: Repo.get!(List, id)

  def get_list_by_slug!(slug), do: Repo.get_by!(List, slug: slug)

  def get_list_with_items!(id) do
    List
    |> Repo.get!(id)
    |> Repo.preload(:items)
  end

  def unique_slug do
    slug = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)

    case Repo.get_by(List, slug: slug) do
      nil -> slug
      _ -> unique_slug()
    end
  end

  @doc """
  Creates a list.

  ## Examples

      iex> create_list(%{field: value})
      {:ok, %List{}}

      iex> create_list(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  @spec create_list(map()) :: {:ok, %List{}} | {:error, %Ecto.Changeset{}}
  def create_list(attrs) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(7, :day)
      |> DateTime.truncate(:second)

    %List{}
    |> List.changeset(Map.put(attrs, :expires_at, expires_at))
    |> Repo.insert()
  end

  @doc """
  Updates a list.

  ## Examples

      iex> update_list(list, %{field: new_value})
      {:ok, %List{}}

      iex> update_list(list, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_list(%List{} = list, attrs) do
    list
    |> List.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a list.

  ## Examples

      iex> delete_list(list)
      {:ok, %List{}}

      iex> delete_list(list)
      {:error, %Ecto.Changeset{}}

  """
  def delete_list(%List{} = list) do
    Repo.delete(list)
  end

  def delete_expired_lists do
    from(l in List, where: not is_nil(l.expires_at) and l.expires_at < ^DateTime.utc_now())
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking list changes.

  ## Examples

      iex> change_list(list)
      %Ecto.Changeset{data: %List{}}

  """
  def change_list(%List{} = list, attrs \\ %{}) do
    List.changeset(list, attrs)
  end

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Repo.all(Item)
  end

  def list_items_by_list_id(list_id) do
    list_items_flat(list_id, nil)
  end

  def list_completed_items(list_id) do
    Repo.all(from i in Item, where: i.list_id == ^list_id and i.completed == true)
  end

  def update_item_positions(ids) do
    ids
    |> Enum.with_index()
    |> Enum.each(fn {id, index} ->
      from(i in Item, where: i.id == ^id)
      |> Repo.update_all(set: [position: index])
    end)

    :ok
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  def get_item(id), do: Repo.get(Item, id)

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  # Votes

  @doc """
  Toggles a vote for an item. If the voter has already voted, removes the vote.
  Otherwise, creates a new vote.

  Returns `{:ok, :voted}` or `{:ok, :unvoted}` on success.
  """
  def toggle_vote(item_id, voter_id) do
    case Repo.get_by(ItemVote, item_id: item_id, voter_id: voter_id) do
      nil ->
        %ItemVote{}
        |> ItemVote.changeset(%{item_id: item_id, voter_id: voter_id})
        |> Repo.insert()
        |> case do
          {:ok, _vote} -> {:ok, :voted}
          {:error, changeset} -> {:error, changeset}
        end

      vote ->
        Repo.delete(vote)
        {:ok, :unvoted}
    end
  end

  @doc """
  Returns the vote count for an item.
  """
  def get_vote_count(item_id) do
    from(v in ItemVote, where: v.item_id == ^item_id, select: count(v.id))
    |> Repo.one()
  end

  @doc """
  Checks if a voter has voted for an item.
  """
  def has_voted?(item_id, voter_id) do
    Repo.exists?(from v in ItemVote, where: v.item_id == ^item_id and v.voter_id == ^voter_id)
  end

  @doc """
  Returns items for a list with vote counts and whether the given voter has voted.
  Returns Item structs with virtual fields :vote_count and :voted populated.
  """
  def list_items_with_votes(list_id, voter_id) do
    list_items_flat(list_id, voter_id)
  end

  @doc """
  Returns all items (parents and subtasks) in a flat list, ordered for display:
  - Top-level items ordered by votes desc, then position
  - Each parent's subtasks immediately follow, ordered by position
  """
  def list_items_flat(list_id, voter_id) do
    # First get all items with vote counts
    all_items =
      if voter_id do
        from(i in Item,
          where: i.list_id == ^list_id,
          left_join: v in ItemVote,
          on: v.item_id == i.id,
          left_join: my_vote in ItemVote,
          on: my_vote.item_id == i.id and my_vote.voter_id == ^voter_id,
          group_by: [i.id, my_vote.id],
          select: %{i | vote_count: count(v.id), voted: not is_nil(my_vote.id)}
        )
        |> Repo.all()
      else
        from(i in Item,
          where: i.list_id == ^list_id,
          left_join: v in ItemVote,
          on: v.item_id == i.id,
          group_by: i.id,
          select: %{i | vote_count: count(v.id), voted: false}
        )
        |> Repo.all()
      end

    # Separate parents and children
    {parents, children} = Enum.split_with(all_items, &is_nil(&1.parent_id))

    # Sort parents by votes desc, then position
    sorted_parents =
      Enum.sort_by(parents, fn p -> {-p.vote_count, p.position, p.id} end)

    # Group children by parent_id
    children_by_parent = Enum.group_by(children, & &1.parent_id)

    # Interleave: parent followed by its children
    Enum.flat_map(sorted_parents, fn parent ->
      subtasks =
        children_by_parent
        |> Map.get(parent.id, [])
        |> Enum.sort_by(fn c -> {c.position, c.id} end)

      [parent | subtasks]
    end)
  end

  @doc """
  Loads vote data for a single item.
  """
  def load_item_votes(item, voter_id) do
    vote_count = get_vote_count(item.id)
    voted = has_voted?(item.id, voter_id)
    %{item | vote_count: vote_count, voted: voted}
  end

  # Subtasks

  @doc """
  Returns subtasks for a given parent item with vote counts.
  """
  def list_subtasks(parent_id, voter_id) when is_nil(voter_id) do
    from(i in Item,
      where: i.parent_id == ^parent_id,
      left_join: v in ItemVote,
      on: v.item_id == i.id,
      group_by: i.id,
      select: %{i | vote_count: count(v.id), voted: false},
      order_by: [asc: i.position, asc: i.id]
    )
    |> Repo.all()
  end

  def list_subtasks(parent_id, voter_id) do
    from(i in Item,
      where: i.parent_id == ^parent_id,
      left_join: v in ItemVote,
      on: v.item_id == i.id,
      left_join: my_vote in ItemVote,
      on: my_vote.item_id == i.id and my_vote.voter_id == ^voter_id,
      group_by: [i.id, my_vote.id],
      select: %{i | vote_count: count(v.id), voted: not is_nil(my_vote.id)},
      order_by: [asc: i.position, asc: i.id]
    )
    |> Repo.all()
  end

  @doc """
  Creates a subtask under a parent item.
  Inherits list_id from parent.
  """
  def create_subtask(parent_id, attrs) do
    parent = get_item!(parent_id)

    attrs =
      attrs
      |> Map.put("list_id", parent.list_id)
      |> Map.put("parent_id", parent_id)

    create_item(attrs)
  end

  @doc """
  Nests an item under a parent (makes it a subtask).
  """
  def nest_item(item_id, parent_id) do
    item = get_item!(item_id)
    update_item(item, %{parent_id: parent_id})
  end

  @doc """
  Unnests an item (promotes it to top-level).
  """
  def unnest_item(item_id) do
    item = get_item!(item_id)
    update_item(item, %{parent_id: nil})
  end

  @doc """
  Updates positions for items in a flat list.
  Accepts a list of {id, parent_id} tuples representing the new order.
  """
  def update_item_positions_with_nesting(items_order) do
    items_order
    |> Enum.with_index()
    |> Enum.each(fn {{id, parent_id}, index} ->
      # Convert string IDs to integers
      id = if is_binary(id), do: String.to_integer(id), else: id

      parent_id =
        case parent_id do
          nil -> nil
          "" -> nil
          p when is_binary(p) -> String.to_integer(p)
          p -> p
        end

      from(i in Item, where: i.id == ^id)
      |> Repo.update_all(set: [position: index, parent_id: parent_id])
    end)

    :ok
  end
end
