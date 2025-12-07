defmodule ColistWeb.ListLive.Show do
  use ColistWeb, :live_view

  alias Colist.Lists

  @topic "todo"
  @colors ~w(bg-red-400 bg-orange-400 bg-amber-400 bg-yellow-400 bg-lime-400 bg-green-400 bg-emerald-400 bg-teal-400 bg-cyan-400 bg-sky-400 bg-blue-400 bg-indigo-400 bg-violet-400 bg-purple-400 bg-fuchsia-400 bg-pink-400 bg-rose-400)

  defp user_color(nil), do: "bg-base-300"

  defp user_color(name) do
    index = :erlang.phash2(name, length(@colors))
    Enum.at(@colors, index)
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
              <span class={["w-3 h-3 rounded-full", user_color(presence.id)]}></span>
              <span>{presence.user.name}</span>
              <span :if={presence.id == @current_user} class="badge badge-xs">you</span>
            </li>
          </ul>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button>close</button>
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

          <input
            type="text"
            placeholder="Enter your name"
            phx-keydown={JS.push("set_presence") |> JS.dispatch("click", to: "#close-name-modal")}
            phx-key="Enter"
            class="input input-bordered w-full"
          />
        </div>
      </dialog>

      <.form for={@form} id="item-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:text]}
          type="text"
          placeholder="Add a task..."
          class="input input-ghost w-full text-base focus:input-bordered focus:bg-base-100"
        />
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
          class={["flex items-center gap-2 py-2 px-3 group", item.completed && "opacity-50"]}
          id={item_id}
        >
          <span class="drag-handle cursor-grab active:cursor-grabbing opacity-30 hover:opacity-100 touch-none p-2 -m-2 sm:p-0 sm:m-0">
            <.icon name="hero-bars-2" class="size-5 sm:size-4" />
          </span>
          <span
            class={["w-2 h-2 rounded-full shrink-0", user_color(@item_creators[item.id] || item.id)]}
            title={@item_creators[item.id] || "Unknown"}
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
            class="btn btn-square btn-ghost btn-sm opacity-0 group-hover:opacity-100 text-error"
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

    {:ok,
     socket
     |> assign(:page_title, "List")
     |> assign(:list, list)
     |> assign(:current_user, nil)
     |> assign(:presence_count, 0)
     |> assign(:item_creators, %{})
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

  @impl true
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

    if connected?(socket) do
      ColistWeb.Presence.track_user(slug, name, %{id: name})
      ColistWeb.Presence.subscribe(slug)
    end

    presences = ColistWeb.Presence.list_online_users(slug)

    {:noreply,
     socket
     |> assign(:current_user, name)
     |> assign(:presence_count, length(presences))
     |> stream(:presences, presences, reset: true)
     |> push_event("store", %{key: "username", data: name})}
  end

  defp save_item(socket, :show, item_params) do
    item_params = Map.put(item_params, "list_id", socket.assigns.list.id)
    creator = socket.assigns.current_user

    case Lists.create_item(item_params) do
      {:ok, item} ->
        broadcast(socket.assigns.list.slug, "item_created", %{item: item, created_by: creator})

        {:noreply,
         socket
         |> update(:total_items, &(&1 + 1))
         |> update(:item_creators, &Map.put(&1, item.id, creator))
         |> stream_insert(:items, item)
         |> assign(:form, to_form(Lists.change_item(%Lists.Item{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp broadcast(slug, event, %{} = payload) do
    ColistWeb.Endpoint.broadcast_from!(self(), @topic <> ":#{slug}", event, payload)
  end

  @impl true
  def handle_info(%{event: "item_created", payload: %{item: item, created_by: creator}}, socket) do
    {:noreply,
     socket
     |> update(:total_items, &(&1 + 1))
     |> update(:item_creators, &Map.put(&1, item.id, creator))
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
      socket =
        if presence.id != socket.assigns.current_user do
          update(socket, :presence_count, &max(&1 - 1, 0))
        else
          socket
        end

      {:noreply, stream_delete(socket, :presences, presence)}
    else
      {:noreply, stream_insert(socket, :presences, presence)}
    end
  end
end
