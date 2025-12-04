defmodule ColistWeb.PageController do
  use ColistWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
