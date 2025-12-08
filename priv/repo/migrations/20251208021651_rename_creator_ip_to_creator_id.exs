defmodule Colist.Repo.Migrations.RenameCreatorIpToCreatorId do
  use Ecto.Migration

  def change do
    rename table(:items), :creator_ip, to: :creator_id
  end
end
