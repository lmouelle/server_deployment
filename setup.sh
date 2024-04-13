# Any random host setup required, like SELinux permissions
# Eventually move this into a proper Ansible config, a script is fine for now though

# Plan, options, techs:
# quadlets (https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
# let me integrate systemd in and easily manage with host OS, logical
# choice for restic type automations on a timer. I see no 'network_mode'
# feature on sight to easily route deluge traffic through the gluetun container though.
# podman compose does not support secrets into container env vars, and is awkward
# for stuff like restic that should not run on compose up but on a timer schedule.
# Ansible is complex but can do everything, prob replace these script for stuff like
# SELinux settings. Or just a long ass shell script?

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

# We also have file/user permissions on the /data directory, anything from me there?

# Any kind of NFS/Samba share setup here as well

# This is required for quadlets, https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#network
# They only scan these paths for non-root containers:
# $XDG_CONFIG_HOME/containers/systemd/ or ~/.config/containers/systemd/
# /etc/containers/systemd/users/$(UID)
# /etc/containers/systemd/users/
# and /etc/containers/systemd for root containers
# TODO: Can I use something like gnu stow for symlink management here?


# Symlink the quadlet files to the UID of each new user
# ... Or root user can start containers, but the containers run as nonroot?

for container_name in (ls */*.container | cut -f1 -d/); do
    useradd -rmU $container_name -s /sbin/nologin
    usermod luouelle -aG $container_name
    # TODO: Consider replacing this with gnu stow
    mkdir -p /home/$container_name/.config/containers/systemd/
    ln -s $container_name/$container_name.container /home/$container_name/.config/containers/systemd/
    # reloading every time is inefficient but we want systemctl enable to see the current file
    systemctl daemon-reload
    systemctl enable --now /home/$container_name/.config/containers/systemd/$container_name.container --user $container_name

    # TODO: systemctl enable the user defined podman service file
    # TODO: Create timer for restic, and volume/image defs in each
    # TODO: Have not 1 restic script that runs backup/check/prune/check but 4
    # systemd units, each going to the next only on success. This way I do not need
    # the container to exec scripts, just run restic
done

# TODO: Add media servers like Calibre and Jellyfin here
chown -R deluge:deluge /data/torrents 

# Need to do this so everything works? Unsure how to propogate podman secrets
# TODO: Eventually bootstrap secrets with bitwarden sync
# cat /data/deployment/container_configs/restic/.restic_passwd | podman secret create restic-repo-password -
# cat /data/deployment/container_configs/restic/.aws_secret_access_key | podman secret create aws-secret-access-key -
