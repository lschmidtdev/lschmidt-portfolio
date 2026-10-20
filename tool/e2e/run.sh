#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
version=$(sed -n 's/.*"@playwright\/test": "\([0-9.]*\)".*/\1/p' "$here/package.json")
if [[ -z ${E2E_BASE_URL:-} && ! -f "$repo/build/web/flutter_bootstrap.js" ]]; then
  echo "build/web is missing; build the site and its shells first" >&2
  exit 1
fi
mount="$repo"
if command -v cygpath >/dev/null; then mount="$(cygpath -w "$repo")"; fi
MSYS_NO_PATHCONV=1 docker run --rm --ipc=host \
  -v "$mount:/repo" -v lschmidt-portfolio-e2e-node-modules:/repo/tool/e2e/node_modules \
  -e CI -e E2E_BASE_URL -e E2E_TARGET -w /repo/tool/e2e \
  "mcr.microsoft.com/playwright:v$version-noble" \
  bash -c 'npm ci --ignore-scripts --no-audit --no-fund >/dev/null && npx playwright test "$@"' -- "$@"
