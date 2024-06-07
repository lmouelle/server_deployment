#!/usr/bin/bash
set -euo pipefail

# I want to avoid using ansible vault, and maybe even podman secrets, if I can
# Just put everything in bitwarden and pull it with the ansible module from bitwarden
# Sadly bitwarden module has some issues, this prototype that only uses ansible-vault is fine for now

export HISTCONTROL=ignorespace

python -m venv bitwarden_sdk_venv
source bitwarden_sdk_venv/bin/activate
pip install bitwarden-sdk

ansible-galaxy collection install -r requirements.ansible.yml

# Run the playbook now. Preceding space is important to hide password from process history
# --syntax-check and --check for validating
 ansible-playbook --inventory inventory.ini main.ansible.yml --ask-become-pass --vault-password-file secrets/.vault_passwd

# After install and setup, some remaining tasks that I have not/can not automate:
# Set allow_remote to true for deluge core.conf, https only to true for web conf, 
# create auth file for deluge remote user (currently in bitwarden), create web UI password, etc.
# Maybe create an ansible module for that? deluge was designed to generate auth/core.conf/web.conf on first run, makes it harder
