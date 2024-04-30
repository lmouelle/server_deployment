#!/usr/bin/bash
set -euo pipefail

# bitwarden setup for initial secrets, set BWS_ACCESS_TOKEN=<your_access_token> or pass it in with ansible vault?
# https://galaxy.ansible.com/ui/repo/published/bitwarden/secrets/docs/

# I want to avoid using ansible vault, and maybe even podman secrets, if I can
# Just put everything in bitwarden and pull it with the ansible module from bitwarden
export HISTCONTROL=ignorespace
# Leading space is important here!
 export BWS_ACCESS_TOKEN=$(ansible-vault view secrets/.bw_access_token --vault-password-file secrets/.vault_passwd)

# We could use the pip and dnf module tasks inside ansible but this flow works
# better for setting up ansible dependencies I think
# git and ansible are prereqs for accessing this playbook, fish is just my personal user
# Only podman is critical to containers setup. cockpit-podman is convenince for cockpit UI,
# policycoreutils and libselinux is just because pip/PyPI does not have them

# dnf install git ansible podman fish cockpit-podman python3-policycoreutils policycoreutils-python-utils python3-libselinux -y
# pip install bitwarden-sdk

# Install dependencies for ansible run
ansible-galaxy collection install -r requirements.ansible.yml

# Run the playbook now. Preceding space is important to hide password from process history
# --syntax-check and --check for validating
 ansible-playbook --inventory inventory.ini main.ansible.yml --ask-become-pass --vault-password-file secrets/.vault_passwd

# After install and setup, some remaining tasks that I have not/can not automate:
# Set allow_remote to true for deluge core.conf, https only to true for web conf, create auth file for remote user in bitwarden,
# create web UI password, etc
# Maybe create an ansible module for that? deluge was designed to generate auth/core.conf/web.conf on first run, makes it harder