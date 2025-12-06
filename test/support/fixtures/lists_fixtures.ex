defmodule Colist.ListsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Colist.Lists` context.
  """

  @doc """
  Generate a list.
  """
  def list_fixture(attrs \\ %{}) do
    {:ok, list} =
      attrs
      |> Enum.into(%{
        id: "some id",
        slug: "some slug",
        title: "some title"
      })
      |> Colist.Lists.create_list()

    list
  end

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        completed: true,
        list_id: "some list_id",
        position: 42,
        text: "some text"
      })
      |> Colist.Lists.create_item()

    item
  end
end
