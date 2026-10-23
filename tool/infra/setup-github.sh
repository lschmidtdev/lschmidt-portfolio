#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPO:-lschmidtdev/lschmidt-portfolio}"
FIREBASE_PROJECT="${FIREBASE_PROJECT:-myportfolio-f0271}"
PROJECT_NUMBER="${PROJECT_NUMBER:-559307365405}"
SITE_URL="${SITE_URL:-https://lschmidt.tech}"
gh=${GH:-gh}
here="$(cd "$(dirname "$0")" && pwd)"

WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github/providers/lschmidt-portfolio"
SERVICE_ACCOUNT="github-deployer@${FIREBASE_PROJECT}.iam.gserviceaccount.com"

die() {
  echo "setup-github: $1" >&2
  exit 1
}

echo "== merge settings"
"$gh" api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK >/dev/null

echo "== secret scanning and push protection"
"$gh" api -X PATCH "repos/$REPO" --input - >/dev/null <<'JSON'
{"security_and_analysis": {
  "secret_scanning": {"status": "enabled"},
  "secret_scanning_push_protection": {"status": "enabled"}
}}
JSON

echo "== environments"
"$gh" api -X PUT "repos/$REPO/environments/preview" --input - >/dev/null <<'JSON'
{"wait_timer": 0, "prevent_self_review": false, "reviewers": [],
 "deployment_branch_policy": null}
JSON
"$gh" api -X PUT "repos/$REPO/environments/live" --input - >/dev/null <<'JSON'
{"wait_timer": 0, "prevent_self_review": false, "reviewers": [],
 "deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
JSON
policies=$("$gh" api "repos/$REPO/environments/live/deployment-branch-policies"   --jq '.branch_policies[].name')
if ! grep -qx main <<<"$policies"; then
  "$gh" api -X POST "repos/$REPO/environments/live/deployment-branch-policies"     -f name=main -f type=branch >/dev/null
fi
for env in preview live; do
  rules=$("$gh" api "repos/$REPO/environments/$env" --jq     '[.protection_rules[]? | select(.type == "required_reviewers" or .type == "wait_timer") | .type] | join(",")')
  [[ -z $rules ]] || die "environment $env has protection rules ($rules); remove them (Settings > Environments > $env)"
done

echo "== variables"
set_var() {
  "$gh" variable set "$1" --repo "$REPO" --body "$2" >/dev/null
}
set_var FIREBASE_PROJECT "$FIREBASE_PROJECT"
set_var GCP_WIF_PROVIDER "$WIF_PROVIDER"
set_var GCP_SERVICE_ACCOUNT "$SERVICE_ACCOUNT"
set_var SITE_URL "$SITE_URL"
set_var DEPLOY_CHANNEL live

echo "== ruleset"
body=$(<"$here/github/ruleset-main.json")
id=$("$gh" api "repos/$REPO/rulesets" --jq '.[] | select(.name == "main") | .id')
if [[ -n $id ]]; then
  "$gh" api -X PUT "repos/$REPO/rulesets/$id" --input - <<<"$body" >/dev/null
else
  "$gh" api -X POST "repos/$REPO/rulesets" --input - <<<"$body" >/dev/null
  id=$("$gh" api "repos/$REPO/rulesets" --jq '.[] | select(.name == "main") | .id')
fi
[[ -n $id ]] || die "ruleset main was not created"

echo "== assertions"
scanning=$("$gh" api "repos/$REPO" --jq '.security_and_analysis.secret_scanning.status')
[[ $scanning == enabled ]] || die "secret scanning is '$scanning', expected enabled"
echo "secret scanning: enabled"

protection=$("$gh" api "repos/$REPO" --jq '.security_and_analysis.secret_scanning_push_protection.status')
[[ $protection == enabled ]] || die "push protection is '$protection', expected enabled"
echo "push protection: enabled"

channel=$("$gh" variable get DEPLOY_CHANNEL --repo "$REPO")
[[ $channel == live ]] || die "DEPLOY_CHANNEL is '$channel', expected live"
echo "DEPLOY_CHANNEL=live"

live_policies=$("$gh" api "repos/$REPO/environments/live/deployment-branch-policies" \
  --jq '.branch_policies[].name')
[[ $live_policies == main ]] || die "live environment branches are '$live_policies', expected only main; delete the extra policies by hand (Settings > Environments > live > Deployment branches)"
echo "live environment: main only"

actual=$("$gh" api "repos/$REPO/rulesets/$id" --jq \
  '[.enforcement, (.bypass_actors | length | tostring), ([.rules[] | select(.type == "required_status_checks") | .parameters | ((.strict_required_status_checks_policy | tostring), ([.required_status_checks[] | "\(.context)@\(.integration_id)"] | sort | join(",")))] | join(";")), ([.rules[].type] | sort | join(",")), (.conditions.ref_name.include | sort | join(","))] | join("|")')
expected='active|0|true;gitleaks@15368,pr-title@15368,verify / build@15368,workflow-lint@15368|deletion,non_fast_forward,pull_request,required_linear_history,required_status_checks|refs/heads/main'
[[ $actual == "$expected" ]] || die "ruleset main is '$actual', expected '$expected'"
echo "ruleset main: as expected"
