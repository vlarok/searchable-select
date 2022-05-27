defmodule SearchableSelect.TestView do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    example_options = [
      %{id: 1, name: "Ayy"},
      %{id: 2, name: "Bar"},
      %{id: 3, name: "Foo"},
      %{id: 4, name: "Lmao"}
    ]

    socket =
      socket
      |> assign(:options, example_options)
      |> assign(:selected_options, [])

    {:ok, socket}
  end

  @impl true
  def handle_info({:change_options, options}, socket) do
    socket
    |> assign(:options, options)
    |> then(&{:noreply, &1})
  end

  def handle_info({:select, _items_key, items}, socket) do
    socket
    |> assign(:selected_options, items)
    |> then(&{:noreply, &1})
  end

  defp get_selected_id_list([]), do: "[]"
  defp get_selected_id_list([%{id: id}]), do: "[#{id}]"
  defp get_selected_id_list(nil), do: "nil"
  defp get_selected_id_list(%{id: id}), do: "#{id}"
  defp get_selected_id_list(selected), do: Enum.map(selected, & &1.id) |> inspect()

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      id="multi"
      module={SearchableSelect}
      multiple
      options={@options}
      parent_key="selected_options"
    />
    <.live_component
      id="single"
      module={SearchableSelect}
      options={@options}
      parent_key="selected_options"
    />
    <.live_component
      dropdown
      id="dropdown"
      module={SearchableSelect}
      options={@options}
      parent_key="selected_options"
    />
    <span id="selected-options"><%= get_selected_id_list(@selected_options) %></span>
    """
  end
end
