defmodule ColistWeb.ListLive.Form do
  use ColistWeb, :live_view

  alias Colist.Lists
  alias Colist.Lists.List

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage list records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="list-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:slug]} type="text" label="Slug" />
        <.input field={@form[:title]} type="text" label="Title" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save List</.button>
          <.button navigate={return_path(@return_to, @list)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    list = Lists.get_list!(id)

    socket
    |> assign(:page_title, "Edit List")
    |> assign(:list, list)
    |> assign(:form, to_form(Lists.change_list(list)))
  end

  defp apply_action(socket, :new, _params) do
    list = %List{}

    socket
    |> assign(:page_title, "New List")
    |> assign(:list, list)
    |> assign(:form, to_form(Lists.change_list(list)))
  end

  @impl true
  def handle_event("validate", %{"list" => list_params}, socket) do
    changeset = Lists.change_list(socket.assigns.list, list_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"list" => list_params}, socket) do
    save_list(socket, socket.assigns.live_action, list_params)
  end

  defp save_list(socket, :edit, list_params) do
    case Lists.update_list(socket.assigns.list, list_params) do
      {:ok, list} ->
        {:noreply,
         socket
         |> put_flash(:info, "List updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, list))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_list(socket, :new, list_params) do
    case Lists.create_list(list_params) do
      {:ok, list} ->
        {:noreply,
         socket
         |> put_flash(:info, "List created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, list))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _list), do: ~p"/lists"
  defp return_path("show", list), do: ~p"/lists/#{list}"
end
