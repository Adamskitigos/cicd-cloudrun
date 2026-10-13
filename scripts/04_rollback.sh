#!/usr/bin/env bash
# Rollback : renvoie 100 % du trafic vers une révision précédente.
# Usage :
#   ./04_rollback.sh                 -> revient à l'avant-dernière révision
#   ./04_rollback.sh <revision>      -> revient à une révision précise
#   ./04_rollback.sh --latest        -> annule le rollback (retour à la dernière)
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--latest" ]]; then
  gcloud run services update-traffic "$SERVICE" --region="$REGION" --to-latest
  echo ">> Trafic renvoyé vers la dernière révision."
  exit 0
fi

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  CURRENT=$(gcloud run services describe "$SERVICE" --region="$REGION" \
    --format='value(status.traffic[0].revisionName)')
  TARGET=$(gcloud run revisions list --service="$SERVICE" --region="$REGION" \
    --sort-by=~metadata.creationTimestamp --format='value(metadata.name)' \
    | grep -v -x "$CURRENT" | head -n1)
fi

if [[ -z "$TARGET" ]]; then
  echo "Aucune révision précédente trouvée." >&2
  exit 1
fi

echo ">> Rollback vers : $TARGET"
gcloud run services update-traffic "$SERVICE" --region="$REGION" --to-revisions="${TARGET}=100"

URL=$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)')
echo ">> Version servie maintenant :"
curl -s "$URL/version"; echo
