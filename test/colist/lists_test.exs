defmodule Colist.ListsTest do
  use Colist.DataCase

  alias Colist.Lists

  describe "lists" do
    alias Colist.Lists.List

    import Colist.ListsFixtures

    @invalid_attrs %{id: nil, title: nil, slug: nil}

    test "list_lists/0 returns all lists" do
      list = list_fixture()
      assert Lists.list_lists() == [list]
    end

    test "get_list!/1 returns the list with given id" do
      list = list_fixture()
      assert Lists.get_list!(list.id) == list
    end

    test "create_list/1 with valid data creates a list" do
      valid_attrs = %{id: "some id", title: "some title", slug: "some slug"}

      assert {:ok, %List{} = list} = Lists.create_list(valid_attrs)
      assert list.id == "some id"
      assert list.title == "some title"
      assert list.slug == "some slug"
    end

    test "create_list/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Lists.create_list(@invalid_attrs)
    end

    test "update_list/2 with valid data updates the list" do
      list = list_fixture()
      update_attrs = %{id: "some updated id", title: "some updated title", slug: "some updated slug"}

      assert {:ok, %List{} = list} = Lists.update_list(list, update_attrs)
      assert list.id == "some updated id"
      assert list.title == "some updated title"
      assert list.slug == "some updated slug"
    end

    test "update_list/2 with invalid data returns error changeset" do
      list = list_fixture()
      assert {:error, %Ecto.Changeset{}} = Lists.update_list(list, @invalid_attrs)
      assert list == Lists.get_list!(list.id)
    end

    test "delete_list/1 deletes the list" do
      list = list_fixture()
      assert {:ok, %List{}} = Lists.delete_list(list)
      assert_raise Ecto.NoResultsError, fn -> Lists.get_list!(list.id) end
    end

    test "change_list/1 returns a list changeset" do
      list = list_fixture()
      assert %Ecto.Changeset{} = Lists.change_list(list)
    end
  end

  describe "items" do
    alias Colist.Lists.Item

    import Colist.ListsFixtures

    @invalid_attrs %{position: nil, text: nil, completed: nil, list_id: nil}

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Lists.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Lists.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      valid_attrs = %{position: 42, text: "some text", completed: true, list_id: "some list_id"}

      assert {:ok, %Item{} = item} = Lists.create_item(valid_attrs)
      assert item.position == 42
      assert item.text == "some text"
      assert item.completed == true
      assert item.list_id == "some list_id"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Lists.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      update_attrs = %{position: 43, text: "some updated text", completed: false, list_id: "some updated list_id"}

      assert {:ok, %Item{} = item} = Lists.update_item(item, update_attrs)
      assert item.position == 43
      assert item.text == "some updated text"
      assert item.completed == false
      assert item.list_id == "some updated list_id"
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Lists.update_item(item, @invalid_attrs)
      assert item == Lists.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Lists.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Lists.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Lists.change_item(item)
    end
  end
end
