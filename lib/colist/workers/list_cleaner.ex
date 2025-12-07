defmodule Colist.Workers.ListCleaner do
  use GenServer
  require Logger

  @check_interval :timer.minutes(1)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_check()
    {:ok, state}
  end

  @impl true
  def handle_info(:clean_expired, state) do
    deleted_count = clean_expired_lists()

    if deleted_count > 0 do
      Logger.info("Deleted #{deleted_count} expired list(s)")
    end

    schedule_check()
    {:noreply, state}
  end

  defp schedule_check do
    Process.send_after(self(), :clean_expired, @check_interval)
  end

  defp clean_expired_lists do
    import Ecto.Query, warn: false
    alias Colist.Repo
    alias Colist.Lists.List

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {deleted_count, _} =
      from(l in List, where: not is_nil(l.expires_at) and l.expires_at <= ^now)
      |> Repo.delete_all()

    deleted_count
  end
end
