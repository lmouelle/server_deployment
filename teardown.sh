#!/usr/bin/bash
set -euo pipefail

export HISTCONTROL=ignorespace
# IIRC leading space here is important to block secrets from leaking
 ansible-playbook --inventory inventory.ini teardown.ansible.yml --ask-become-pass --vault-password-file secrets/.vault_passwd