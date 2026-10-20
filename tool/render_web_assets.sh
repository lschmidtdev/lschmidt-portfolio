#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
docker version >/dev/null 2>&1 ||
  { echo "Docker is not running: start Docker Desktop and retry." >&2; exit 1; }
version=$(sed -n 's/^  flutter: *\([0-9][0-9.]*\).*/\1/p' pubspec.yaml | head -1)
[ -n "$version" ] || { echo "no Flutter pin found in pubspec.yaml" >&2; exit 1; }
echo "Rendering web images with Flutter $version on Linux..." >&2

git ls-files -z --cached --others --exclude-standard |
  tar c --null --ignore-failed-read -T - |
  MSYS_NO_PATHCONV=1 docker run --rm -i \
    "ghcr.io/cirruslabs/flutter:$version" bash -c '
      set -e
      mkdir /w && cd /w && tar x
      flutter pub get >/dev/null
      flutter test --run-skipped --tags render test/tool/render_web_assets_test.dart >&2
      tar c web/og-image.png web/favicon.png web/icons/Icon-192.png web/icons/Icon-512.png web/icons/Icon-maskable-192.png web/icons/Icon-maskable-512.png
    ' |
  tar x

git status --short -- web
