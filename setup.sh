# Any random host setup required, like SELinux permissions
# Eventually move this into a proper Ansible config, a script is fine for now though

# These two are needed by gluetun container, the former
# to access the /dev/net/tun device and the latter so the container
# may load/read firewall rules with nftables module
setsebool -P container_use_devices=true
setsebool -P domain_kernel_load_modules=true

# Alterntaively, do not allow the container to load modules.
# Preload them in host config? These are the expected modules below, according to https://github.com/containers/podman/issues/15120
# Spent a while trying to see if I could enable these in the host some way so
# the gluetun container needs nothing in compose.yml, no luck.
# Will just set the SELinux booleans above instead
# modprobe iptable_filter ip_tables iptable_nat wireguard xt_MASQUERADE

# We also have file/user permissions on the /data directory, anything from me there?

# Load the podman application/extension for fedora cockpit automatically somehow

# Any kind of NFS/Samba share setup here as well

# Should restic and bitwarden CLI also be a container or installed natively on host?
# Only potential issue is file permissions, how to mount volumes correctly?
# Also how to script it inside a container? Container does the script work, but
# how can I schedule container runs??? Maybe I have to use a systemd timer/service for the host
# If I create a systemd timer/service anyways, why bother with the restic container?
# I would not need to install the restic binary I guess... different upstream, fedora proj vs whoever
# made the container. Little difference either way, container would be more consistent though.
# Real issue is how to pass secrets files to the container?
# https://www.redhat.com/sysadmin/podman-kubernetes-secrets this is a promising answer?
# Requires host setup script though. Ugh
# Spent a lot of time looking at this, podman-compose still cannot set secrets as environment vars
# All secrets are mounted on /run/secrets/$NAME as files. I do not see how to set AWS env vars easily from within podman compose...
# Maybe just make a wrapper script??
# https://github.com/containers/podman-compose/pull/856


# Make sure that hostname is always 'nas' or podman compose will fail on restic, which
# wants hostname specified