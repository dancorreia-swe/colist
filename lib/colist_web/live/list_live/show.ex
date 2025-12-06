defmodule ColistWeb.ListLive.Show do
  use ColistWeb, :live_view

  alias Colist.Lists

  @topic "todo"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@list.title}
        <:subtitle>This is a list record from your database.</:subtitle>
      </.header>

      <.form for={@form} id="item-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:text]} type="text" label="Title" placeholder="Make eggs..." />
      </.form>

      <ul class="list bg-base-100 rounded-box shadow-md" id="items" phx-update="stream">
        <li :for={{item_id, item} <- @streams.items} class="list-row" id={item_id}>
          <.input
            id={"complete-item-#{item.id}"}
            type="checkbox"
            name="completed"
            label=""
            checked={item.completed}
            phx-click={JS.push("toggle_completion", value: %{id: item.id})}
          />
          <span>{item.text}</span>
          <button
            class="btn btn-square btn-ghost btn-error"
            phx-click={
              JS.push("delete", value: %{id: item.id})
              |> hide("##{item_id}")
            }
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="lucide lucide-trash2-icon lucide-trash-2"
            >
              <path d="M10 11v6" /><path d="M14 11v6" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" /><path d="M3 6h18" /><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
            </svg>
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

    broadcast(socket.assigns.list.slug, "item_deleted", item)
    {:noreply, stream_delete(socket, :items, item)}
  end

  def handle_event("toggle_completion", %{"id" => id}, socket) do
    item = Lists.get_item!(id)

    case Lists.update_item(item, %{completed: !item.completed}) do
      {:ok, updated_item} ->
        broadcast(socket.assigns.list.slug, "item_updated", updated_item)
        {:noreply, stream_insert(socket, :items, updated_item)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update item")}
    end
  end

  defp save_item(socket, :show, item_params) do
    item_params = Map.put(item_params, "list_id", socket.assigns.list.id)

    case Lists.create_item(item_params) do
      {:ok, item} ->
        broadcast(socket.assigns.list.slug, "item_created", item)

        {:noreply,
         socket
         |> put_flash(:info, "Item created successfully")
         |> stream_insert(:items, item)
         |> assign(:form, to_form(Lists.change_item(%Lists.Item{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp broadcast(slug, event, item) do
    ColistWeb.Endpoint.broadcast_from!(self(), @topic <> ":#{slug}", event, %{item: item})
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
end
