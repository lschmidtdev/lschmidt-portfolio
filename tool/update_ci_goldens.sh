#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
docker version >/dev/null 2>&1 ||
  { echo "Docker is not running: start Docker Desktop and retry." >&2; exit 1; }
version=$(sed -n 's/^  flutter: *\([0-9][0-9.]*\).*/\1/p' pubspec.yaml | head -1)
[ -n "$version" ] || { echo "no Flutter pin found in pubspec.yaml" >&2; exit 1; }
echo "Rendering CI goldens with Flutter $version on Linux..." >&2

git ls-files -z --cached --others --exclude-standard |
  tar c --null --ignore-failed-read -T - |
  MSYS_NO_PATHCONV=1 docker run --rm -i \
    "ghcr.io/cirruslabs/flutter:$version" bash -c '
      set -e
      mkdir /w && cd /w && tar x
      apt-get update -qq >/dev/null && apt-get install -y -qq poppler-utils >/dev/null
      flutter pub get >/dev/null
      flutter test --update-goldens >&2
      find . -path "*/goldens/ci/*.png" | tar c -T -
    ' |
  tar x

git status --short -- '*/goldens/ci/*.png'
