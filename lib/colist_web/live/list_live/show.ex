defmodule ColistWeb.ListLive.Show do
  use ColistWeb, :live_view

  alias Colist.Lists
  alias Colist.RateLimit

  @topic "todo"

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    ColistWeb.Endpoint.subscribe(@topic <> ":#{slug}")
    list = Lists.get_list_by_slug!(slug)
    items = list_items(list.id, nil)
    completed_count = Enum.count(items, & &1.completed)

    client_ip = get_client_ip(socket)

    {:ok,
     socket
     |> assign(:page_title, gettext("List"))
     |> assign(:list, list)
     |> assign(:client_ip, client_ip)
     |> assign(:client_id, nil)
     |> assign(:user_color, nil)
     |> assign(:current_user, nil)
     |> assign(:changing_from, nil)
     |> assign(:presence_count, 0)
     |> assign(:editing_item_id, nil)
     |> assign(:total_items, length(items))
     |> assign(:completed_items, completed_count)
     |> stream(:items, items)
     |> stream(:presences, [], limit: 10)
     |> assign(:form, to_form(Lists.change_item(%Lists.Item{})))}
  end

  defp list_items(list_id, nil = _voter_id) do
    Lists.list_items_by_list_id(list_id)
  end

  defp list_items(list_id, voter_id) do
    Lists.list_items_with_votes(list_id, voter_id)
  end

  defp get_client_ip(socket) do
    case get_connect_info(socket, :x_headers) do
      headers when is_list(headers) ->
        case List.keyfind(headers, "x-forwarded-for", 0) do
          {"x-forwarded-for", value} ->
            value |> String.split(",") |> List.first() |> String.trim()

          nil ->
            get_peer_ip(socket)
        end

      _ ->
        get_peer_ip(socket)
    end
  end

  defp get_peer_ip(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: ip} -> ip |> :inet.ntoa() |> to_string()
      _ -> "unknown"
    end
  end

  @impl true
  def handle_event("set_client_id", %{"client_id" => client_id}, socket) do
    user_color = hsl_color(client_id)
    # Reload items with vote data now that we have the client_id
    items = list_items(socket.assigns.list.id, client_id)

    {:noreply,
     socket
     |> assign(:client_id, client_id)
     |> assign(:user_color, user_color)
     |> stream(:items, items, reset: true)
     |> push_event("client_ready", %{})}
  end

  def handle_event("validate", %{"item" => item_params}, socket) do
    changeset =
      %Lists.Item{}
      |> Lists.change_item(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"item" => item_params}, socket) do
    save_item(socket, socket.assigns.live_action, item_params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    item = Lists.get_item!(id)
    {:ok, _} = Lists.delete_item(item)

    broadcast(socket.assigns.list.slug, "item_deleted", %{item: item})

    socket =
      socket
      |> update(:total_items, &(&1 - 1))
      |> then(fn s -> if item.completed, do: update(s, :completed_items, &(&1 - 1)), else: s end)
      |> stream_delete(:items, item)

    {:noreply, socket}
  end

  def handle_event("toggle_completion", %{"id" => id}, socket) do
    item = Lists.get_item!(id)

    case Lists.update_item(item, %{completed: !item.completed}) do
      {:ok, updated_item} ->
        # Reload with vote data
        updated_item = Lists.load_item_votes(updated_item, socket.assigns.client_id)
        broadcast(socket.assigns.list.slug, "item_updated", %{item: updated_item})

        socket =
          socket
          |> update(:completed_items, &if(updated_item.completed, do: &1 + 1, else: &1 - 1))
          |> stream_insert(:items, updated_item)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update item"))}
    end
  end

  def handle_event("toggle_vote", %{"id" => id}, socket) do
    voter_id = socket.assigns.client_id

    if voter_id do
      case Lists.toggle_vote(id, voter_id) do
        {:ok, action} ->
          broadcast(socket.assigns.list.slug, "item_voted", %{item_id: id, action: action})

          # Get sorted items and extract order
          items = list_items(socket.assigns.list.id, voter_id)
          sorted_ids = Enum.map(items, & &1.id)

          # Update items in stream (without reset) and push reorder to client
          socket =
            Enum.reduce(items, socket, fn item, acc ->
              stream_insert(acc, :items, item)
            end)

          {:noreply, push_event(socket, "reorder_items", %{ids: sorted_ids})}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to vote"))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("start_edit", %{"id" => id}, socket) do
    item = Lists.get_item!(id) |> Lists.load_item_votes(socket.assigns.client_id)

    {:noreply,
     socket
     |> assign(:editing_item_id, id)
     |> stream_insert(:items, item)}
  end

  def handle_event("save_edit", %{"id" => id, "value" => text}, socket) do
    item = Lists.get_item!(id)
    text = String.trim(text)

    if text != "" and text != item.text do
      case Lists.update_item(item, %{text: text}) do
        {:ok, updated_item} ->
          updated_item = Lists.load_item_votes(updated_item, socket.assigns.client_id)
          broadcast(socket.assigns.list.slug, "item_updated", %{item: updated_item})

          {:noreply,
           socket
           |> assign(:editing_item_id, nil)
           |> stream_insert(:items, updated_item)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to update item"))}
      end
    else
      item = Lists.load_item_votes(item, socket.assigns.client_id)

      {:noreply,
       socket
       |> assign(:editing_item_id, nil)
       |> stream_insert(:items, item)}
    end
  end

  def handle_event("edit_keydown", %{"key" => "Enter", "id" => id, "value" => text}, socket) do
    handle_event("save_edit", %{"id" => id, "value" => text}, socket)
  end

  def handle_event("edit_keydown", %{"key" => "Escape", "id" => id}, socket) do
    item = Lists.get_item!(id) |> Lists.load_item_votes(socket.assigns.client_id)

    {:noreply,
     socket
     |> assign(:editing_item_id, nil)
     |> stream_insert(:items, item)}
  end

  def handle_event("edit_keydown", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("copied_url", _params, socket) do
    {:noreply, put_flash(socket, :info, gettext("URL copied to clipboard!"))}
  end

  def handle_event("update_title", %{"value" => title}, socket) do
    list = socket.assigns.list

    if title != list.title && String.trim(title) != "" do
      case Lists.update_list(list, %{title: title}) do
        {:ok, updated_list} ->
          broadcast(list.slug, "list_updated", %{list: updated_list})
          {:noreply, assign(socket, :list, updated_list)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to update title"))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("reorder", %{"ids" => ids}, socket) do
    Lists.update_item_positions(ids)
    broadcast(socket.assigns.list.slug, "items_reordered", %{ids: ids})
    {:noreply, socket}
  end

  def handle_event("clear_completed", _params, socket) do
    list_id = socket.assigns.list.id
    completed_items = Lists.list_completed_items(list_id)

    Enum.each(completed_items, fn item ->
      Lists.delete_item(item)
      broadcast(socket.assigns.list.slug, "item_deleted", %{item: item})
    end)

    {:noreply,
     socket
     |> assign(:completed_items, 0)
     |> update(:total_items, &(&1 - length(completed_items)))
     |> stream(:items, list_items(list_id, socket.assigns.client_id), reset: true)}
  end

  def handle_event("no_name", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("set_presence", %{"value" => name}, socket) do
    slug = socket.assigns.list.slug
    old_name = socket.assigns.current_user

    # Ensure we have a color - fallback to generating from client_id if somehow nil
    color = socket.assigns.user_color || hsl_color(socket.assigns.client_id)

    if connected?(socket) and socket.assigns.client_id do
      if old_name do
        ColistWeb.Presence.untrack_user(slug, old_name)
        ColistWeb.Presence.track_user(slug, name, %{id: name, color: color})

        {:noreply,
         socket
         |> assign(:current_user, name)
         |> assign(:changing_from, old_name)
         |> push_event("store", %{key: "username", data: name})}
      else
        ColistWeb.Presence.track_user(slug, name, %{id: name, color: color})
        ColistWeb.Presence.subscribe(slug)
        presences = ColistWeb.Presence.list_online_users(slug)

        {:noreply,
         socket
         |> assign(:current_user, name)
         |> assign(:presence_count, length(presences))
         |> stream(:presences, presences, reset: true)
         |> push_event("store", %{key: "username", data: name})}
      end
    else
      {:noreply, socket}
    end
  end

  defp save_item(socket, :show, item_params) do
    if is_nil(socket.assigns.client_id) do
      {:noreply, socket}
    else
      case RateLimit.check_item_creation(socket.assigns.client_ip) do
        :ok ->
          create_item(socket, item_params)

        {:error, :rate_limited, _retry_after} ->
          {:noreply,
           socket
           |> put_flash(:error, gettext("Too many items created. Please try again later."))
           |> assign(:form, to_form(Lists.change_item(%Lists.Item{})))}
      end
    end
  end

  defp create_item(socket, item_params) do
    item_params =
      item_params
      |> Map.put("list_id", socket.assigns.list.id)
      |> Map.put("creator_id", socket.assigns.client_id)

    if item_params["text"] |> String.trim() == "" do
      {:noreply, assign(socket, :form, to_form(Lists.change_item(%Lists.Item{})))}
    else
      case Lists.create_item(item_params) do
        {:ok, item} ->
          broadcast(socket.assigns.list.slug, "item_created", %{item: item})

          {:noreply,
           socket
           |> update(:total_items, &(&1 + 1))
           |> stream_insert(:items, item)
           |> assign(:form, to_form(Lists.change_item(%Lists.Item{})))}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    end
  end

  defp broadcast(slug, event, %{} = payload) do
    ColistWeb.Endpoint.broadcast_from!(self(), @topic <> ":#{slug}", event, payload)
  end

  @impl true
  def handle_info(%{event: "item_created", payload: %{item: item}}, socket) do
    # Load vote data for the new item
    item = Lists.load_item_votes(item, socket.assigns.client_id)

    {:noreply,
     socket
     |> update(:total_items, &(&1 + 1))
     |> stream_insert(:items, item, at: -1)}
  end

  def handle_info(%{event: "item_updated", payload: %{item: item}}, socket) do
    items = list_items(socket.assigns.list.id, socket.assigns.client_id)
    completed_count = Enum.count(items, & &1.completed)
    # Reload item with current user's vote status
    item = Lists.load_item_votes(item, socket.assigns.client_id)

    {:noreply,
     socket
     |> assign(:completed_items, completed_count)
     |> stream_insert(:items, item)}
  end

  def handle_info(%{event: "item_deleted", payload: %{item: item}}, socket) do
    socket =
      socket
      |> update(:total_items, &max(&1 - 1, 0))
      |> then(fn s ->
        if item.completed, do: update(s, :completed_items, &max(&1 - 1, 0)), else: s
      end)
      |> stream_delete(:items, item)

    {:noreply, socket}
  end

  def handle_info(%{event: "list_updated", payload: %{list: list}}, socket) do
    {:noreply, assign(socket, :list, list)}
  end

  def handle_info(%{event: "items_reordered", payload: %{ids: _ids}}, socket) do
    {:noreply,
     stream(socket, :items, list_items(socket.assigns.list.id, socket.assigns.client_id),
       reset: true
     )}
  end

  def handle_info(%{event: "item_voted", payload: %{item_id: _item_id}}, socket) do
    # Another user voted - get sorted items and animate reorder
    items = list_items(socket.assigns.list.id, socket.assigns.client_id)
    sorted_ids = Enum.map(items, & &1.id)

    # Update items in stream (without reset) and push reorder to client
    socket =
      Enum.reduce(items, socket, fn item, acc ->
        stream_insert(acc, :items, item)
      end)

    {:noreply, push_event(socket, "reorder_items", %{ids: sorted_ids})}
  end

  def handle_info({ColistWeb.Presence, {:join, presence}}, socket) do
    socket =
      if presence.id != socket.assigns.current_user do
        update(socket, :presence_count, &(&1 + 1))
      else
        socket
      end

    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({ColistWeb.Presence, {:leave, presence}}, socket) do
    if presence.metas == [] do
      if presence.id == socket.assigns.changing_from do
        {:noreply,
         socket
         |> assign(:changing_from, nil)
         |> stream_delete(:presences, presence)}
      else
        socket =
          if presence.id != socket.assigns.current_user do
            update(socket, :presence_count, &max(&1 - 1, 0))
          else
            socket
          end

        {:noreply, stream_delete(socket, :presences, presence)}
      end
    else
      {:noreply, stream_insert(socket, :presences, presence)}
    end
  end
end
