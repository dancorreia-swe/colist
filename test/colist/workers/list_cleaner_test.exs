defmodule Colist.Workers.ListCleanerTest do
  use Colist.DataCase

  alias Colist.Lists

  describe "delete_expired_lists/0" do
    test "deletes lists that have expired" do
      # Create an expired list (expired 1 hour ago)
      expired_at = DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
      {:ok, expired_list} = Lists.create_list(%{slug: "expired", title: "Expired"})
      {:ok, expired_list} = Lists.update_list(expired_list, %{expires_at: expired_at})

      # Create a non-expired list (expires in 1 hour)
      future_at = DateTime.utc_now() |> DateTime.add(1, :hour) |> DateTime.truncate(:second)
      {:ok, active_list} = Lists.create_list(%{slug: "active", title: "Active"})
      {:ok, _active_list} = Lists.update_list(active_list, %{expires_at: future_at})

      # Run the cleanup
      {deleted_count, _} = Lists.delete_expired_lists()

      assert deleted_count == 1

      # Expired list should be gone
      assert_raise Ecto.NoResultsError, fn ->
        Lists.get_list!(expired_list.id)
      end

      # Active list should still exist
      assert Lists.get_list!(active_list.id)
    end

    test "does not delete lists without expires_at" do
      # Create a list and remove its expires_at
      {:ok, list} = Lists.create_list(%{slug: "no-expiry", title: "No Expiry"})
      {:ok, _list} = Lists.update_list(list, %{expires_at: nil})

      # Run the cleanup
      {deleted_count, _} = Lists.delete_expired_lists()

      assert deleted_count == 0

      # List should still exist
      assert Lists.get_list!(list.id)
    end
  end

  describe "create_list/1" do
    test "sets expires_at to 7 days from now" do
      {:ok, list} = Lists.create_list(%{slug: "new-list", title: "New List"})

      assert list.expires_at != nil

      # Should be roughly 7 days from now (within a few seconds)
      expected = DateTime.utc_now() |> DateTime.add(7, :day)
      diff = DateTime.diff(list.expires_at, expected, :second) |> abs()

      assert diff < 5, "expires_at should be ~7 days from now"
    end
  end
end
