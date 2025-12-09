defmodule Colist.Lists.ItemVote do
  use Ecto.Schema

  import Ecto.Changeset

  alias Colist.Lists.Item

  schema "item_votes" do
    field :voter_id, :string
    belongs_to :item, Item

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item_vote, attrs) do
    item_vote
    |> cast(attrs, [:item_id, :voter_id])
    |> validate_required([:item_id, :voter_id])
  end
end
