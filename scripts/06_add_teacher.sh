#!/usr/bin/env bash
# Ajoute le professeur comme Viewer du projet GCP (exigé par le sujet).
set -euo pipefail
source "$(dirname "$0")/config.sh"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:${TEACHER_EMAIL}" --role="roles/viewer" --condition=None
echo ">> ${TEACHER_EMAIL} ajouté en Viewer sur ${PROJECT_ID}"
