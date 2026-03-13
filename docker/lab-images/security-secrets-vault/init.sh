#!/bin/bash
export VAULT_DEV_ROOT_TOKEN_ID=root
export VAULT_ADDR=http://127.0.0.1:8200
vault server -dev -dev-root-token-id=root &>/tmp/vault.log &
sleep 2
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bashrc
echo "export VAULT_TOKEN=root" >> ~/.bashrc
vault status
vault kv put secret/myapp db_password=supersecret api_key=abc123
echo "Vault ready. Tasks:"
echo "1. vault kv get secret/myapp"
echo "2. vault kv put secret/mydb username=admin password=changeme"
echo "3. vault kv list secret/"
