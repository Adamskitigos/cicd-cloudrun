#!/usr/bin/env bash
# Configuration commune à tous les scripts. Modifiez ces valeurs.
export PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
export REGION="${REGION:-europe-west1}"
export SERVICE="${SERVICE:-cicd-demo}"
export REPO="${REPO:-cicd-repo}"
export BUILDER_SA="cicd-builder"
export RUNTIME_SA="cicd-runtime"

# Dépôt GitHub (owner/nom) connecté à Cloud Build
export GITHUB_OWNER="${GITHUB_OWNER:-VOTRE_USER_GITHUB}"
export GITHUB_REPO="${GITHUB_REPO:-cicd-cloudrun}"

# Compte du professeur à ajouter en Viewer
export TEACHER_EMAIL="juan-angel.lorenzo-delcastillo@cyu.fr"

if [[ -z "$PROJECT_ID" ]]; then
  echo "PROJECT_ID non défini : lancez 'gcloud config set project <ID>'" >&2
  exit 1
fi

BUILDER_SA_EMAIL="${BUILDER_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
RUNTIME_SA_EMAIL="${RUNTIME_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
export BUILDER_SA_EMAIL RUNTIME_SA_EMAIL
