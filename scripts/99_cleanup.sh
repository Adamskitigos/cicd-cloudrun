#!/usr/bin/env bash
# Nettoyage : supprime toutes les ressources du projet.
# À lancer UNIQUEMENT après la notation (le prof doit pouvoir inspecter le projet).
set -euo pipefail
source "$(dirname "$0")/config.sh"

read -r -p "Supprimer toutes les ressources de $PROJECT_ID ? (oui/non) " ANSWER
[[ "$ANSWER" == "oui" ]] || { echo "Annulé."; exit 0; }

gcloud builds triggers delete deploy-on-main --region=global --quiet || true
gcloud builds triggers delete test-on-pr --region=global --quiet || true
gcloud run services delete "$SERVICE" --region="$REGION" --quiet || true
gcloud artifacts repositories delete "$REPO" --location="$REGION" --quiet || true
gcloud iam service-accounts delete "$BUILDER_SA_EMAIL" --quiet || true
gcloud iam service-accounts delete "$RUNTIME_SA_EMAIL" --quiet || true

echo ">> Ressources supprimées."
echo "   Pour tout supprimer d'un coup : gcloud projects delete $PROJECT_ID"
