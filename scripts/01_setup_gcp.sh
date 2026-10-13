#!/usr/bin/env bash
# Étape 1 : active les APIs, crée Artifact Registry et les comptes de service.
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo ">> Projet : $PROJECT_ID | Région : $REGION"

echo ">> Activation des APIs"
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com

echo ">> Création du dépôt Artifact Registry"
gcloud artifacts repositories describe "$REPO" --location="$REGION" >/dev/null 2>&1 || \
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Images du projet CI/CD"

echo ">> Politique de nettoyage : on garde les 5 dernières images, on supprime les autres après 7 jours"
cat > /tmp/cleanup-policy.json <<'EOF'
[
  {
    "name": "keep-last-5",
    "action": {"type": "Keep"},
    "mostRecentVersions": {"keepCount": 5}
  },
  {
    "name": "delete-old",
    "action": {"type": "Delete"},
    "condition": {"tagState": "any", "olderThan": "604800s"}
  }
]
EOF
gcloud artifacts repositories set-cleanup-policies "$REPO" \
  --location="$REGION" --policy=/tmp/cleanup-policy.json --no-dry-run

echo ">> Comptes de service"
gcloud iam service-accounts describe "$BUILDER_SA_EMAIL" >/dev/null 2>&1 || \
  gcloud iam service-accounts create "$BUILDER_SA" --display-name="Cloud Build CI/CD"
gcloud iam service-accounts describe "$RUNTIME_SA_EMAIL" >/dev/null 2>&1 || \
  gcloud iam service-accounts create "$RUNTIME_SA" --display-name="Cloud Run runtime (sans droits)"

echo ">> Droits minimaux pour le compte de build"
for ROLE in roles/run.admin roles/artifactregistry.writer roles/logging.logWriter; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${BUILDER_SA_EMAIL}" --role="$ROLE" --condition=None >/dev/null
done

# Le builder a le droit d'utiliser UNIQUEMENT le compte runtime (pas tout le projet)
gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_SA_EMAIL" \
  --member="serviceAccount:${BUILDER_SA_EMAIL}" --role="roles/iam.serviceAccountUser" >/dev/null

echo ">> Setup terminé."
echo "   Étape suivante : connecter GitHub à Cloud Build dans la console (voir ETAPES.md), puis lancer 02_create_triggers.sh"
