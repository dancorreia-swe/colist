defmodule Colist.Repo.Migrations.AddCreatorToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :creator_ip, :string
    end
  end
end
