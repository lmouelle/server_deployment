# Download bitwarden CLI, setup secrets flow?

# Download git (would have happened before cloning this repo, but that is init step)

# Setup a common user/home dir for deployment. Then later I can stow/symlink
# from pod/service dirs to deployment user dir by giving everyone in the 'deployment'
# group perms to that (e.g. link from /home/torrents/config to /home/deployment/torrents/dot-config)
common_user=(cat common_user_name.txt)
useradd -mrU $common_user
chown 660 /home/$common_user