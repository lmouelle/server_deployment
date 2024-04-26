#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


for package in $(ls */dot-config/* -d | cut -f1 -d/); do
    if userdbctl user $package &> /dev/null
    then 
        target_dir=$(userdbctl user $package --output=classic | cut -f6 -d:)
        stow -D --target $target_dir --dotfiles $package/

        if loginctl user-status $package &> /dev/null
        then
            loginctl terminate-user $package
        fi

        userdel $package -rZ
    fi

    if userdbctl group $package &> /dev/null
    then
        groupdel $package -f
    fi
done

if userdbctl group data &> /dev/null
then    
    groupdel data -f 
fi

# common_user=$(cat deployment_user_name.txt)
# groupdel $common_user -f

printf 'Completed teardown\n'