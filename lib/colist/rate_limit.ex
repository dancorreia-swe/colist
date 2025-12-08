defmodule Colist.RateLimit do
  use Hammer, backend: :ets

  @list_limit 25
  @item_limit 100
  @one_hour :timer.hours(1)

  @doc """
  Check if a user can create a list. Limit: #{@list_limit} per hour.
  """
  def check_list_creation(user_id) do
    key = "list_creation:#{user_id}"

    case hit(key, @one_hour, @list_limit) do
      {:allow, _count} -> :ok
      {:deny, retry_after} -> {:error, :rate_limited, retry_after}
    end
  end

  @doc """
  Check if a user can create an item. Limit: #{@item_limit} per hour.
  """
  def check_item_creation(user_id) do
    key = "item_creation:#{user_id}"

    case hit(key, @one_hour, @item_limit) do
      {:allow, _count} -> :ok
      {:deny, retry_after} -> {:error, :rate_limited, retry_after}
    end
  end
end
