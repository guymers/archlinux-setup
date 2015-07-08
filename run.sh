#!/bin/sh

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

sudo -H -u user ansible-playbook --inventory-file="${dir}/inventory" --limit=local --ask-sudo-pass "${dir}/local.yml"
