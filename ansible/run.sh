#!/bin/bash
set -e
set -o pipefail

readonly DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# if SKIP_ASK_PASS is present dont ask for a sudo password
ASK_PASS="--ask-become-pass"
if [ -n "$SKIP_ASK_PASS" ]; then
  ASK_PASS=""
fi

ansible-playbook --inventory-file="${DIR}/inventory" --limit=local "$ASK_PASS" "${DIR}/local.yml"
