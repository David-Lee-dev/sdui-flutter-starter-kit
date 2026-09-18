#!/bin/bash
# Upload the built IPA to App Store Connect. Pure upload — separate from
# building (scripts/build_release.sh ios) and from review submission.
#
# Requires scripts/.appstore.env with:
#   ASC_KEY_ID=XXXXXXXXXX
#   ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# and the corresponding .p8 key installed for altool
# (~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8).

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/scripts/.appstore.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .appstore.env not found at $ENV_FILE"
  echo "Create it with ASC_KEY_ID and ASC_ISSUER_ID."
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [ -z "${ASC_KEY_ID:-}" ] || [ -z "${ASC_ISSUER_ID:-}" ]; then
  echo "Error: ASC_KEY_ID and ASC_ISSUER_ID must be set in $ENV_FILE"
  exit 1
fi

IPA=$(find "$PROJECT_DIR/build/ios/ipa" -name '*.ipa' 2>/dev/null | head -1)
if [ -z "$IPA" ]; then
  echo "Error: IPA not found in build/ios/ipa/. Run scripts/build_release.sh ios first."
  exit 1
fi

echo "Uploading $(basename "$IPA") to App Store Connect..."
xcrun altool --upload-app -t ios -f "$IPA" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"
