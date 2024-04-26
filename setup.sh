#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Any random host setup required, like SELinux permissions
# Eventually move this into a proper Ansible config, a script is fine for now though.
# Maybe use gnu stow + a makefile

# One requirement is a /data drive is mounted, I guess I have to do that on OS installation?
# Find disks and create volumes/etc and mount based on UUID?

# This script should be run as sudo, from the deployment user
# We set deployment user's ~/ with 750 permissions, add all new system users to deployment user group
# Them stow/symlink to deploy user's ~/deployment_files/$package dir to each service's home dir
common_user=$(cat deployment_user_name.txt)
datadir=$(cat datadir_name.txt)

# Host DNF packages. We assume git is already installed else this script
# would not be on the host, but for completeness I include it here
dnf install podman fish git stow -y &> /dev/null # ansible (will I ever move to ansible?)

if ! userdbctl user $common_user &> /dev/null
then
    # move deployment user setup to the presetup script
    # useradd -mrU $common_user
    exit 1
fi

common_user_home=$(userdbctl user $common_user --output=classic | cut -f6 -d:)
chmod 750 $common_user_home

# These two are needed by gluetun container, the former
# to access the /dev/net/tun device and the latter so the container
# may load/read firewall rules with nftables module
setsebool -P container_use_devices=true
setsebool -P domain_kernel_load_modules=true

# Alterntaively, do not allow the container to load modules.
# Preload them in host config? These are the expected modules below, according to 
# https://github.com/containers/podman/issues/15120
# modprobe iptable_filter ip_tables iptable_nat wireguard xt_MASQUERADE
# Spent a while trying to see if I could enable these in the host some way so
# the gluetun container needs nothing in compose.yml, no luck.
# Will just set the SELinux booleans above instead

# Any kind of host NFS/Samba share setup here as well

for package in $(ls */dot-config/* -d | cut -f1 -d/); do
    common_user_group=$(userdbctl user $common_user --output=classic | cut -f5 -d:)
    if ! userdbctl user $package &> /dev/null
    then
        useradd --create-home --system --user-group $package --groups $common_user_group --shell /usr/bin/nologin --add-subids-for-system
    fi

    loginctl enable-linger $package
    # TODO: Any SELinux file specific context to set here?
    chown --recursive --changes :$package $package/ --preserve-root
    chmod 750 --recursive --changes --preserve-root $package/
    # This script must be run as root, which runs stow as root and creates symlinks with
    # root:root as owner:group. Fix that immediately after
    target_dir=$(userdbctl user $package --output=classic | cut -f6 -d:)
    stow --target=$target_dir --stow --dotfiles $package/
    chown --recursive --changes --no-dereference -P $package:$package $target_dir --preserve-root --from=root:root
done

groupadd data --force --system --users restic
chown --recursive --preserve-root :data $datadir/
chmod --recursive --changes --preserve-root 750 $datadir/

# Overwrite perms set above for $datadir/{comics,videos}
# TODO: Add media servers like Calibre and Jellyfin here, and *arr apps.
# Can I write some manifest in each app/service/container and have it say what host permissions it needs?
# May create 'videos', 'comics' groups for different container/users to access stuff like $datadir/videos
# Feels like I'm recreating Ansible badly here...
if userdbctl user restic &> /dev/null
then
    usermod restic --append --groups torrents
fi    

if userdbctl group torrents &> /dev/null
then 
    usermod torrents --append --groups data
    chown --recursive --preserve-root :torrents $datadir/torrents/ --from=:data
fi    

semanage fcontext $datadir --add --type container_file_t 
restorecon -R /data -T 0

# Now enable/start the systemd services I symlinked with stow, as the new user accounts
#for package in $(ls */dot-config/* | cut -f1 -d/); do
    # su $package -c 'systemctl daemon-reload --user' -l
    # systemd-run --no-ask-password --uid=$package -E XDG_RUNTIME_DIR=/run/user/$(id -u $package) -t --wait --pipe systemctl enable ~/.config/containers/systemd/ --now --user
#done

# Need to do this so everything works? Unsure how to propogate podman secrets
# TODO: Eventually bootstrap secrets with bitwarden sync
# cat $datadir/deployment/container_configs/restic/.restic_passwd | podman secret create restic-repo-password -
# cat $datadir/deployment/container_configs/restic/.aws_secret_access_key | podman secret create aws-secret-access-key -

printf 'Completed setup\n'