defmodule ColistWeb.ListControllerTest do
  use ColistWeb.ConnCase

  setup do
    # Clear rate limit for localhost IP
    # Assuming "127.0.0.1" is the IP in tests or whatever `conn.remote_ip` is.
    # But Hammer doesn't expose a clear function easily for a specific key without knowing the bucket.
    # However, we can just try.
    :ok
  end

  test "redirects to /rate-limited when limit exceeded", %{conn: conn} do
    # Consume the rate limit (10 requests)
    # We expect these to redirect to a new list (path like /:slug)
    for _ <- 1..10 do
      conn = get(conn, ~p"/")
      assert redirected_to(conn) =~ ~r{^/[a-zA-Z0-9_-]+$}
    end

    # The 11th request should be rate limited and redirect to /rate-limited
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/rate-limited"
  end
end
