defmodule SearchableSelect do
  @moduledoc """
  Select component with nicer styling than HTML5 select

  Your view will need to implement a callback like this:
  `handle_info({:select, parent_key, selected}, socket)`

  For multiple selects, selected will be a list of selected structs/maps
  For single selects, selected will be a struct/map
  """
  use Phoenix.LiveComponent
  alias Phoenix.LiveView.JS

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @doc """
  class - Classes to apply to outermost div, defaults to ""
  disabled - True=component is disabled - optional, defaults to `false`
  dropdown - True=selection doesn't persist after click, so behaves like a dropdown instead of a select - optional, defaults to `false`
  id - Component id - required
  id_key - Map/struct key to use when generating DOM IDs for options - optional, defaults to `:id`.
    If your maps/structs don't have this field then no DOM IDs will be set. Not needed for the select to function, just included
    as a testing convenience.
  label_key - Map/struct key to use as label when displaying items - optional, defaults to `:name`
  multiple - True=multiple options may be selected, False=only one option may be select - optional, defaults to `false`
  options - List of maps or structs to use as options - required
  parent_key - Key to send to parent view when options are selected/unselected - required
  placeholder - Placeholder for the search input, defaults to "Search"
  """
  @impl true
  # this is when assigns change after the component is mounted
  def update(assigns, %{assigns: %{id: _id}} = socket) do
    socket =
      socket
      |> assign(:search, "")
      |> prep_options(assigns)

    socket
    |> assign(:visible_options, filter(socket.assigns.options, ""))
    |> then(&{:ok, &1})
  end

  # this is when the component is mounted
  def update(assigns, socket) do
    socket =
      socket
      |> assign(:class, assigns[:class] || "")
      |> assign(:disabled, assigns[:disabled] || false)
      |> assign(:dropdown, assigns[:dropdown] || false)
      |> assign(:id, assigns.id)
      |> assign(:id_key, assigns[:id_key] || :id)
      |> assign(:label_key, assigns[:label_key] || :name)
      |> assign(:multiple, assigns[:multiple] || false)
      |> prep_options(assigns)
      |> assign(:placeholder, assigns[:placeholder] || "Search")
      |> assign(:search, "")
      |> assign(:parent_key, assigns.parent_key)
      |> assign(:selected, [])

    socket
    |> assign(:visible_options, filter(socket.assigns.options, ""))
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("pop", %{"key" => key}, %{assigns: assigns} = socket) do
    %{options: options, selected: selected, search: search} = assigns

    {selected, val} =
      Enum.reduce(selected, {[], nil}, fn
        {^key, val}, {acc, nil} -> {acc, val}
        other_selection, {acc, acc_val} -> {[other_selection | acc], acc_val}
      end)

    options = :gb_trees.insert(key, val, options)

    socket
    |> assign(:options, options)
    |> assign(:selected, Enum.reverse(selected))
    |> update_parent_view()
    |> assign(:visible_options, filter(options, search))
    |> then(&{:noreply, &1})
  end

  def handle_event("search", %{"value" => search}, socket) do
    %{assigns: %{options: options}} = socket

    socket
    |> assign(:search, search)
    |> assign(:visible_options, filter(options, search))
    |> then(&{:noreply, &1})
  end

  def handle_event("select", %{"key" => key}, %{assigns: %{dropdown: true} = assigns} = socket) do
    %{options: options, parent_key: parent_key} = assigns
    val = :gb_trees.get(key, options)
    send(self(), {:select, parent_key, val})

    socket
    |> assign(:search, "")
    |> then(&{:noreply, &1})
  end

  def handle_event("select", %{"key" => key}, %{assigns: assigns} = socket) do
    %{options: options, selected: selected} = assigns
    {val, options} = :gb_trees.take(key, options)

    {options, selected} =
      if !assigns.multiple and length(selected) == 1 do
        [{old_key, old_val}] = selected
        {:gb_trees.insert(old_key, old_val, options), []}
      else
        {options, selected}
      end

    selected = selected ++ [{key, val}]

    socket
    |> assign(:options, options)
    |> assign(:selected, selected)
    |> update_parent_view()
    |> assign(:search, "")
    |> assign(:visible_options, filter(options, ""))
    |> then(&{:noreply, &1})
  end

  def pop_cross(assigns) do
    ~H"""
    <svg
      class="fill-current h-4 w-4 my-auto"
      id={get_pop_cross_id(@component_id, elem(@selected, 1), @id_key)}
      role="button"
      viewBox="0 0 20 20"
      phx-click="pop"
      phx-value-key={elem(@selected, 0)}
      phx-target={@target}
    >
      <path d="M14.348,14.849c-0.469,0.469-1.229,0.469-1.697,0L10,11.819l-2.651,3.029c-0.469,0.469-1.229,0.469-1.697,0 c-0.469-0.469-0.469-1.229,0-1.697l2.758-3.15L5.651,6.849c-0.469-0.469-0.469-1.228,0-1.697s1.228-0.469,1.697,0L10,8.183 l2.651-3.031c0.469-0.469,1.228-0.469,1.697,0s0.469,1.229,0,1.697l-2.758,3.152l2.758,3.15 C14.817,13.62,14.817,14.38,14.348,14.849z" />
    </svg>
    """
  end

  # get id_key, component id, selected
  def get_option_id(component_id, selected, id_key) do
    case Map.get(selected, id_key) do
      nil -> nil
      id -> "#{component_id}-option-#{id}"
    end
  end

  def get_pop_cross_id(component_id, selected, id_key) do
    case Map.get(selected, id_key) do
      nil -> nil
      id -> "#{component_id}-pop-cross-#{id}"
    end
  end

  # TODO: transition animations
  def hide_dropdown(id, js \\ %JS{}) do
    JS.hide(js, to: "##{id}-dropdown")
  end

  def show_dropdown(js, id) do
    JS.show(js, to: "##{id}-dropdown")
  end

  def toggle_dropdown(id) do
    JS.toggle(%JS{}, to: "##{id}-dropdown")
  end

  def selection_action(key, target, id, multiple) do
    js = JS.push("select", target: target, value: %{"key" => key})

    if multiple do
      js
    else
      hide_dropdown(id, js)
    end
  end

  def prep_options(%{assigns: %{label_key: label_key} = assigns} = socket, %{options: options}) do
    selected = Map.get(assigns, :selected, [])

    gb_options =
      Enum.reduce(options, :gb_trees.empty(), fn option, acc ->
        normalised_label =
          option
          |> Map.get(label_key)
          |> normalise_string()

        :gb_trees.insert(normalised_label, option, acc)
      end)

    gb_options =
      Enum.reduce(selected, gb_options, fn {key, _}, acc ->
        :gb_trees.delete_any(key, acc)
      end)

    assign(socket, :options, gb_options)
  end

  def filter(options, search) do
    search = normalise_string(search)

    if search == "" do
      :gb_trees.to_list(options)
    else
      options
      |> :gb_trees.iterator()
      |> :gb_trees.next()
      |> filter([], search)
    end
  end

  def filter({key, val, next}, acc, search) do
    acc =
      if String.contains?(key, search) do
        [{key, val} | acc]
      else
        acc
      end

    filter(:gb_trees.next(next), acc, search)
  end

  def filter(:none, acc, _search), do: Enum.reverse(acc)

  def update_parent_view(%{assigns: %{multiple: true} = assigns} = socket) do
    %{parent_key: parent_key, selected: selected} = assigns
    send(self(), {:select, parent_key, Enum.map(selected, fn {_key, val} -> val end)})
    socket
  end

  def update_parent_view(%{assigns: %{parent_key: parent_key, selected: []}} = socket) do
    send(self(), {:select, parent_key, nil})
    socket
  end

  def update_parent_view(%{assigns: %{parent_key: parent_key, selected: [{_, val}]}} = socket) do
    send(self(), {:select, parent_key, val})
    socket
  end

  defp normalise_string(string) do
    string
    |> String.replace(" ", "")
    |> String.downcase()
  end
end
