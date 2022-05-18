defmodule SearchableSelect.SearchableSelectTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Phoenix.LiveViewTest
  @endpoint SearchableSelect.Endpoint

  setup :load_test_view

  test "renders all options on load", %{live: live} do
    Enum.each(1..4, fn i -> assert has_element?(live, "#multi-option-#{i}") end)
    Enum.each(1..4, fn i -> assert has_element?(live, "#single-option-#{i}") end)
  end

  test "search filters items in dropdown", %{live: live} do
    live |> element("#multi-search") |> render_keyup(%{"value" => " ayy  "})
    assert has_element?(live, "#multi-option-1")
    Enum.each(2..4, fn i -> refute has_element?(live, "#multi-option-#{i}") end)

    live |> element("#single-search") |> render_keyup(%{"value" => "LmAO  "})
    assert has_element?(live, "#single-option-4")
    Enum.each(1..3, fn i -> refute has_element?(live, "#single-option-#{i}") end)

    live |> element("#multi-search") |> render_keyup(%{"value" => ""})
    Enum.each(1..4, fn i -> assert has_element?(live, "#multi-option-#{i}") end)
  end

  test "no results message shows if no items available", %{live: live} do
    assert live
           |> element("#multi-search")
           |> render_keyup(%{"value" => "asdf"}) =~ "Sorry, no matching options."

    Enum.each(1..4, fn i -> refute has_element?(live, "#multi-option-#{i}") end)
  end

  test "can select multiple items if multiple=true", %{live: live} do
    live |> element("#multi-option-1") |> render_click()
    live |> element("#multi-option-2") |> render_click()

    assert has_element?(live, "#multi-pop-cross-1")
    assert has_element?(live, "#multi-pop-cross-2")
    refute has_element?(live, "#multi-option-1")
    refute has_element?(live, "#multi-option-2")

    assert live |> element("#selected-options") |> render() ==
             "<span id=\"selected-options\">[1, 2]</span>"
  end

  test "selection is replaced instead of appended if multiple=false", %{live: live} do
    live |> element("#single-option-1") |> render_click()
    live |> element("#single-option-2") |> render_click()

    refute has_element?(live, "#single-pop-cross-1")
    assert has_element?(live, "#single-pop-cross-2")
    assert has_element?(live, "#single-option-1")
    refute has_element?(live, "#single-option-2")

    assert live |> element("#selected-options") |> render() ==
             "<span id=\"selected-options\">2</span>"
  end

  test "pop cross removes correct item from selected if multiple=true", %{live: live} do
    live |> element("#multi-option-1") |> render_click()
    live |> element("#multi-option-2") |> render_click()
    live |> element("#multi-pop-cross-1") |> render_click()

    refute has_element?(live, "#multi-pop-cross-1")
    assert has_element?(live, "#multi-pop-cross-2")
    assert has_element?(live, "#multi-option-1")
    refute has_element?(live, "#multi-option-2")

    assert live |> element("#selected-options") |> render() ==
             "<span id=\"selected-options\">[2]</span>"
  end

  test "pop cross clears selection if multiple=false", %{live: live} do
    live |> element("#multi-option-1") |> render_click()
    live |> element("#multi-pop-cross-1") |> render_click()

    refute has_element?(live, "#multi-pop-cross-1")
    assert has_element?(live, "#multi-option-1")

    assert live |> element("#selected-options") |> render() ==
             "<span id=\"selected-options\">[]</span>"
  end

  defp load_test_view(_) do
    {:ok, live, _html} = live_isolated(conn(:get, "/"), SearchableSelect.TestView)
    %{live: live}
  end
end
