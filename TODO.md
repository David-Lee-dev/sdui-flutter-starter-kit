# Starter kit gaps — audit checklist (2026-09-19)

Audit of this starter against the engine's full injection surface. All required
seams (ScreenLoader / NetworkClient / ImageSource / VideoSource / AppStorage /
SecureStorage) are implemented, annotated, and tested; the ExternalCommand
service example (clipboard) is solid. What follows is what's missing for a
developer cloning this repo to build a real app.

## HIGH — blocks or misleads a cloning developer

- [ ] **Stale command vocabulary in docs/TEMPLATE-GUIDE.md** (lines 25, 75):
      says `_type: api` routing to an "injected ApiClient" — the engine and the
      shipped fixtures use `net` / `NetworkClient`. Also
      `integration_test/app_test.dart:24` comment. Rename `api`→`net`,
      `ApiClient`→`NetworkClient`.
- [ ] **Bundled-first media is advertised but never exercised**: no `assets/`
      directory, no `assets:` in pubspec, and no image/video node in either
      example screen — `AppImageSource`/`AppVideoSource`/`BundledAssetRegistry`
      never run in the demo. Bundle one image, declare assets, add an
      image/video node to an example screen.
- [ ] **Not runnable from a lone clone**: example screens live only in
      `../91_sdui-template-compiler/spec/fixtures/basic/expected` —
      `scripts/serve_example.mjs` exits and `test/app/example_screens_test.dart`
      fails without the sibling checkout, and there's no in-repo YAML to copy
      for a first custom screen. Vendor the compiled fixtures (keep the sibling
      path as an override).

## MEDIUM — engine capability with no demonstration

- [ ] Optional seams undemonstrated: no `TelemetrySink` impl (add a
      `ConsoleTelemetrySink`), `SduiErrorObserver`/`FlutterErrorObserver`
      unreferenced, no `toastPresenter`.
- [ ] Error/loading surfaces never shown: `Sdui.router()` called bare —
      `loadErrorBuilder` / `screenErrorBuilder` / `nodeErrorBuilder` /
      `loadingBuilder` appear nowhere; server-down UX is undefined.
- [ ] Extension points 3/4 missing: `widgets:`, `motions:`, `functions:` on
      `Sdui.initialize` never passed — add one small annotated example of each
      (custom WidgetSpec, custom Motion, custom expression function).
- [ ] `SduiPresentation` shown only for `tapFeedback` — add a brand
      typography/scaling/modal-style example.
- [ ] Example screens cover a narrow slice (net/set/navigate/toast/haptic, one
      `_loop`, `cond`, mount hook): no modal, no motion, no
      app_storage/secure_storage command usage, no input widgets. Add a
      kitchen-sink screen.
- [ ] `networkProtocols` (named second client) mentioned in README only, never
      demonstrated.

## LOW — polish

- [ ] No CI: ship a `.github/workflows` analyze+test workflow as the pattern.
- [ ] `docs/TEMPLATE-GUIDE.md` never links to the engine's full docs tree
      (widgets/, commands/, expressions.md, motion.md).
- [ ] No auth-shaped flow: `DeviceSecureStorage` exists but no
      token→header→login pattern; at minimum a commented header hook in
      `RestNetworkClient`.
