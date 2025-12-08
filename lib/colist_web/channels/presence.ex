defmodule ColistWeb.Presence do
  use Phoenix.Presence,
    otp_app: :colist,
    pubsub_server: Colist.PubSub

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def fetch(_topic, presences) do
    for {key, %{metas: [meta | metas]}} <- presences, into: %{} do
      {key, %{metas: [meta | metas], id: meta.id, color: meta[:color], user: %{name: meta.id}}}
    end
  end

  @impl true
  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, _presence} <- joins do
      metas = Map.fetch!(presences, user_id)
      color = List.first(metas)[:color]
      user_data = %{id: user_id, color: color, user: %{name: user_id}, metas: metas}
      msg = {__MODULE__, {:join, user_data}}

      Phoenix.PubSub.local_broadcast(Colist.PubSub, "proxy:#{topic}", msg)
    end

    for {user_id, presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      color = List.first(presence.metas)[:color]
      user_data = %{id: user_id, color: color, user: %{name: user_id}, metas: metas}
      msg = {__MODULE__, {:leave, user_data}}

      Phoenix.PubSub.local_broadcast(Colist.PubSub, "proxy:#{topic}", msg)
    end

    {:ok, state}
  end

  def list_online_users(slug),
    do: list(topic(slug)) |> Enum.map(fn {_id, presence} -> presence end)

  def track_user(slug, name, params), do: track(self(), topic(slug), name, params)

  def untrack_user(slug, name), do: untrack(self(), topic(slug), name)

  def subscribe(slug), do: Phoenix.PubSub.subscribe(Colist.PubSub, "proxy:#{topic(slug)}")

  defp topic(slug), do: "list:#{slug}"
end
