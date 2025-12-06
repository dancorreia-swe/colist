defmodule Colist.Repo.Migrations.CreateLists do
  use Ecto.Migration

  def change do
    create table(:lists) do
      add :slug, :string
      add :title, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:lists, [:slug])
  end
end
