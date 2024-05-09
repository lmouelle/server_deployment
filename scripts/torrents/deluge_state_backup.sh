#!/usr/bin/bash

set -euo pipefail

 export AWS_ACCESS_KEY_ID=$(cat secrets/.wasabi_access_key_id)
 export AWS_SECRET_ACCESS_KEY=$(cat secrets/.wasabi_secret_access_key)
 export RESTIC_PASSWORD=$(cat secrets/.restic_passwd_deluge_state)
 export RESTIC_REPOSITORY=$(cat secrets/.restic_repo_deluge_state)

restic backup /home/torrents/deluge_state -vvv --read-concurrency 8

if ! restic check; then
    printf "Post backup check failed\n"
    exit 63
fi

restic forget --keep-daily 7 --keep-hourly 7 --keep-weekly 7 --prune

if ! restic check; then
    printf "Post prune check failed\n"
    exit 127
fi
