#!/bin/bash
# Point local development at this machine's LAN IP so a real device on the
# same network can reach the example server, then rebake env.g.dart and
# refresh the Android cleartext allowlist for the current subnet.

set -euo pipefail

PORT="${1:-8080}"
IP=$(ipconfig getifaddr en0)

if [ -z "$IP" ]; then
  echo "Error: Could not get IP address from en0"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.local"

sed -i '' "s|^SERVER_URL=.*|SERVER_URL='http://$IP:$PORT'|" "$ENV_FILE"
echo "SERVER_URL updated to http://$IP:$PORT"

# Env values are compile-time constants — regenerate so this script alone
# completes the change.
"$SCRIPT_DIR/gen_env.sh" local
"$SCRIPT_DIR/set_android_subnet.sh"
