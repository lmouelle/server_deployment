#!/bin/bash

export AWS_ACCESS_KEY_ID=$(cat /usr/local/bin/.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(cat /usr/local/bin/.aws_secret_access_key)
export RESTIC_PASSWORD=$(cat /usr/local/bin/.restic_passwd)
export RESTIC_REPOSITORY=s3:https://s3.us-west-1.wasabisys.com/backups-luouelle

restic backup /srv/samba -vvv

# run restic check and panic if there is errors
if ! restic check; then
    printf "Post backup check failed\n"
    exit 127
fi

# run restic prune with a policy
restic forget --keep-daily 7 --prune

# run restic check and panic if there is errors
if ! restic check; then
    printf "Post prune check failed\n"
    exit 127
fi
