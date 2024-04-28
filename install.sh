#!/usr/bin/bash
set -euo pipefail

# bitwarden setup for initial secrets, set BWS_ACCESS_TOKEN=<your_access_token> or pass it in with ansible vault?
# https://galaxy.ansible.com/ui/repo/published/bitwarden/secrets/docs/

# I want to avoid using ansible vault, and maybe even podman secrets, if I can
# Just put everything in bitwarden and pull it with the ansible module from bitwarden
export HISTCONTROL=ignorespace
# Leading space is important here!
 export BWS_ACCESS_TOKEN=<token>

# Install dependencies for ansible run
ansible-galaxy collection install -r requirements.ansible.yml

# After install and setup, some remaining tasks that I have not/can not automate:
# Set allow_remote to true for deluge core.conf, https only to true for web conf, create auth file for remote user in bitwarden,
# create web UI password, etc
# Maybe create an ansible module for that? deluge was designed to generate auth/core.conf/web.conf on first run, makes it harder