defmodule ColistWeb.Plugs.Locale do
  @moduledoc """
  Plug to set the locale based on:

  1. URL path prefix (explicit choice: `/pt_BR/*`)
  2. Accept-Language header (browser preference)
  3. Default to English
  """
  import Plug.Conn

  @default_locale "en"
  @supported_locales ["en", "pt_BR"]

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      locale_from_path(conn.request_path) ||
        locale_from_accept_language(conn) ||
        @default_locale

    Gettext.put_locale(ColistWeb.Gettext, locale)

    conn
    |> assign(:locale, locale)
    |> put_session(:locale, locale)
  end

  defp locale_from_path("/pt_BR" <> _rest), do: "pt_BR"
  defp locale_from_path(_path), do: nil

  defp locale_from_accept_language(conn) do
    conn
    |> get_req_header("accept-language")
    |> parse_accept_language()
    |> find_supported_locale()
  end

  defp parse_accept_language([header | _]) do
    header
    |> String.split(",")
    |> Enum.map(&parse_language_tag/1)
    |> Enum.sort_by(fn {_lang, q} -> q end, :desc)
    |> Enum.map(fn {lang, _q} -> lang end)
  end

  defp parse_accept_language([]), do: []

  defp parse_language_tag(tag) do
    tag = String.trim(tag)

    case String.split(tag, ";") do
      [lang, "q=" <> q] ->
        {normalize_locale(lang), parse_quality(q)}

      [lang] ->
        {normalize_locale(lang), 1.0}
    end
  end

  defp parse_quality(q) do
    case Float.parse(q) do
      {val, _} -> val
      :error -> 0.0
    end
  end

  defp normalize_locale(lang) do
    lang
    |> String.trim()
    |> String.replace("-", "_")
  end

  defp find_supported_locale(preferred_locales) do
    Enum.find_value(preferred_locales, fn preferred ->
      cond do
        preferred in @supported_locales ->
          preferred

        String.starts_with?(preferred, "pt") ->
          "pt_BR"

        String.starts_with?(preferred, "en") ->
          "en"

        true ->
          nil
      end
    end)
  end
end
