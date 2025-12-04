defmodule Colist.Repo do
  use Ecto.Repo,
    otp_app: :colist,
    adapter: Ecto.Adapters.Postgres
end
