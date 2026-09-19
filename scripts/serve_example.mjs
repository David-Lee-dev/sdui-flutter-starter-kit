#!/usr/bin/env node
// Dependency-free example server for the starter app.
//
// Serves the compiler conformance fixture (`basic` — the same two screens the
// widget tests mount) straight from the sibling compiler checkout, plus the
// data operations those screens call. Nothing here is part of the SDUI
// contract beyond the two routes the app's impls speak:
//
//   GET /screens/<id>    x-app-version, If-None-Match -> 304 | 200+ETag
//   GET /feed            -> { data: { items } }        (op HomeFeed)
//   GET /items/<id>      -> { data: { item } }         (op ItemDetail)
//
// Usage: node scripts/serve_example.mjs [port]   (default 8080)

import { existsSync, readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
// In-repo vendored copy first (works from a lone clone); fall back to the
// sibling compiler checkout, which stays useful for testing against a
// freshly-recompiled fixture without re-vendoring.
const IN_REPO_FIXTURE = join(HERE, '../example/compiled');
const SIBLING_FIXTURE = join(
  HERE,
  '../../91_sdui-template-compiler/spec/fixtures/basic/expected',
);
const FIXTURE = existsSync(join(IN_REPO_FIXTURE, 'manifest.json'))
  ? IN_REPO_FIXTURE
  : SIBLING_FIXTURE;

let manifest;
try {
  manifest = JSON.parse(readFileSync(join(FIXTURE, 'manifest.json'), 'utf8'));
} catch {
  console.error(
    `Compiled example screens not found at:\n  ${FIXTURE}\n` +
      'Either restore example/compiled (vendored in this repo) or check out ' +
      'the compiler repo as a sibling directory:\n' +
      '  git clone https://github.com/David-Lee-dev/sdui-template-compiler.git ../91_sdui-template-compiler',
  );
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Data plane — the REST routes the app's RestNetworkClient op table points
// at (see lib/main.dart). Shapes mirror test/app/example_screens_test.dart.

const ITEMS = [
  {
    id: 1,
    emoji: '🚀',
    title: 'Server-driven UI',
    subtitle: 'Ship screens without app releases',
    description:
      'Screens are YAML on the server: compiled to JSON, rendered natively ' +
      'by the engine, and updated without shipping a new app build.',
  },
  {
    id: 2,
    emoji: '🧩',
    title: 'Components & tokens',
    subtitle: 'Author DRY, serve flat',
    description:
      'Shared components and design tokens are resolved at compile time — ' +
      'the client only ever sees plain JSON.',
  },
  {
    id: 3,
    emoji: '🔁',
    title: 'Versioned templates',
    subtitle: 'Old apps keep working',
    description:
      'Each screen maps app-version thresholds to template versions, so ' +
      'older clients keep receiving trees they understand.',
  },
];

function feed() {
  return {
    items: ITEMS.map(({ id, emoji, title, subtitle }) => ({
      id,
      emoji,
      title,
      subtitle,
    })),
  };
}

function itemDetail(rawId) {
  const item = ITEMS.find((entry) => entry.id === Number(rawId));
  if (item === undefined) return null;
  const { subtitle, ...detail } = item;
  return { item: detail };
}

// ---------------------------------------------------------------------------
// Template plane — static serving of the compiled fixture with app-version
// threshold selection and etag revalidation (see the compiler repo's
// docs/integration.md for the algorithm).

function compareSemver(left, right) {
  const a = left.split('.');
  const b = right.split('.');
  for (let i = 0; i < 3; i += 1) {
    const d =
      a[i].length - b[i].length || (a[i] < b[i] ? -1 : a[i] > b[i] ? 1 : 0);
    if (d !== 0) return d;
  }
  return 0;
}

function resolveTemplateVersion(screen, appVersion) {
  const thresholds = Object.keys(screen.versions).sort(compareSemver);
  let selected = thresholds[0];
  if (appVersion && /^(0|[1-9]\d*)(\.(0|[1-9]\d*)){2}$/.test(appVersion)) {
    for (const threshold of thresholds) {
      if (compareSemver(threshold, appVersion) <= 0) selected = threshold;
    }
  }
  return screen.versions[selected].template;
}

function serveScreen(request, response, screenId) {
  const screen = manifest[screenId];
  if (screen === undefined) {
    response.writeHead(404).end(`unknown screen: ${screenId}`);
    return;
  }
  const version = resolveTemplateVersion(
    screen,
    request.headers['x-app-version'],
  );
  const etag = `"${screen.etags[version]}"`;
  if (request.headers['if-none-match'] === etag) {
    response.writeHead(304).end();
    return;
  }
  const body = readFileSync(join(FIXTURE, 'screens', screenId, `${version}.json`));
  response
    .writeHead(200, { 'content-type': 'application/json', etag })
    .end(body);
}

function json(response, status, payload) {
  response
    .writeHead(status, { 'content-type': 'application/json' })
    .end(JSON.stringify(payload));
}

const port = Number(process.argv[2] ?? 8080);
createServer((request, response) => {
  const path = new URL(request.url, 'http://localhost').pathname;
  const screenMatch = /^\/screens\/([^/]+)$/.exec(path);
  const itemMatch = /^\/items\/([^/]+)$/.exec(path);
  if (request.method !== 'GET') {
    response.writeHead(404).end();
  } else if (screenMatch !== null) {
    serveScreen(request, response, decodeURIComponent(screenMatch[1]));
  } else if (path === '/feed') {
    json(response, 200, { data: feed() });
  } else if (itemMatch !== null) {
    const detail = itemDetail(decodeURIComponent(itemMatch[1]));
    if (detail === null) json(response, 404, { errorCode: 'NOT_FOUND' });
    else json(response, 200, { data: detail });
  } else {
    response.writeHead(404).end();
  }
}).listen(port, () => {
  console.log(
    `SDUI example server on http://localhost:${port}\n` +
      `  screens: ${Object.keys(manifest).join(', ')}   (from ${FIXTURE})`,
  );
});
