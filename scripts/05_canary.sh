#!/usr/bin/env bash
# Déploiement canary : envoie un pourcentage du trafic vers la dernière révision.
# Usage : ./05_canary.sh 10      -> 10 % nouvelle version, 90 % ancienne
#         ./05_canary.sh 100     -> promotion complète
set -euo pipefail
source "$(dirname "$0")/config.sh"

PERCENT="${1:-10}"
REVS=($(gcloud run revisions list --service="$SERVICE" --region="$REGION" \
  --sort-by=~metadata.creationTimestamp --format='value(metadata.name)' --limit=2))

if [[ ${#REVS[@]} -lt 2 ]]; then
  echo "Il faut au moins 2 révisions pour un canary." >&2
  exit 1
fi
NEW="${REVS[0]}"; OLD="${REVS[1]}"

if [[ "$PERCENT" -ge 100 ]]; then
  gcloud run services update-traffic "$SERVICE" --region="$REGION" --to-revisions="${NEW}=100"
else
  gcloud run services update-traffic "$SERVICE" --region="$REGION" \
    --to-revisions="${NEW}=${PERCENT},${OLD}=$((100 - PERCENT))"
fi

echo ">> Trafic : ${NEW}=${PERCENT}% / ${OLD}=$((100 - PERCENT))%"
URL=$(gcloud run services describe "$SERVICE" --region="$REGION" --format='value(status.url)')
echo ">> 20 requêtes pour observer la répartition :"
for _ in $(seq 1 20); do
  curl -s "$URL/version" | grep -o '"version":"[^"]*"'
done | sort | uniq -c
