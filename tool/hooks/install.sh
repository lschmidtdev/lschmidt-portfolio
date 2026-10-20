#!/usr/bin/env sh
set -eu
git config core.hooksPath tool/hooks
echo "Git hooks now come from tool/hooks."
