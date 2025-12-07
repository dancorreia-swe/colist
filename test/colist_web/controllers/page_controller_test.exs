defmodule ColistWeb.PageControllerTest do
  use ColistWeb.ConnCase

  test "GET /rate-limited", %{conn: conn} do
    conn = get(conn, ~p"/rate-limited")
    assert html_response(conn, 200) =~ "Rate Limit Exceeded"
  end
end
