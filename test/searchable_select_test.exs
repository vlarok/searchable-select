defmodule SearchableSelect.SearchableSelectTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Phoenix.LiveViewTest
  @endpoint SearchableSelect.Endpoint

  setup :load_test_view

  test "renders all options on load", %{live: live} do
    Enum.each(1..4, fn i -> assert has_element?(live, "#multi-option-#{i}") end)
    Enum.each(1..4, fn i -> assert has_element?(live, "#single-option-#{i}") end)
    Enum.each(1..4, fn i -> assert has_element?(live, "#dropdown-option-#{i}") end)
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

  test "no change to options or selection if dropdown=true", %{live: live} do
    live |> element("#dropdown-option-1") |> render_click()
    live |> element("#dropdown-option-2") |> render_click()

    refute has_element?(live, "#dropdown-pop-cross-1")
    refute has_element?(live, "#dropdown-pop-cross-2")
    assert has_element?(live, "#dropdown-option-1")
    assert has_element?(live, "#dropdown-option-2")

    assert live |> element("#selected-options") |> render() ==
             "<span id=\"selected-options\">2</span>"
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
    live |> element("#single-option-1") |> render_click()
    live |> element("#single-pop-cross-1") |> render_click()

    refute has_element?(live, "#single-pop-cross-1")
    assert has_element?(live, "#single-option-1")

    assert live |> element("#selected-options") |> render() ==
             "<span id=\"selected-options\">nil</span>"
  end

  test "view can change available options dynamically without messing up selection", %{live: live} do
    live |> element("#single-option-2") |> render_click()

    new_options = [
      %{id: 1, name: "Ayy"},
      %{id: 2, name: "Bar"},
      %{id: 3, name: "Foo"}
    ]

    send(live.pid, {:change_options, new_options})

    assert has_element?(live, "#single-option-1")
    refute has_element?(live, "#single-option-2")
    assert has_element?(live, "#single-option-3")
    refute has_element?(live, "#single-option-4")

    live |> element("#single-pop-cross-2") |> render_click()
    assert has_element?(live, "#single-option-2")
  end

  test "form mode pushes event and creates hidden inputs when changing single select", %{
    live: live
  } do
    hook_id = "single_form-form-hook"
    assert has_element?(live, "##{hook_id}")

    live |> element("#single_form-option-1") |> render_click()

    assert has_element?(live, "#test_single_select[value=1]")
    assert_push_event(live, "searchable_select", %{id: ^hook_id})

    live |> element("#single_form-option-2") |> render_click()

    refute has_element?(live, "#test_single_select[value=1]")
    assert has_element?(live, "#test_single_select[value=2]")
    assert_push_event(live, "searchable_select", %{id: ^hook_id})

    live |> element("#single_form-pop-cross-2") |> render_click()

    refute has_element?(live, "#test_single_select[value=2]")
    assert_push_event(live, "searchable_select", %{id: ^hook_id})
  end

  test "form mode pushes event and creates hidden inputs when changing multi select", %{
    live: live
  } do
    hook_id = "multi_form-form-hook"
    assert has_element?(live, "##{hook_id}")

    live |> element("#multi_form-option-1") |> render_click()

    assert has_element?(live, "#test_multi_select_1[name=\"test[multi_select][]\"]")
    assert_push_event(live, "searchable_select", %{id: ^hook_id})

    live |> element("#multi_form-option-2") |> render_click()

    assert has_element?(live, "#test_multi_select_1[name=\"test[multi_select][]\"]")
    assert has_element?(live, "#test_multi_select_2[name=\"test[multi_select][]\"]")
    assert_push_event(live, "searchable_select", %{id: ^hook_id})

    live |> element("#multi_form-pop-cross-2") |> render_click()

    refute has_element?(live, "#test_multi_select_2[name=\"test[multi_select][]\"]")
    assert_push_event(live, "searchable_select", %{id: ^hook_id})
  end

  defp load_test_view(_) do
    {:ok, live, _html} = live_isolated(conn(:get, "/"), SearchableSelect.TestView)
    %{live: live}
  end
end
