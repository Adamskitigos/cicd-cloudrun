#!/usr/bin/env bash
# Affiche l'état du service, les révisions, la répartition du trafic et les derniers builds.
set -euo pipefail
source "$(dirname "$0")/config.sh"

URL=$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)')
echo "=== URL du service : $URL"
echo
echo "=== Révisions (versions déployées)"
gcloud run revisions list --service="$SERVICE" --region="$REGION" \
  --format="table(metadata.name, metadata.labels.commit, metadata.creationTimestamp.date('%Y-%m-%d %H:%M'), status.conditions[0].status:label=READY)"
echo
echo "=== Répartition du trafic"
gcloud run services describe "$SERVICE" --region="$REGION" \
  --format="table(status.traffic[].revisionName, status.traffic[].percent, status.traffic[].tag)"
echo
echo "=== Réponse actuelle"
curl -s "$URL/version"; echo
echo
echo "=== 5 derniers builds"
gcloud builds list --limit=5 --region=global \
  --format="table(id.slice(0:8), status, createTime.date('%Y-%m-%d %H:%M'), substitutions.SHORT_SHA)"
