defmodule ColistWeb.ListController do
  use ColistWeb, :controller

  alias Colist.Lists
  alias Colist.RateLimit

  def create(conn, _params) do
    client_ip = conn.remote_ip |> :inet.ntoa() |> to_string()

    case RateLimit.check_list_creation(client_ip) do
      :ok ->
        create_list(conn)

      {:error, :rate_limited, retry_after} ->
        conn
        |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
        |> put_flash(:error, "Too many lists created. Please try again later.")
        |> redirect(to: ~p"/")
    end
  end

  defp create_list(conn) do
    case Lists.create_list(%{slug: Lists.unique_slug(), title: "New List"}) do
      {:ok, list} ->
        redirect(conn, to: ~p"/#{list.slug}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create list")
        |> redirect(to: ~p"/")
    end
  end
end
