defmodule ColistWeb.Plugs.Locale do
  @moduledoc """
  Plug to set the locale based on the URL path prefix.

  - `/pt_BR/*` routes will use Portuguese (Brazil)
  - All other routes default to English
  """
  import Plug.Conn

  @default_locale "en"

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = locale_from_path(conn.request_path)

    Gettext.put_locale(ColistWeb.Gettext, locale)

    conn
    |> assign(:locale, locale)
    |> put_session(:locale, locale)
  end

  defp locale_from_path("/pt_BR" <> _rest), do: "pt_BR"
  defp locale_from_path(_path), do: @default_locale
end
