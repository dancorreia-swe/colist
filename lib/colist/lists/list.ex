defmodule Colist.Lists.List do
  alias Colist.Lists.Item
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :title]}

  schema "lists" do
    field :slug, :string
    field :title, :string
    has_many :items, Item

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(list, attrs) do
    list
    |> cast(attrs, [:slug, :title])
    |> validate_required([:slug, :title])
    |> unique_constraint(:slug)
  end
end
