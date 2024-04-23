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
        useradd -mrU $package -G $common_user_group -s /usr/bin/nologin
    fi

    loginctl enable-linger $package
    # TODO: Any SELinux file specific context to set here?
    chown -Rc :$package $package/ --preserve-root
    chmod 750 -Rc --preserve-root $package/
    # This script must be run as root, which runs stow as root and creates symlinks with
    # root:root as owner:group. Fix that immediately after
    target_dir=$(userdbctl user $package --output=classic | cut -f5 -d:)
    stow --target=$target_dir --stow --dotfiles $package/
    chown -Rch $package:$package $target_dir --preserve-root
done

groupadd data -f -r -U restic
chown -Rc --preserve-root :data $datadir/
chmod -Rc --preserve-root 750 $datadir/

# Overwrite perms set above for $datadir/{comics,videos}
# TODO: Add media servers like Calibre and Jellyfin here, and *arr apps.
# Can I write some manifest in each app/service/container and have it say what host permissions it needs?
# May create 'videos', 'comics' groups for different container/users to access stuff like $datadir/videos
# Feels like I'm recreating Ansible badly here...
if userdbctl user restic 2>&1 /dev/null
then
    usermod restic -aG torrents
fi    

if userdbctl group torrents 2>&1 /dev/null
then 
    chown -Rc --preserve-root :torrents $datadir/torrents/
fi    

semanage fcontext $datadir -a -t container_file_t 
restorecon -vR /data -T 0

# Now enable/start the systemd services I symlinked with stow, as the new user accounts
for package in (ls */dot-config/* | cut -f1 -d/); do
    # su $package -c 'systemctl daemon-reload --user' -l
    # systemd-run --no-ask-password --uid=$package -E XDG_RUNTIME_DIR=/run/user/$(id -u $package) -t --wait --pipe systemctl enable ~/.config/containers/systemd/ --now --user
done

# Need to do this so everything works? Unsure how to propogate podman secrets
# TODO: Eventually bootstrap secrets with bitwarden sync
# cat $datadir/deployment/container_configs/restic/.restic_passwd | podman secret create restic-repo-password -
# cat $datadir/deployment/container_configs/restic/.aws_secret_access_key | podman secret create aws-secret-access-key -
