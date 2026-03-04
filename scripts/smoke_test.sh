#!/usr/bin/env bash
set -euo pipefail

API_URL="${1:?Usage: $0 <API_URL>}"

echo "[1/3] Health check..."
curl -sf "${API_URL}/health" | jq .

echo ""
echo "[2/3] Create item..."
ITEM_ID="item-$(date +%s)"
curl -sf -X POST "${API_URL}/items" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"${ITEM_ID}\",\"name\":\"demo\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" | jq .

echo ""
echo "[3/3] Read item..."
curl -sf "${API_URL}/items/${ITEM_ID}" | jq .

echo ""
echo "Smoke test passed."
