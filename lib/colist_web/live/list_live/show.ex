defmodule ColistWeb.ListLive.Show do
  use ColistWeb, :live_view

  alias Colist.Lists
  alias Colist.RateLimit

  @topic "todo"

  defp hsl_color(nil), do: nil

  defp hsl_color(id) do
    hue = :erlang.phash2(id, 360)
    "hsl(#{hue}, 70%, 60%)"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <header
        class="flex items-center justify-between gap-6 pb-4"
        phx-hook="LocalStoreData"
        id="list-header"
      >
        <input
          type="text"
          name="title"
          value={@list.title}
          phx-blur="update_title"
          phx-keydown="update_title"
          phx-key="Enter"
          class="text-lg font-semibold leading-8 bg-transparent border-none outline-none w-full focus:bg-base-200 focus:px-2 focus:-mx-2 rounded transition-all"
          placeholder="Untitled"
        />
        <div class="flex-none flex items-center gap-2">
          <button
            class="btn btn-ghost btn-sm gap-1"
            onclick="presences_modal.showModal()"
          >
            <.icon name="hero-users" class="size-4" />
            <span class="badge badge-sm">{@presence_count}</span>
          </button>
          <.button phx-hook="CopyUrl" id="copy-url-btn">
            <.icon name="hero-link" />
          </.button>
        </div>
      </header>

      <dialog id="presences_modal" class="modal">
        <div class="modal-box">
          <form method="dialog">
            <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">
              ✕
            </button>
          </form>
          <h3 class="text-lg font-bold mb-4">Who's here</h3>
          <ul id="presences-list" phx-update="stream" class="space-y-2">
            <li
              :for={{id, presence} <- @streams.presences}
              id={id}
              class="flex items-center gap-2"
            >
              <span
                class="w-3 h-3 rounded-full"
                style={"background-color: #{presence.color || "oklch(0.872 0.01 258.338)"}"}
              ></span>
              <span>{presence.user.name}</span>
              <span :if={presence.id == @current_user} class="badge badge-xs">you</span>
              <button
                :if={presence.id == @current_user}
                class="btn btn-ghost btn-xs"
                onclick="presences_modal.close(); name_modal.showModal();"
              >
                <.icon name="hero-pencil-square" class="size-3" />
              </button>
            </li>
          </ul>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button class="cursor-pointer" onclick="document.getElementById('presences_modal').close()">close</button>
        </form>
      </dialog>

      <dialog id="name_modal" class="modal">
        <div class="modal-box">
          <form method="dialog">
            <button
              id="close-name-modal"
              class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
            >
              ✕
            </button>
          </form>
          <h3 class="text-lg font-bold">Hello!</h3>
          <p class="py-4">Enter your name:</p>

          <form phx-submit={JS.push("set_presence") |> JS.dispatch("click", to: "#close-name-modal")}>
            <input
              id="name-input"
              name="value"
              type="text"
              value={@current_user}
              placeholder="Enter your name"
              class="input input-bordered w-full"
            />
            <div class="modal-action">
              <button
                type="submit"
                class="btn btn-primary"
                phx-disable-with="Joining..."
              >
                Set Name
              </button>
            </div>
          </form>
        </div>
      </dialog>

      <.form for={@form} id="item-form" phx-change="validate" phx-submit="save" class="flex gap-2 items-start">
        <div class="flex-1">
          <.input
            id="new-item-input"
            field={@form[:text]}
            type="text"
            placeholder="Add a task..."
            class="input input-ghost w-full text-base focus:input-bordered focus:bg-base-100"
          />
        </div>
        <button
          type="submit"
          class="btn btn-primary btn-square md:hidden mt-1"
        >
          <.icon name="hero-paper-airplane" class="size-5 -rotate-45" />
        </button>
      </.form>

      <div
        :if={@total_items > 0}
        class="flex items-center justify-between text-sm text-base-content/60 mb-2"
      >
        <span>{@completed_items}/{@total_items} completed</span>
        <button
          :if={@completed_items > 0}
          phx-click="clear_completed"
          class="text-xs hover:text-error transition-colors"
        >
          Clear completed
        </button>
      </div>

      <ul
        class="bg-base-100 rounded-box shadow-md"
        id="items"
        phx-update="stream"
        phx-hook="DragNDrop"
      >
        <li id="items-empty" class="hidden only:block py-8 px-4 text-center text-base-content/50">
          <p class="mb-2">No tasks yet. Add one above!</p>
          <p class="text-xs">
            Share the URL to collaborate • Changes sync in real-time
          </p>
        </li>
        <li
          :for={{item_id, item} <- @streams.items}
          class={["flex items-center gap-2 py-2 px-4 sm:px-3 group", item.completed && "opacity-50"]}
          id={item_id}
        >
          <span class="drag-handle cursor-grab active:cursor-grabbing opacity-30 hover:opacity-100 touch-none p-2 -m-2 sm:p-0 sm:m-0">
            <.icon name="hero-bars-2" class="size-5 sm:size-4" />
          </span>
          <span
            class="w-2 h-2 rounded-full shrink-0"
            style={"background-color: #{hsl_color(item.creator_id) || "oklch(0.872 0.01 258.338)"}"}
          >
          </span>
          <input
            id={"complete-item-#{item.id}"}
            type="checkbox"
            checked={item.completed}
            phx-click={JS.push("toggle_completion", value: %{id: item.id})}
            class="checkbox checkbox-sm"
          />
          <input
            :if={@editing_item_id == item.id}
            type="text"
            value={item.text}
            phx-blur="save_edit"
            phx-keydown="edit_keydown"
            phx-value-id={item.id}
            phx-mounted={JS.focus()}
            class="flex-1 bg-transparent border-none outline-none"
            id={"edit-item-#{item.id}"}
          />
          <span
            :if={@editing_item_id != item.id}
            class={["flex-1 cursor-text", item.completed && "line-through"]}
            phx-click={JS.push("start_edit", value: %{id: item.id})}
          >
            {item.text}
          </span>
          <button
            class="btn btn-square btn-ghost btn-sm opacity-40 sm:opacity-0 sm:group-hover:opacity-100 text-error"
            phx-click={
              JS.push("delete", value: %{id: item.id})
              |> hide("##{item_id}")
            }
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </li>
      </ul>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    ColistWeb.Endpoint.subscribe(@topic <> ":#{slug}")
    list = Lists.get_list_by_slug!(slug)
    items = list_items(list.id)
    completed_count = Enum.count(items, & &1.completed)

    client_ip = get_client_ip(socket)

    {:ok,
     socket
     |> assign(:page_title, "List")
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

  defp list_items(list_id) do
    Lists.list_items_by_list_id(list_id)
  end

  defp get_client_ip(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: ip} -> ip |> :inet.ntoa() |> to_string()
      _ -> "unknown"
    end
  end

  @impl true
  def handle_event("set_client_id", %{"client_id" => client_id}, socket) do
    user_color = hsl_color(client_id)

    {:noreply,
     socket
     |> assign(:client_id, client_id)
     |> assign(:user_color, user_color)}
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
        broadcast(socket.assigns.list.slug, "item_updated", %{item: updated_item})

        socket =
          socket
          |> update(:completed_items, &if(updated_item.completed, do: &1 + 1, else: &1 - 1))
          |> stream_insert(:items, updated_item)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update item")}
    end
  end

  def handle_event("start_edit", %{"id" => id}, socket) do
    item = Lists.get_item!(id)

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
          broadcast(socket.assigns.list.slug, "item_updated", %{item: updated_item})

          {:noreply,
           socket
           |> assign(:editing_item_id, nil)
           |> stream_insert(:items, updated_item)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update item")}
      end
    else
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
    item = Lists.get_item!(id)

    {:noreply,
     socket
     |> assign(:editing_item_id, nil)
     |> stream_insert(:items, item)}
  end

  def handle_event("edit_keydown", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("copied_url", _params, socket) do
    {:noreply, put_flash(socket, :info, "URL copied to clipboard!")}
  end

  def handle_event("update_title", %{"value" => title}, socket) do
    list = socket.assigns.list

    if title != list.title && String.trim(title) != "" do
      case Lists.update_list(list, %{title: title}) do
        {:ok, updated_list} ->
          broadcast(list.slug, "list_updated", %{list: updated_list})
          {:noreply, assign(socket, :list, updated_list)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update title")}
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
     |> stream(:items, list_items(list_id), reset: true)}
  end

  def handle_event("no_name", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("set_presence", %{"value" => name}, socket) do
    slug = socket.assigns.list.slug
    old_name = socket.assigns.current_user
    color = socket.assigns.user_color

    if connected?(socket) do
      if old_name do
        ColistWeb.Presence.untrack_user(slug, old_name)
        ColistWeb.Presence.track_user(slug, name, %{id: name, color: color})
        # Track old name so leave handler ignores it
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
    case RateLimit.check_item_creation(socket.assigns.client_ip) do
      :ok ->
        create_item(socket, item_params)

      {:error, :rate_limited, _retry_after} ->
        {:noreply,
         socket
         |> put_flash(:error, "Too many items created. Please try again later.")
         |> assign(:form, to_form(Lists.change_item(%Lists.Item{})))}
    end
  end

  defp create_item(socket, item_params) do
    item_params =
      item_params
      |> Map.put("list_id", socket.assigns.list.id)
      |> Map.put("creator_id", socket.assigns.client_id)

    case Lists.create_item(item_params) do
      {:ok, item} ->
        broadcast(socket.assigns.list.slug, "item_created", %{item: item})

        {:noreply,
         socket
         |> update(:total_items, &(&1 + 1))
         |> stream_insert(:items, item)
         |> assign(:form, to_form(Lists.change_item(%Lists.Item{})))
         |> push_event("focus", %{id: "new-item-input"})}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp broadcast(slug, event, %{} = payload) do
    ColistWeb.Endpoint.broadcast_from!(self(), @topic <> ":#{slug}", event, payload)
  end

  @impl true
  def handle_info(%{event: "item_created", payload: %{item: item}}, socket) do
    {:noreply,
     socket
     |> update(:total_items, &(&1 + 1))
     |> stream_insert(:items, item, at: -1)}
  end

  def handle_info(%{event: "item_updated", payload: %{item: item}}, socket) do
    # Check if completion status changed by comparing with what we expect
    # Since we track completed_items, we need to sync it
    items = list_items(socket.assigns.list.id)
    completed_count = Enum.count(items, & &1.completed)

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
    {:noreply, stream(socket, :items, list_items(socket.assigns.list.id), reset: true)}
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
      # Ignore leave event if this is our old name during a name change
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
