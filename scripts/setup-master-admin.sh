#!/bin/bash
# Setup Master Admin for LibyaChain
# Configures the master admin wallet and permissions

set -e

MASTER_ADMIN_ADDRESS=${1:-libya1hkkzq3pctnvefu5ekfj9m95edgmzyu6vd872pm}
HOME_DIR=${2:-~/.libyachain}
CHAIN_ID=${3:-libyachain-1}

echo "Setting up Master Admin for LibyaChain"
echo "Master Admin Address: $MASTER_ADMIN_ADDRESS"
echo "Home Directory: $HOME_DIR"
echo "Chain ID: $CHAIN_ID"
echo ""

# Ensure jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed"
    exit 1
fi

GENESIS_FILE="$HOME_DIR/config/genesis.json"

if [ ! -f "$GENESIS_FILE" ]; then
    echo "Error: Genesis file not found at $GENESIS_FILE"
    echo "Please run 'libyachaind init' first"
    exit 1
fi

echo "Configuring master admin in genesis..."

# Create temporary file
TMP_GENESIS=$(mktemp)

# Set master admin in admin module params (if admin module is enabled)
jq --arg admin "$MASTER_ADMIN_ADDRESS" '
  if .app_state.admin then
    .app_state.admin.params.master_admin = $admin |
    .app_state.admin.params.enable_action_logging = true |
    .app_state.admin.params.max_admins = 50
  else
    .
  end
' "$GENESIS_FILE" > "$TMP_GENESIS"

mv "$TMP_GENESIS" "$GENESIS_FILE"

# Grant initial balance to master admin if not already present
echo "Checking if master admin has genesis balance..."

HAS_BALANCE=$(jq --arg addr "$MASTER_ADMIN_ADDRESS" '
  .app_state.bank.balances | map(select(.address == $addr)) | length
' "$GENESIS_FILE")

if [ "$HAS_BALANCE" == "0" ]; then
    echo "Adding genesis balance to master admin..."

    TMP_GENESIS=$(mktemp)
    jq --arg addr "$MASTER_ADMIN_ADDRESS" '.app_state.bank.balances += [
      {
        "address": $addr,
        "coins": [
          {"denom": "ulydc", "amount": "10000000000000"},
          {"denom": "ulydd", "amount": "10000000000000"},
          {"denom": "uucbl", "amount": "10000000000000"}
        ]
      }
    ]' "$GENESIS_FILE" > "$TMP_GENESIS"

    mv "$TMP_GENESIS" "$GENESIS_FILE"
    echo "✅ Master admin balance added"
else
    echo "✅ Master admin already has genesis balance"
fi

echo ""
echo "✅ Master Admin Setup Complete!"
echo ""
echo "Master Admin Address: $MASTER_ADMIN_ADDRESS"
echo ""
echo "Master Admin Capabilities:"
echo "  - Full control over all blockchain operations"
echo "  - Can create/update/revoke all other admin accounts"
echo "  - Can update all module parameters"
echo "  - Can pause/unpause modules"
echo "  - Can execute emergency procedures"
echo ""
echo "Next Steps:"
echo "  1. Import or create the master admin key:"
echo "     libyachaind keys add master-admin --recover"
echo "  2. Verify the address matches: $MASTER_ADMIN_ADDRESS"
echo "  3. Create sub-admins for each currency:"
echo "     libyachaind tx authz grant <sub-admin> ..."
echo "  4. Review security best practices in docs/ADMIN_SYSTEM.md"
echo ""
echo "Security Reminders:"
echo "  ⚠️  Use hardware wallet or HSM for master admin key"
echo "  ⚠️  Never share master admin private key"
echo "  ⚠️  Enable multi-signature for critical operations"
echo "  ⚠️  Regularly review admin access and permissions"
