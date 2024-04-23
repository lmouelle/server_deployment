#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


for package in $(ls */dot-config/* -d | cut -f1 -d/); do
    target_dir=$(userdbctl user $package --output=classic | cut -f5 -d:)
    stow -D --target $target_dir --dotfiles $package/

    if loginctl user-status $package
    then
        loginctl kill-user $package
    fi
    userdel $package -rZ
    groupdel $package -f
done

groupdel data -f 

# common_user=$(cat deployment_user_name.txt)
# groupdel $common_user -f