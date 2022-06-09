# SearchableSelect

Searchable multi/single select made for LiveView. Requires Tailwind to be set up in your project.

# Implementation

## Tailwind config
in tailwind.config.js add "../deps/searchable_select/lib/*.*ex", to the module.exports
```js
module.exports = {
    content: [
        "./js/**/*.js",
        "../lib/*_web.ex",
        "../lib/*_web/**/*.*ex",
        "../deps/searchable_select/lib/*.*ex",
    ],
```


## JS hooks
in app.js implement searchable select hooks

```js
import {SearchableSelect} from "../../deps/searchable_select/lib/hook.js"

Hooks.SearchableSelect = SearchableSelect
```

# Usage

If you want to make the searchable select more integrated with your form and don't care about getting the whole struct (e.g. you have options like `[%{id: 1, name: "ABC", value: 25}]` and only want `25`) you can use SearchableSelect like this:
```
    <.input_group
      form={f}
      label="Your label"
      field={:your_field}
      type={:searchable_select}
      options={@options}
    />
```
then whenever you select stuff it'll show up as part of params in your form's `handle_event` instead of a separate `handle_info`

If you want to change how the labels are generated, you can add a callback, for example if you had a list of options like this:`[%{id: 1, network_name: "ABC", billing_type: "Prepaid"}, %{id: 2, network_name: "ABC", billing_type: "Contract"}]` you could add a callback like this:
```
    label_callback={fn item -> "#{item.network_name} - #{item.billing_type}" end}
```

A similar callback is available for generating values if you opt to go the form route (instead of `handle_info`). You set it with `value_callback`:
```
    value_callback={fn item -> item.billing_type end}
```
