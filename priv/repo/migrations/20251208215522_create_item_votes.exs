defmodule Colist.Repo.Migrations.CreateItemVotes do
  use Ecto.Migration

  def change do
    create table(:item_votes) do
      add :item_id, references(:items, on_delete: :delete_all)
      add :voter_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:item_votes, [:item_id, :voter_id])
  end
end
