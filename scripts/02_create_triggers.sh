#!/usr/bin/env bash
# Étape 2 : crée les triggers Cloud Build (push sur main + pull requests).
# Prérequis : l'app GitHub "Google Cloud Build" est installée sur votre dépôt
# (Console > Cloud Build > Triggers > Connect repository).
set -euo pipefail
source "$(dirname "$0")/config.sh"

SA_PATH="projects/${PROJECT_ID}/serviceAccounts/${BUILDER_SA_EMAIL}"

echo ">> Trigger CD : push sur main -> test, build, deploy"
gcloud builds triggers create github \
  --name="deploy-on-main" \
  --region=global \
  --repo-owner="$GITHUB_OWNER" \
  --repo-name="$GITHUB_REPO" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.yaml" \
  --service-account="$SA_PATH" \
  --description="CI/CD : test + build + deploy Cloud Run"

echo ">> Trigger CI : pull request vers main -> test + build uniquement"
gcloud builds triggers create github \
  --name="test-on-pr" \
  --region=global \
  --repo-owner="$GITHUB_OWNER" \
  --repo-name="$GITHUB_REPO" \
  --pull-request-pattern="^main$" \
  --build-config="cloudbuild-pr.yaml" \
  --service-account="$SA_PATH" \
  --description="CI : tests sur pull request"

gcloud builds triggers list --region=global
echo ">> Triggers créés. Faites un 'git push' sur main pour lancer le premier déploiement."
