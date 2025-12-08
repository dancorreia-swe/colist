defmodule ColistWeb.PresenceCounter do
  @moduledoc """
  Tracks the count of active users across all lists for telemetry.
  Updated by Presence on join/leave events.
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def increment do
    Agent.update(__MODULE__, &(&1 + 1))
  end

  def decrement do
    Agent.update(__MODULE__, &max(&1 - 1, 0))
  end

  def count do
    Agent.get(__MODULE__, & &1)
  end
end
