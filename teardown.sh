#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# TODO: Replace this with some new ansible playbook where state: absent

for package in $(ls files/* -d | cut -f2 -d/); do
    if userdbctl user $package &> /dev/null
    then 
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