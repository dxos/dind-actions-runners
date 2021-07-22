#!/usr/bin/env bash
set -euo pipefail

if [ -n "$GITHUB_PAT" ]; then
  export GITHUB_PAT
  docker-compose stop
  docker-compose up --build -d --scale dxos-actions-runner=4
else
  echo "Please add GITHUB_PAT variable."
  exit -1
fi
