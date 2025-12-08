defmodule ColistWeb.Router do
  use ColistWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ColistWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ColistWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :dashboard do
    plug :dashboard_basic_auth
  end

  defp dashboard_basic_auth(conn, _opts) do
    username = Application.get_env(:colist, :dashboard_user)
    password = Application.get_env(:colist, :dashboard_password)
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

  scope "/", ColistWeb do
    pipe_through :browser

    get "/", ListController, :create
    get "/rate-limited", PageController, :rate_limited

    live "/:slug", ListLive.Show, :show
  end

  scope "/pt_BR", ColistWeb, as: :pt_br do
    pipe_through :browser

    get "/", ListController, :create
    get "/rate-limited", PageController, :rate_limited

    live "/:slug", ListLive.Show, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", ColistWeb do
  #   pipe_through :api
  # end

  # Live Dashboard with basic auth protection
  scope "/admin" do
    pipe_through [:browser, :dashboard]
    live_dashboard "/dashboard", metrics: ColistWeb.Telemetry
  end

  # Swoosh mailbox preview in development only
  if Application.compile_env(:colist, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
