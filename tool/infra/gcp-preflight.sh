#!/usr/bin/env bash
set -euo pipefail

project=${1:?usage: gcp-preflight.sh <project>}
gcloud=${GCLOUD:-gcloud}

fail() {
  echo "preflight: $project: $1" >&2
  exit 1
}

errors=$(mktemp)
trap 'rm -f "$errors"' EXIT

if ! "$gcloud" projects describe "$project" --format='value(projectId)' \
    >/dev/null 2>"$errors"; then
  fail "project not found or not readable: $(<"$errors")"
fi
echo "preflight: $project exists"

if ! accounts=$("$gcloud" iam service-accounts list --project "$project" \
    --format='value(email)' 2>"$errors" | tr -d '\r'); then
  fail "cannot list the service accounts: $(<"$errors")
Enable iam.googleapis.com in the project, then re-run."
fi

keyed=()
while IFS= read -r account; do
  [[ -z $account ]] && continue
  if ! keys=$("$gcloud" iam service-accounts keys list --iam-account "$account" \
      --managed-by user --project "$project" --format='value(name)' 2>"$errors" | tr -d '\r'); then
    fail "cannot list the keys of $account: $(<"$errors")"
  fi
  if [[ -n $keys ]]; then
    keyed+=("$account")
  fi
done <<<"$accounts"

if ((${#keyed[@]} > 0)); then
  fail "user-managed key found on: ${keyed[*]}. Delete it (gcloud iam service-accounts keys delete) before continuing; deploys are keyless."
fi
echo "preflight: $project: no user-managed service-account keys"
