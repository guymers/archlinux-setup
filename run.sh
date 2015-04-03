#!/bin/sh
ansible-playbook --inventory-file=inventory --limit=local user.yml
sudo -H -u user ansible-playbook --inventory-file=inventory --limit=local --ask-sudo-pass local.yml
