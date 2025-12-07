defmodule ColistWeb.PageController do
  use ColistWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def rate_limited(conn, _params) do
    conn
    |> assign(:page_title, "Rate Limit Exceeded")
    |> render(:rate_limited)
  end
end
