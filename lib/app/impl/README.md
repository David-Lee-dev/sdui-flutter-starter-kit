# `app/impl` — this app's dependency implementations

The engine's rule: **every `dependency/` seam is implemented by the app and
injected at boot.** The package ships no default implementations — the one
exception is telemetry, which falls back to a no-op sink so "not observing"
is a valid choice. `contract/` (currently `ExternalCommand`) is different:
those are protocols referenced by the engine and implementations at once,
not injection points.

| Dependency | Implementation here | Notes |
|---|---|---|
| `ScreenLoader` | `EtagScreenLoader` | etag/304 revalidation over plain HTTP; caching strategy is implementor freedom |
| `NetworkClient` | `RestNetworkClient` | classic REST fields straight from the template — `method`/`path`/`params`/`body` (`path: '/items/${id}'`). Speak GraphQL/gRPC-web by writing a different one — request vocabulary is the client's own |
| `ImageSource` | `AppImageSource` | **bundled-first**: srcs whose basename is in `BundledAssetRegistry` render from assets with no network; everything else falls back to HTTP with the engine's exported loading polish (fade-in + shimmer) |
| `VideoSource` | `AppVideoSource` | same bundled-first policy |
| `AppStorage` | `PrefsAppStorage` | real device storage (shared_preferences), JSON-encoded values, loaded once at boot for sync reads |
| `SecureStorage` | `DeviceSecureStorage` | platform keystore via flutter_secure_storage (iOS Keychain / Android Keystore) |
| `TelemetrySink` | (package no-op in use) | inject a sink to actually collect; runtime toggle via `Sdui.telemetryEnabled` |

`BundledAssetRegistry` indexes `assets/images/` + `assets/videos/` from the
AssetManifest at boot — ship popular assets inside the app and template srcs
naming the same file (`/assets/logo.png`) render without a round-trip;
unbundled ones fall back to the server automatically.

All of them are wired in `main.dart` through `Sdui.initialize` — miss one and
the app does not compile.

## Vendor integrations and system drivers

Beyond the required dependencies:

- **`SduiService`** — an integration (ads SDK, support chat, social login)
  bundling the `ExternalCommand`s it contributes; each command `type` becomes
  a template-callable `{ _type: ... }`. SDK setup goes in `onRegister`;
  wire with `Sdui.initialize(services: [...])`.
  **See `../service/clipboard_service.dart` for the fully-annotated example**
  — it walks through what a command is, how params/event/cancellation arrive,
  and how return / `CommandFailure` / `CommandDismissed` map onto the
  template's `_then` / `_error[code]` / `_dismiss` flows.
- Drivers cannot be injected — every driver is engine-owned and locked
  (`sys_haptic` included). Platform capabilities (clipboard, share,
  browser, ...) are `ExternalCommand`s contributed by a service, named
  `sys_<thing>` by convention. The `net` command routes to the injected
  `NetworkClient` (or a named one via `protocol:`).
