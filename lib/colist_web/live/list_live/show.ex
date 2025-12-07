defmodule ColistWeb.ListLive.Show do
  use ColistWeb, :live_view

  alias Colist.Lists

  @topic "todo"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <header class="flex items-center justify-between gap-6 pb-4">
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
        <div class="flex-none">
          <.button phx-hook="CopyUrl" id="copy-url-btn">
            <.icon name="hero-link" />
          </.button>
        </div>
      </header>

      <.form for={@form} id="item-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:text]}
          type="text"
          placeholder="Add a task..."
          class="input input-ghost w-full text-base focus:input-bordered focus:bg-base-100"
        />
      </.form>

      <ul
        class="bg-base-100 rounded-box shadow-md"
        id="items"
        phx-update="stream"
        phx-hook="DragNDrop"
      >
        <li
          :for={{item_id, item} <- @streams.items}
          class={["flex items-center gap-3 py-2 px-3 group cursor-grab active:cursor-grabbing", item.completed && "opacity-50"]}
          id={item_id}
        >
          <input
            id={"complete-item-#{item.id}"}
            type="checkbox"
            checked={item.completed}
            phx-click={JS.push("toggle_completion", value: %{id: item.id})}
            class="checkbox checkbox-sm"
          />
          <span class={["flex-1", item.completed && "line-through"]}>
            {item.text}
          </span>
          <button
            class="btn btn-square btn-ghost btn-sm opacity-0 group-hover:opacity-100 transition-opacity text-error"
            phx-click={
              JS.push("delete", value: %{id: item.id})
              |> hide("##{item_id}")
            }
          >
            <.icon name="hero-trash" class="size-4" />
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

    {:ok,
     socket
     |> assign(:page_title, "Show List")
     |> assign(:list, list)
     |> stream(:items, list_items(list.id))
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
    {:noreply, stream_delete(socket, :items, item)}
  end

  def handle_event("toggle_completion", %{"id" => id}, socket) do
    item = Lists.get_item!(id)

    case Lists.update_item(item, %{completed: !item.completed}) do
      {:ok, updated_item} ->
        broadcast(socket.assigns.list.slug, "item_updated", %{item: updated_item})
        {:noreply, stream_insert(socket, :items, updated_item)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update item")}
    end
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

  defp save_item(socket, :show, item_params) do
    item_params = Map.put(item_params, "list_id", socket.assigns.list.id)

    case Lists.create_item(item_params) do
      {:ok, item} ->
        broadcast(socket.assigns.list.slug, "item_created", %{item: item})

        {:noreply,
         socket
         |> put_flash(:info, "Item created successfully")
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
  def handle_info(%{event: "item_created", payload: %{item: item}}, socket) do
    {:noreply, stream_insert(socket, :items, item, at: -1)}
  end

  def handle_info(%{event: "item_updated", payload: %{item: item}}, socket) do
    {:noreply, stream_insert(socket, :items, item)}
  end

  def handle_info(%{event: "item_deleted", payload: %{item: item}}, socket) do
    {:noreply, stream_delete(socket, :items, item)}
  end

  def handle_info(%{event: "list_updated", payload: %{list: list}}, socket) do
    {:noreply, assign(socket, :list, list)}
  end

  def handle_info(%{event: "items_reordered", payload: %{ids: _ids}}, socket) do
    # Reset stream with fresh order from database
    {:noreply, stream(socket, :items, list_items(socket.assigns.list.id), reset: true)}
  end
end
