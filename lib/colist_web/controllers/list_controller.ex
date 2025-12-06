defmodule ColistWeb.ListController do
  use ColistWeb, :controller

  alias Colist.Lists

  def create(conn, _params) do
    case Lists.create_list(%{slug: Lists.unique_slug(), title: "New List"}) do
      {:ok, list} ->
        redirect(conn, to: ~p"/#{list.slug}")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Failed to create list")
        |> render("home.html", changeset: changeset)
    end
  end
end
