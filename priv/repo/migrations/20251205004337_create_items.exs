defmodule Colist.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :text, :string
      add :completed, :boolean, default: false, null: false
      add :position, :integer
      add :list_id, references(:lists, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:position])
  end
end
