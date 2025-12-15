defmodule Colist.Repo.Migrations.AddParentIdToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :parent_id, references(:items, on_delete: :delete_all), null: true
    end

    create index(:items, [:parent_id])
  end
end
