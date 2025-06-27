# Overview

This repo is used to harden the OS and SSH of a VPS using the (dev-sec.io)[dev-sec.io] Ansible playbook

## Retrieving your public key
Macos: `pbcopy < ~/.ssh/id_ed25519.pub`

# The Littlest JupyterHub

Ensure permissions are set: 

`sudo chmod -R a+rX /opt/tljh/user`
`sudo chmod +x /opt/tljh/user/bin/python3`
