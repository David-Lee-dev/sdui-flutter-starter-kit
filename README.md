# Flutter SDUI Starter Kit

A Flutter project for server-driven UI (SDUI): screens are **YAML
templates on the server**, compiled to JSON and rendered by the
[`sdui_engine`](../91_sdui-starter/flutter-engine) package — ship UI changes
without app releases.

The reusable pieces (the engine and the template compilers in TS/Python/Go)
live in [`91_sdui-starter`](../91_sdui-starter); this repo is the app itself —
a runnable Flutter project plus example templates and a tiny example server.

```
┌────────────────────┐   compile    ┌──────────────────┐   HTTP GET    ┌─────────────────┐
│ YAML templates     │ ───────────▶ │ composed JSON    │ ────────────▶ │ sdui_engine      │
│ examples/sdui      │  (js-cplr)   │ + etag manifest  │  (any server) │ (package)        │
└────────────────────┘              └──────────────────┘               └─────────────────┘
                                     POST /v3/data  { op, variables }  ◀──────┘
                                     (transport-neutral data operations)
```

## Layout

| Path | What |
|---|---|
| `lib/`, `test/`, `scripts/` | The Flutter app itself: `main.dart` + env config + `lib/app/impl` over the `sdui_engine` path dependency |
| `examples/sdui` | Example SDUI root: tokens, components, two screens |
| `examples/serve-js` | Dependency-free Node server serving compiled output + data ops |
| `docs/` | Template guide |

## Quick start

```sh
# 1. Build the compiler (once) and compile the example screens
cd ../91_sdui-starter/js-cplr && pnpm install && pnpm build
node dist/cli.js ../../08_flutter-sdui-starter-kit/examples/sdui \
  --out ../../08_flutter-sdui-starter-kit/examples/serve-js/composed

# 2. Serve them
cd ../../08_flutter-sdui-starter-kit/examples/serve-js && node server.mjs 8080

# 3. Run the app from the repo root (simulator: localhost works; Android emulator: use 10.0.2.2)
cd .. && flutter run
```

## Key design points

- **Template plane is protocol-neutral.** Compiled output is static JSON + an
  etag manifest — serve it from any language, framework, or a CDN. The client
  sends `x-app-version` (template version thresholds) and `If-None-Match`
  (etag revalidation, `304` reuses the cached copy).
- **Data plane is a named-operation contract.** The engine's `api` command
  calls `execute(op, variables)` behind the required `ApiClient` dependency.
  This app's `HttpApiClient` speaks `POST /v3/data` over plain HTTP; write a
  different `ApiClient` to speak GraphQL or anything else — templates never
  change.
- **The app implements every dependency.** The engine ships no default
  implementations (telemetry's no-op aside): loader, api client, media
  sources, and storage live in `lib/app/impl` (see its README), and
  template-callable capability is added through services
  (`lib/app/service/clipboard_service.dart` is the annotated example).

## Automation (`scripts/`)

Env values are baked in at compile time from `.env.<flavor>` files
(`gen_env.sh` writes `lib/app/config/env.g.dart`; app version comes from
`pubspec.yaml`). A `--dart-define` still overrides for one-off runs.

| Script | What |
|---|---|
| `gen_env.sh [local\|dev\|prod]` | Rebake `env.g.dart` from `.env.<flavor>` |
| `set_local_ip.sh [port]` | Point `.env.local` at this machine's LAN IP (real-device testing), rebake env, refresh the Android subnet allowlist |
| `set_android_subnet.sh` | Regenerate `network_security_config.xml` for the current /24 subnet (Android can't express CIDR — hosts are enumerated) |
| `build_release.sh [all\|aos\|ios]` | Bake prod env, build obfuscated artifacts (+ crash-symbol mapping), collect to `~/Downloads/sdui_starter_build`, restore local env |
| `upload_ios.sh` | Upload the built IPA to App Store Connect (needs `scripts/.appstore.env`) |

## Verifying

```sh
flutter test   # app impls + example screens mounted in the real engine
```

Engine and compiler suites live with their packages — see
[`91_sdui-starter`](../91_sdui-starter#compilers).
