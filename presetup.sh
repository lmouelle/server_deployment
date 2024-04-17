## This file is run as root/sudo when the machine is first configured
# Only prerequisite is git was installed to clone this script (and ssh key setup for github)

# Download bitwarden CLI, setup secrets flow?

# Download git (would have happened before cloning this repo, but that is init step)

# Setup a common user/home dir for deployment. Then later I can stow/symlink
# from pod/service dirs to deployment user dir by giving everyone in the 'deployment'
# group perms to that (e.g. link from /home/torrents/config to /home/deployment/torrents/dot-config)

