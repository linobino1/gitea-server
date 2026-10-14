# Ansible Deployment

This playbook keeps the existing Docker Compose deployment model and moves host setup, configuration rendering, and container reconciliation into Ansible.

## First deployment

1. Make the age private key matching the recipient in `.sops.yaml` available to
   SOPS, for example through `SOPS_AGE_KEY_FILE`.

2. Install the required Ansible collection:

   ```bash
   ansible-galaxy collection install -r ansible/requirements.yml
   ```

3. Run the deployment from the repository root:

    ```bash
     sops exec-file secrets/vars.enc.yaml \
       'ansible-playbook \
        -i ansible/inventory/hosts.yml -e @{} ansible/site.yml'
    ```

      The become password is stored as the encrypted `ansible_become_password`
      variable in `secrets/vars.enc.yaml`. `sops exec-file` decrypts the variables
      into a temporary file and removes it afterward. The inventory is intentionally
      kept as a normal tracked Ansible file because it contains connection metadata
      rather than secrets. `sops exec-env` is intended for dotenv files and cannot
      represent this structured Ansible variable data.

The existing `gitea`, `mysql`, `dump`, `data`, and `letsencrypt` data must remain in place when migrating an already-running host. The playbook creates `/opt/gitea-server`; change `gitea_deploy_dir` to the current Compose directory before the first run if the existing data is elsewhere.

## Override the SSH key

The SSH private key defaults to `~/.ssh/gg-admin` in
`ansible/inventory/hosts.yml`. Override it for a deployment with an Ansible
extra variable:

```bash
sops exec-file secrets/vars.enc.yaml \
  'ansible-playbook \
   -i ansible/inventory/hosts.yml \
   -e @{} \
   -e ansible_private_key_file=/path/to/private-key \
   ansible/site.yml'
```

Extra variables take precedence over the value defined in the inventory.
