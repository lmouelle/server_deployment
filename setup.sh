# Any random host setup required, like SELinux permissions
# Eventually move this into a proper Ansible config, a script is fine for now though.
# Maybe use gnu stow + a makefile

me=luouelle
datadir=$datadir

# Host DNF packages. We assume git is already installed else this script
# would not be on the host, but for completeness I include it here
dnf install podman fish git stow -y # ansible (will I ever move to ansible?)

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

for container_name in (ls */.config/* | cut -f1 -d/); do
    useradd -rU $container_name -m
    usermod $me -aG $container_name
    loginctl enable-linger $container_name
    # TODO: Any SELinux file specific context to set here?
    chown -R -c $me:$container_name $container_name/ --preserve-root
    chmod 0760 -R --preserve-root -c $container_name/
    stow --target=/home/$container_name --stow --dotfiles $container_name
done

groupadd data -f -r -U restic $me
chown -Rc --preserve-root $me:data $datadir
chmod -Rc --preserve-root 0760

# Overwrite perms set above for $datadir/{comics,videos}
# TODO: Add media servers like Calibre and Jellyfin here, and *arr apps.
# Can I write some manifest in each app/service/container and have it say what host permissions it needs?
# May create 'videos', 'comics' groups for different container/users to access stuff like $datadir/videos
# Feels like I'm recreating Ansible badly here...
groupadd torrents -f -r -U deluge restic $me
chown -Rc --preserve-root $me:torrents $datadir/torrents 
chmod -Rc --preserve-root 0760

semanage fcontext $datadir -a -t container_file_t 

# TODO: Does the section below need to run as the container account?
# I believe so, test this. Do i need to run su with -l to simulate user login?
for container_name in (ls */.config/containers/systemd*.container | cut -f1 -d/); do
    su $container_name -c 'systemctl daemon-reload --user' -l
    su $container_name -c "systemctl enable $container_name --user --now" -l
done

# Need to do this so everything works? Unsure how to propogate podman secrets
# TODO: Eventually bootstrap secrets with bitwarden sync
# cat $datadir/deployment/container_configs/restic/.restic_passwd | podman secret create restic-repo-password -
# cat $datadir/deployment/container_configs/restic/.aws_secret_access_key | podman secret create aws-secret-access-key -
