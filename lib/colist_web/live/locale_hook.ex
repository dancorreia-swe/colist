defmodule ColistWeb.LocaleHook do
  @moduledoc """
  LiveView hook to set the locale based on the session.
  """
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    locale = session["locale"] || "en"

    Gettext.put_locale(ColistWeb.Gettext, locale)

    {:cont, assign(socket, :locale, locale)}
  end
end
