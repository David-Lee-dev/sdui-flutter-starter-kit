# Flutter SDUI Starter Kit

A Flutter project for server-driven UI (SDUI): screens are **YAML
templates on the server**, compiled to JSON and rendered by the
[`sdui_engine`](https://github.com/David-Lee-dev/sdui-flutter-engine)
package — ship UI changes without app releases.

This repo is the app itself: a runnable Flutter project that implements
every engine dependency the way a real app would (device storage, REST
networking, bundled-first media), plus a one-file example server so it runs
out of the box. The reusable pieces live in sibling repos:

| Repo | Role | Checked out as |
|---|---|---|
| [sdui-template-compiler](https://github.com/David-Lee-dev/sdui-template-compiler) | YAML → composed JSON + etag manifest (TS/Python/Go) | `../91_sdui-template-compiler` |
| [sdui-flutter-engine](https://github.com/David-Lee-dev/sdui-flutter-engine) | Renders the compiled JSON reactively | `../92_sdui-flutter-engine` |

```text
┌──────────────────┐  sdui-compile  ┌──────────────────┐  GET /screens/<id>  ┌──────────────┐
│ YAML templates   │ ─────────────▶ │ composed JSON    │ ──────────────────▶ │ this app     │
│ (server-owned)   │                │ + etag manifest  │   (etag / 304)      │ (sdui_engine)│
└──────────────────┘                └──────────────────┘                     └──────┬───────┘
                                      your REST endpoints  ◀── net command ─────────┘
                                      (method/path/params/body in templates)
```

## Quick start

Runs standalone from a lone clone — the compiled example screens are
vendored in `example/compiled/` (sources to copy from are in `example/src/`,
see `example/README.md`):

```sh
# 1. Serve the example screens + data (dependency-free Node, one file)
node scripts/serve_example.mjs        # port 8080

# 2. Run the app (iOS simulator: localhost works; Android emulator: use 10.0.2.2)
flutter run
```

Home renders a feed loaded over the `net` command; tapping a row navigates
to `/screens/detail?id=…` — the full loop (template → data → interaction →
navigation) with no app-side screen code. `/screens/gallery` demonstrates
bundled-first media (an `image` node rendering `assets/images/` with no
network round-trip).

To edit or add screens, check out the compiler repo as a sibling
(`../91_sdui-template-compiler`) and recompile into `example/compiled/`.

## What to look at

- **`lib/main.dart`** — the whole app boot: implement every dependency,
  inject via `Sdui.initialize`, hand routing to `Sdui.router()`.
- **`lib/app/impl/`** — the dependency implementations (see its README):
  etag screen loader, REST network client, bundled-first media sources,
  shared_preferences / keystore storage.
- **`lib/app/service/clipboard_service.dart`** — the annotated example of
  adding template-callable capability (`SduiService` + `ExternalCommand`).
- **`scripts/serve_example.mjs`** — the serving contract in ~150 lines:
  static compiled JSON with app-version thresholds + etag revalidation,
  plus the two REST data routes the example screens call.

## Key design points

- **Template plane is protocol-neutral.** Compiled output is static JSON +
  an etag manifest — serve it from any language or a CDN. This app sends
  `x-app-version` (template version thresholds) and `If-None-Match` (etag
  revalidation; `304` reuses the cached copy).
- **Data plane is app vocabulary.** The engine's `net` command forwards its
  fields verbatim to the injected `NetworkClient` — the engine never
  interprets them. This app's `RestNetworkClient` reads classic REST fields
  (`method`/`path`/`params`/`body`) straight from the template; a GraphQL
  app would define its own fields instead. Mixing transports is a
  `protocol:` field away (`Sdui.initialize(networkProtocols:)`).
- **The app implements every dependency.** The engine ships no default
  implementations (telemetry's no-op aside) — loader, network, media, and
  storage all live here, and missing one fails the build, not runtime.

## Automation (`scripts/`)

Env values are baked in at compile time from `.env.<flavor>` files
(`gen_env.sh` writes `lib/app/config/env.g.dart`; app version comes from
`pubspec.yaml`). A `--dart-define` still overrides for one-off runs.

| Script | What |
|---|---|
| `serve_example.mjs [port]` | Example server: compiled fixture screens + REST data routes |
| `gen_env.sh [local\|dev\|prod]` | Rebake `env.g.dart` from `.env.<flavor>` |
| `set_local_ip.sh [port]` | Point `.env.local` at this machine's LAN IP (real-device testing), rebake env, refresh the Android subnet allowlist |
| `set_android_subnet.sh` | Regenerate `network_security_config.xml` for the current /24 subnet |
| `build_release.sh [all\|aos\|ios]` | Bake prod env, build obfuscated artifacts, collect to `~/Downloads/sdui_starter_build`, restore local env |
| `upload_ios.sh` | Upload the built IPA to App Store Connect (needs `scripts/.appstore.env`) |

## Verifying

```sh
flutter test                                   # impls + example screens in the real engine
node scripts/serve_example.mjs &               # then, on a booted simulator:
flutter test integration_test -d <device-id>   # real HTTP, real gestures, home -> detail
```

Engine and compiler suites live with their packages.
