defmodule ColistWeb.ListLiveTest do
  use ColistWeb.ConnCase

  import Phoenix.LiveViewTest
  import Colist.ListsFixtures

  @create_attrs %{id: "some id", title: "some title", slug: "some slug"}
  @update_attrs %{id: "some updated id", title: "some updated title", slug: "some updated slug"}
  @invalid_attrs %{id: nil, title: nil, slug: nil}
  defp create_list(_) do
    list = list_fixture()

    %{list: list}
  end

  describe "Index" do
    setup [:create_list]

    test "lists all lists", %{conn: conn, list: list} do
      {:ok, _index_live, html} = live(conn, ~p"/lists")

      assert html =~ "Listing Lists"
      assert html =~ list.id
    end

    test "saves new list", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/lists")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New List")
               |> render_click()
               |> follow_redirect(conn, ~p"/lists/new")

      assert render(form_live) =~ "New List"

      assert form_live
             |> form("#list-form", list: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#list-form", list: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/lists")

      html = render(index_live)
      assert html =~ "List created successfully"
      assert html =~ "some id"
    end

    test "updates list in listing", %{conn: conn, list: list} do
      {:ok, index_live, _html} = live(conn, ~p"/lists")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#lists-#{list.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/lists/#{list}/edit")

      assert render(form_live) =~ "Edit List"

      assert form_live
             |> form("#list-form", list: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#list-form", list: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/lists")

      html = render(index_live)
      assert html =~ "List updated successfully"
      assert html =~ "some updated id"
    end

    test "deletes list in listing", %{conn: conn, list: list} do
      {:ok, index_live, _html} = live(conn, ~p"/lists")

      assert index_live |> element("#lists-#{list.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#lists-#{list.id}")
    end
  end

  describe "Show" do
    setup [:create_list]

    test "displays list", %{conn: conn, list: list} do
      {:ok, _show_live, html} = live(conn, ~p"/lists/#{list}")

      assert html =~ "Show List"
      assert html =~ list.id
    end

    test "updates list and returns to show", %{conn: conn, list: list} do
      {:ok, show_live, _html} = live(conn, ~p"/lists/#{list}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/lists/#{list}/edit?return_to=show")

      assert render(form_live) =~ "Edit List"

      assert form_live
             |> form("#list-form", list: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#list-form", list: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/lists/#{list}")

      html = render(show_live)
      assert html =~ "List updated successfully"
      assert html =~ "some updated id"
    end
  end
end
