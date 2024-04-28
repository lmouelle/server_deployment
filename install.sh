# bitwarden setup for initial secrets

# Install dependencies for ansible run
ansible-galaxy collection install -r requirements.ansible.yml

# This pre-assumes there is a file called secrets.enc that was encrypted with 
# ansible-vault encrypt secrets.enc.
# secrets.enc will be a yml file with name: value format
# ansible-playbook -i inventory.ini -e @secrets.enc --ask-

