# Template Guide (essentials)

The compiled template is a widget-node tree. Reserved keys start with `_`;
compile-time build keys start with `.` (see `compiler/spec/SPEC.md`) and never
reach the client.

## Widget nodes

```yaml
_type: container          # widget type (Flutter primitive, snake_case)
padding: [16, 14]
decoration: { color: { .token: color.surface10 }, border_radius: 12 }
_child: { _type: text, value: hello }        # single child
# _children: [...]                           # multiple children
# _slots: { app_bar: ..., body: ... }        # named slots (scaffold, app_bar)
```

## Scope: state, actions, lifecycle

```yaml
_scope:
  _state: { items: null }        # reactive state owned by this scope
  _action:
    load_feed:
      _type: api                 # driver command
      query: HomeFeed            # transport-neutral operation name
      variables: { id: '${id}' }
      _when: '${items == null}'  # guard: falsy -> skip the command
      _then:                     # continuation with `data` in scope
        - { _type: set, items: '${data.items}' }
      # _error / _dismiss / _always continuations also exist
_scope:
  _lifecycle:
    - { on: mount, action: load_feed }
```

Bindings use `${expr}` — a lone `${x}` preserves the value's type, interpolation
inside a longer string stringifies. State writes go through the `set` command.

## Control flow

```yaml
# Conditional: list of branches; each needs exactly one of _if / _else.
_type: cond
_children:
  - _if: '${items == null}'
    _type: center
    _child: { _type: circular_progress_indicator }
  - _else: true
    _type: single_child_scroll_view
    ...

# Loop: lives on a widget node (never on a .ref) and renders it per item.
- _loop:
    _in: '${items}'
    _as: item
    _key: '${item.id}'          # stable identity — required
    # _index: i                 # optional index binding
    # _wrap: { _type: list, scroll_direction: horizontal }  # lazy wrapper
  _type: container
  ...
```

## Interaction

```yaml
_on: { tap: open_detail }                          # action by name
_on: { tap: { do: open_detail, event: '${item.id}' } }   # with event payload
# the action reads the payload as ${event...}
```

## Command types

Every driver is engine-owned and locked — apps cannot inject or replace
drivers: `set`, `api` (routes to the injected `ApiClient` dependency),
`navigate` (`route: '/screens/detail?id=${event}'`, or `method: pop` with
optional `result`), `toast` (`message`, `variant`), `modal`, `scroll`,
`anchoring`, `app_storage`, `secure_storage`, `sys_haptic`.

Everything else enters through **services**: platform capabilities
(clipboard, share, browser, webview, …) and vendor SDKs are `ExternalCommand`s
contributed by an `SduiService` (`Sdui.initialize(services: [...])`),
`sys_<thing>` by convention. There is no engine webview: webview flows differ
per app (plain page, callback capture, JS bridge), so each app models its own
as a service.

## Loop `_wrap` strategies

`row`, `wrap`, `column` (default), `serpentine`, `serpentine_row`,
`auto_scroll`, `swipe` (swipe_layout + swipe_pane carousel with `on_changed`),
`list`, `sliver_list`, `grid`, `sliver_grid`, `spin_grid`, `reorderable`,
`dismissible`. The validator rejects unknown names at compile time, and an
engine test pins the validator/runtime lists together.

## Screens and routing

The shell mounts every screen at `/screens/:id` and forwards query parameters
into the **root scope's state**: navigate with `route: '/screens/detail?id=1'`
and the template reads `${id}` directly. A declared `_state` default for the
same key (e.g. `id: null`) is overridden by the incoming query value; keys the
query omits keep their declared defaults. Declare the expected keys in
`screen.yaml#params`. A
template's `_modals` top-level key is split out by the loader and served to the
engine as modal templates.
