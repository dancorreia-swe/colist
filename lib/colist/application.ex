defmodule Colist.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        ColistWeb.Telemetry,
        Colist.Repo,
        {DNSCluster, query: Application.get_env(:colist, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Colist.PubSub},
        ColistWeb.Presence,
        # Start to serve requests, typically the last entry
        ColistWeb.Endpoint
      ] ++ workers()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Colist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Only start workers when running the server (not during asset compilation)
  defp workers do
    if Application.get_env(:colist, :start_workers, true) do
      [Colist.Workers.ListCleaner]
    else
      []
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ColistWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
