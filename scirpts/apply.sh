#!/bin/bash
set -e
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "tinkerhub-infra // applying"
echo "---------------------------"
echo ""

echo ""
echo "[2/3] containers"
bash "$SCRIPTS/containers.sh"

echo ""
echo "[3/3] subdomains"
bash "$SCRIPTS/subdomains.sh"

echo ""
echo "done."
echo ""
