# TLJH Bootstrap & Hardening Scripts

This README covers two helper scripts for your TLJH host:

- **bootstrap_user.sh**: Creates and configures a non-root sudo user, installs Docker, adds SSH keys, and enables passwordless sudo.
- **run_hardening.sh**: Disables root SSH login and password auth, installs Ansible & Git, adds the DevSec Hardening collection, and runs your hardening playbook.

---

## Prerequisites

- Ubuntu host running TLJH
- Root or sudo access
- Internet connectivity to install packages
- Both scripts (`bootstrap_user.sh` and `run_hardening.sh`) in the same directory

---

## bootstrap_user.sh

### Description

1. Prompts for a **new sudo username** and the user’s **SSH public key**.
2. Creates the user (`adduser`), adds to `sudo` group.
3. Grants passwordless sudo via `/etc/sudoers.d/010_<username>_nopasswd`.
4. Installs Docker (`docker.io`) and Docker Compose.
5. Adds the new user to the `docker` group.
6. Sets up `~/.ssh/authorized_keys` for SSH login.
7. Prints next steps to test SSH and Docker, then run `run_hardening.sh`.

### Usage

```bash
sudo chmod +x bootstrap_user.sh
sudo ./bootstrap_user.sh
```

---

## run_hardening.sh

### Description

1. Backs up `/etc/ssh/sshd_config`, then disables:
   - `PermitRootLogin`
   - `PasswordAuthentication`
2. Restarts SSH daemon.
3. Installs `ansible`, `git` (via Ansible PPA).
4. Installs the `devsec.hardening` Ansible collection.
5. Runs `ansible-playbook -i localhost, ../ansible/hardening.yml -c local`.

### Usage

```bash
sudo chmod +x run_hardening.sh
sudo ./run_hardening.sh
```

---

## Next Steps

1. **Verify SSH**: SSH in as the new user and use `sudo` without a password.
2. **Test Docker**: Run `docker run hello-world` as the new user.
3. **Inspect SSH Config**:
   ```bash
   sudo grep -E "PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config
   ```
4. **Review Ansible Logs**: Check output from the hardening playbook for any errors.
5. **Customize**:
   - Adjust `/etc/sudoers.d/010_<username>_nopasswd` if needed.
   - Modify Ansible roles or playbook (`../ansible/hardening.yml`) to suit your policies.
