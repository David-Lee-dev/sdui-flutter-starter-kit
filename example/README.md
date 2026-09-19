# Example screens

This directory is the self-contained example content for the starter app —
no sibling checkout required.

```
example/
  src/        YAML sources (screens, components, tokens) — copy from here to
              start your own screen.
  compiled/   Compiled output: manifest.json + screens/<id>/<version>.json.
              This is what scripts/serve_example.mjs serves and what
              test/app/example_screens_test.dart mounts in the engine.
```

## Screens

- `home` — feed loaded on mount over the `net` command, tap-to-navigate.
- `detail` — loads one item by the `id` route parameter.
- `gallery` — a bundled-first `image` node rendering
  `assets/images/placeholder.png` with no network round-trip (see
  `lib/app/impl/image_source.dart`). Served at `GET /screens/gallery`.

## Recompiling

`compiled/` is generated from `src/` — recompile after editing the YAML:

```sh
# Python compiler (py-cplr, from the sdui-template-compiler repo)
python3 -m venv .venv && .venv/bin/pip install ../91_sdui-template-compiler/py-cplr
.venv/bin/sdui-compile example/src --out example/compiled --pretty

# or the TS compiler, same contract — see the compiler repo's README
```

Both compilers implement the same `<rootDir> --out <outDir>` contract and
produce byte-identical templates for the same source.

## Writing your first screen

Copy an existing screen directory under `src/screens/<id>/` (a `screen.yaml`
manifest + `template/<version>/_root.yaml`), edit it, recompile, and it's
served the same way — `scripts/serve_example.mjs` reads whatever screens
exist in `compiled/manifest.json`.
