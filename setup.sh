# Any random host setup required, like SELinux permissions
# Eventually move this into a proper Ansible config, a script is fine for now though

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

for container_name in (ls */*.container | cut -f1 -d/); do
    useradd -rU $container_name -s /sbin/nologin -M -d ./$container_name/
    usermod luouelle -aG $container_name
    # reloading every time is inefficient but we want systemctl enable to see the current file
    systemctl daemon-reload
    systemctl enable --now $container_name --user $container_name

    # TODO: Create timer for restic, and volume/image defs in each service
    # TODO: Have not 1 restic script that runs backup/check/prune/check but 4
    # systemd units, each going to the next only on success. This way I do not need
    # the container to exec scripts, just run restic
done

# TODO: Add media servers like Calibre and Jellyfin here, and *arr apps.
# Can I write some manifest in each app/service/container and have it say what host permissions it needs?
# May create 'videos', 'comics' groups for different container/users to access stuff like /data/videos
groupadd torrents -f -r -U deluge restic
chown -R deluge:deluge /data/torrents 

# Need to do this so everything works? Unsure how to propogate podman secrets
# TODO: Eventually bootstrap secrets with bitwarden sync
# cat /data/deployment/container_configs/restic/.restic_passwd | podman secret create restic-repo-password -
# cat /data/deployment/container_configs/restic/.aws_secret_access_key | podman secret create aws-secret-access-key -
