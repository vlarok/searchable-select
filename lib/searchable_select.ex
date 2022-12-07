defmodule SearchableSelect do
  @moduledoc """
  Select component with nicer styling than HTML5 select

  Your view will need to implement a callback like this:
  `handle_info({:select, parent_key, selected}, socket)`

  Alternatively you can use it as part of a normal Phoenix HTML form by setting form and field
  assigns, and an optional callback for getting the value of each struct.

  For multiple selects, selected will be a list of selected structs/maps
  For single selects, selected will be a struct/map
  """
  use Phoenix.LiveComponent
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @doc """
  class - Classes to apply to outermost div, defaults to ""
  disabled - True=component is disabled - optional, defaults to `false`
  dropdown - True=selection doesn't persist after click, so behaves like a dropdown instead of a select - optional, defaults to `false`
  field - Field name to use as part of form, required if form is set
  form - Phoenix.HTML.Form, optional, if set will make searchable select return values via a hidden input instead of handle_info
  id - Component id - required
  id_key - Map/struct key to use when generating DOM IDs for options - optional, defaults to `:id`.
    If your maps/structs don't have this field then no DOM IDs will be set. Not needed for the select to function, just included
    as a testing convenience.
  label_callback - Function used to populate label when displaying items. Defaults to `fn item -> item.name end`
  multiple - True=multiple options may be selected, False=only one option may be select - optional, defaults to `false`
  options - List of maps or structs to use as options - required
  parent_key - Key to send to parent view when options are selected/unselected - required unless form is set
  placeholder - Placeholder for the search input, defaults to "Search"
  value_callback - Function used to populate the hidden input when form is set. Defaults to `fn item -> item.id end`
  """
  @impl true
  # this is when assigns change after the component is mounted
  def update(assigns, %{assigns: %{id: _id}} = socket) do
    socket =
      socket
      |> assign(:search, "")
      |> assign(:callback, "Nupp lisa")
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
      |> assign(:field, assigns[:field])
      |> assign(:form, assigns[:form])
      |> assign(:id, assigns.id)
      |> assign(:id_key, assigns[:id_key] || :id)
      |> assign(:label_callback, assigns[:label_callback] || fn item -> item.name end)
      |> assign(:multiple, assigns[:multiple] || false)
      |> prep_options(assigns)
      |> assign(:placeholder, assigns[:placeholder] || "Search")
      |> assign(:add_new, assigns[:add_new] || false)
      |> assign(:search, "")
      |> assign(:parent_key, assigns[:parent_key])
      |> assign(:selected, assigns[:selected] || [])
      |> assign(:value_callback, assigns[:value_callback] || fn item -> item.id end)

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

   if key != "" do
    options = :gb_trees.insert(key, val, options)
   end



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
    |> assign(:search, "")
    |> assign(:visible_options, filter(options, ""))
    |> update_parent_view()
    |> then(&{:noreply, &1})
  end

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  def pop_cross(assigns) do
    ~H"""
    <span class="inline-flex items-center px-3 rounded-none text-gray-500 text-sm">
      <svg
      xmlns="http://www.w3.org/2000/svg"
      class="inline-flex text-gray-400 group-hover:text-gray-500 mr-0 flex-shrink-0 h-5 w-5"
      viewBox="0 0 20 20"
        fill="currentColor"
        id={get_pop_cross_id(@component_id, elem(@selected, 1), @id_key)}
        role="button"
        phx-click="pop"
        phx-value-key={elem(@selected, 0)}
        phx-target={@target}
        >
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
      </svg>
    </span>
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

  def prep_options(%{assigns: assigns} = socket, %{options: options}) do
    selected = Map.get(assigns, :selected, [])

    gb_options =
      Enum.reduce(options, :gb_trees.empty(), fn option, acc ->
        normalised_label = assigns.label_callback.(option) |> normalise_string()
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

  def update_parent_view(%{assigns: %{form: form, id: id}} = socket) when form != nil do
    push_event(socket, "searchable_select", %{id: get_hook_id(id)})
  end

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

  def hidden_form_input(%{selected_val: selected_val, value_callback: value_callback} = assigns) do
    assigns = assign(assigns, :value, value_callback.(selected_val))

    ~H"""
    <input
      id={if @multiple, do: Form.input_id(@form, @field, @value), else: Form.input_id(@form, @field)}
      name={Form.input_name(@form, @field) <> if @multiple, do: "[]", else: ""}
      type="hidden"
      value={@value}
    />
    """
  end

  defp get_hook_id(id), do: id <> "-form-hook"

  defp normalise_string(string) do
    string
    |> String.replace(" ", "")
    |> String.downcase()
  end
end
