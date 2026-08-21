#!/bin/bash
#
# bootstrap.sh
# Sets up a local dev environment for order-service and runs basic health checks.
# This is intentionally simple in Phase 0 - it grows as later phases add
# Docker/Kubernetes and replace parts of this with `docker compose up` etc.

set -euo pipefail

echo "== order-service bootstrap =="

# 1. Check prerequisites
for cmd in python3 pip3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

# 2. Create virtualenv if it doesn't exist
if [[ ! -d ".venv" ]]; then
  echo "Creating virtualenv..."
  python3 -m venv .venv
fi

# shellcheck disable=SC1091
source .venv/bin/activate

# 3. Install dependencies (placeholder until src/api/requirements.txt exists)
if [[ -f "src/api/requirements.txt" ]]; then
  pip3 install -q -r src/api/requirements.txt
else
  echo "(no requirements.txt yet - add one in Phase 0)"
fi

# 4. Install test dependencies (needed to run 'pytest' below)
if [[ -f "tests/requirements.txt" ]]; then
  pip3 install -q -r tests/requirements.txt
fi

echo "== bootstrap complete =="
echo "Next: implement src/api and run 'pytest' from repo root."
