#!/bin/sh

readonly dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

ansible-playbook --inventory-file="${dir}/inventory" --limit=local --ask-sudo-pass "${dir}/local.yml"
