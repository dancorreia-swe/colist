defmodule Colist.Repo.Migrations.AddExpiresAtToLists do
  use Ecto.Migration

  def change do
    alter table(:lists) do
      add :expires_at, :utc_datetime
    end
  end
end
