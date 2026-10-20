#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

PROJECT="${PROJECT:-myportfolio-f0271}"
GITHUB_REPO="${GITHUB_REPO:-lschmidtdev/lschmidt-portfolio}"
GITHUB_OWNER_ID="${GITHUB_OWNER_ID:-146366702}"
POOL=github
PROVIDER=lschmidt-portfolio
SA_NAME=github-deployer
DEPLOY_ROLES=(roles/firebasehosting.admin)

echo "== $PROJECT"
if ! gcloud projects describe "$PROJECT" >/dev/null 2>&1; then
  echo "Project $PROJECT not found or not accessible." >&2
  exit 1
fi
bash "$here/gcp-preflight.sh" "$PROJECT"
number=$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')

gcloud services enable iam.googleapis.com iamcredentials.googleapis.com \
  sts.googleapis.com firebasehosting.googleapis.com --project "$PROJECT"

if ! gcloud iam workload-identity-pools describe "$POOL" \
    --project "$PROJECT" --location global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL" --project "$PROJECT" \
    --location global --display-name "GitHub Actions"
fi

mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner_id=assertion.repository_owner_id,attribute.ref=assertion.ref,attribute.environment=assertion.environment"
condition="assertion.repository_owner_id == '${GITHUB_OWNER_ID}' && assertion.repository == '${GITHUB_REPO}'"
verb=create-oidc
if gcloud iam workload-identity-pools providers describe "$PROVIDER" \
    --project "$PROJECT" --location global --workload-identity-pool "$POOL" \
    >/dev/null 2>&1; then
  verb=update-oidc
fi
gcloud iam workload-identity-pools providers "$verb" "$PROVIDER" \
  --project "$PROJECT" --location global --workload-identity-pool "$POOL" \
  --display-name "lschmidt-portfolio repo" \
  --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "$mapping" \
  --attribute-condition "$condition"

sa="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe "$sa" --project "$PROJECT" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" --project "$PROJECT" \
    --display-name "GitHub Actions deployer"
fi
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  gcloud iam service-accounts describe "$sa" --project "$PROJECT" >/dev/null 2>&1 && break
  if ((attempt == 10)); then
    echo "Service account $sa is not visible yet; re-run the script." >&2
    exit 1
  fi
  sleep 3
done
for role in "${DEPLOY_ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$sa" \
    --role "$role" --condition None >/dev/null
done

principal="principalSet://iam.googleapis.com/projects/${number}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/${GITHUB_REPO}"
gcloud iam service-accounts add-iam-policy-binding "$sa" --project "$PROJECT" \
  --role roles/iam.workloadIdentityUser --member "$principal" >/dev/null

bash "$here/gcp-preflight.sh" "$PROJECT"

echo "GCP_WIF_PROVIDER=projects/${number}/locations/global/workloadIdentityPools/${POOL}/providers/${PROVIDER}"
echo "GCP_SERVICE_ACCOUNT=${sa}"
echo "setup-gcp: done. Next: bash tool/infra/setup-github.sh"
