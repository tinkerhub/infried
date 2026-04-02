#!/bin/bash
set -e
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "tinkerhub-infra // applying"
echo "---------------------------"
echo ""

echo "[1/3] networks"
bash "$SCRIPTS/apply-networks.sh"

echo ""
echo "[2/3] containers"
bash "$SCRIPTS/apply-containers.sh"

echo ""
echo "[3/3] subdomains"
bash "$SCRIPTS/apply-subdomains.sh"

echo ""
echo "done."
echo ""
