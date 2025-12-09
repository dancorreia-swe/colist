defmodule Colist.Lists.Item do
  use Ecto.Schema

  alias Colist.Lists.{List, ItemVote}

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :text, :completed, :position, :list_id, :creator_id]}

  schema "items" do
    field :text, :string
    field :completed, :boolean, default: false
    field :position, :integer
    field :creator_id, :string
    belongs_to :list, List
    has_many :votes, ItemVote

    # Virtual fields for vote display
    field :vote_count, :integer, virtual: true, default: 0
    field :voted, :boolean, virtual: true, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:text, :completed, :position, :list_id, :creator_id])
  end
end
