#!/bin/bash
# JAMFMIG-Unmanage-Batch.sh
# -------------------------------------------------------------------------------------------------------
# Server-side / admin-run. Unmanages a BATCH of Macs in Jamf Pro (sends the remove-MDM-profile command)
# from ONE trusted workstation, so the Jamf API credential NEVER has to be placed on the endpoints.
#
# Pair this with JAMFMIG-Migrate-Device.sh (the secret-free on-device step). Run this first for the
# devices that are still checking in to Jamf; then deploy the on-device script to complete enrollment
# into Intune. Devices whose Jamf profile has already expired can't receive this command — that is
# expected, and the on-device script removes the Jamf framework locally regardless.
#
# SECURITY: credentials are read from the ENVIRONMENT only. Nothing is hardcoded, nothing is written to
# disk, and the secret is never echoed. Rotate the Jamf API client if a secret was ever embedded in a
# script that reached an endpoint.
#
# Requires: Jamf Pro 10.49+ API Roles & Clients. The role needs, at minimum:
#   - Jamf Pro Server Object : 'Read Computers'
#   - Jamf Pro Server Action : 'Send Computer Remove MDM Profile Command'
# Dependencies (on the admin Mac): curl, jq.
#
# Usage:
#   export JAMF_PRO_URL="https://your.jamf.server"        # no trailing slash needed
#   export JAMF_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#   export JAMF_CLIENT_SECRET="********"                  # set interactively; do not paste into a file
#   ./JAMFMIG-Unmanage-Batch.sh serials.txt               # one serial number per line (# comments ok)
#   ./JAMFMIG-Unmanage-Batch.sh --dry-run serials.txt     # resolve + report, send nothing
#
# Provided AS IS, without warranty of any kind. Test on a pilot group before fleet use.
# -------------------------------------------------------------------------------------------------------
set -u

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then DRY_RUN=true; shift; fi
INPUT="${1:-}"

fail() { echo "ERROR: $*" >&2; exit 1; }

[[ -n "$INPUT" ]] || fail "Usage: $0 [--dry-run] <serials-file>"
[[ -f "$INPUT" ]] || fail "Serials file not found: $INPUT"
command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v jq   >/dev/null 2>&1 || fail "jq is required (brew install jq)."
[[ -n "${JAMF_PRO_URL:-}"      ]] || fail "Set JAMF_PRO_URL in the environment."
[[ -n "${JAMF_CLIENT_ID:-}"    ]] || fail "Set JAMF_CLIENT_ID in the environment."
[[ -n "${JAMF_CLIENT_SECRET:-}" ]] || fail "Set JAMF_CLIENT_SECRET in the environment."

BASE="${JAMF_PRO_URL%/}"   # strip any trailing slash

# --- Obtain an OAuth bearer token (client_credentials). Secret is never printed. ----------------------
get_token() {
  local resp http body
  resp=$(curl -s -w '\n%{http_code}' -X POST "$BASE/api/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=$JAMF_CLIENT_ID" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_secret=$JAMF_CLIENT_SECRET")
  http=$(printf '%s' "$resp" | tail -n1)
  body=$(printf '%s' "$resp" | sed '$d')
  if [[ "$http" != "200" ]]; then
    fail "Auth failed (HTTP $http). Check JAMF_PRO_URL and the API client credentials/role."
  fi
  printf '%s' "$body" | jq -r '.access_token // empty'
}

TOKEN=$(get_token)
[[ -n "$TOKEN" ]] || fail "Could not obtain an access token."
echo "Authenticated to $BASE (token length ${#TOKEN})."
$DRY_RUN && echo "DRY RUN — no unmanage commands will be sent."

resolve_id() {   # serial -> computer id (or empty)
  local serial="$1"
  curl -s -H "Authorization: Bearer $TOKEN" \
    "$BASE/api/v1/computers-inventory?filter=hardware.serialNumber==$serial" \
    | jq -r '.results[0].id // empty'
}

send_unmanage() {   # computer_id -> commandUuid (or empty)
  local id="$1"
  curl -s -X POST -H "Authorization: Bearer $TOKEN" \
    "$BASE/api/v1/computer-inventory/$id/remove-mdm-profile" \
    | jq -r '.commandUuid // empty'
}

total=0; ok=0; skip=0; failc=0
while IFS= read -r raw || [[ -n "$raw" ]]; do
  serial="$(echo "$raw" | tr -d '[:space:]')"
  [[ -z "$serial" || "$serial" == \#* ]] && continue
  total=$((total+1))

  id="$(resolve_id "$serial")"
  if [[ -z "$id" ]]; then
    echo "  SKIP  $serial — not found in Jamf (already removed / never enrolled)."
    skip=$((skip+1)); continue
  fi

  if $DRY_RUN; then
    echo "  DRY   $serial -> computer id $id (would send remove-mdm-profile)."
    ok=$((ok+1)); continue
  fi

  uuid="$(send_unmanage "$id")"
  if [[ -n "$uuid" ]]; then
    echo "  OK    $serial (id $id) — remove-mdm-profile queued, command $uuid."
    ok=$((ok+1))
  else
    echo "  FAIL  $serial (id $id) — command not accepted (device may be offline / already unmanaged)."
    failc=$((failc+1))
  fi
done < "$INPUT"

echo ""
echo "Done. total=$total  queued/ok=$ok  skipped=$skip  failed=$failc"
echo "Devices that skipped/failed here are handled on-device by JAMFMIG-Migrate-Device.sh (local framework removal)."
exit 0
