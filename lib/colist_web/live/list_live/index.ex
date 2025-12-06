defmodule ColistWeb.ListLive.Index do
  use ColistWeb, :live_view

  alias Colist.Lists

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Lists
        <:actions>
          <.button variant="primary" navigate={~p"/lists/new"}>
            <.icon name="hero-plus" /> New List
          </.button>
        </:actions>
      </.header>

      <.table
        id="lists"
        rows={@streams.lists}
        row_click={fn {_id, list} -> JS.navigate(~p"/lists/#{list}") end}
      >
        <:col :let={{_id, list}} label="Id">{list.id}</:col>
        <:col :let={{_id, list}} label="Slug">{list.slug}</:col>
        <:col :let={{_id, list}} label="Title">{list.title}</:col>
        <:action :let={{_id, list}}>
          <div class="sr-only">
            <.link navigate={~p"/lists/#{list}"}>Show</.link>
          </div>
          <.link navigate={~p"/lists/#{list}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, list}}>
          <.link
            phx-click={JS.push("delete", value: %{id: list.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Lists")
     |> stream(:lists, list_lists())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    list = Lists.get_list!(id)
    {:ok, _} = Lists.delete_list(list)

    {:noreply, stream_delete(socket, :lists, list)}
  end

  defp list_lists() do
    Lists.list_lists()
  end
end
