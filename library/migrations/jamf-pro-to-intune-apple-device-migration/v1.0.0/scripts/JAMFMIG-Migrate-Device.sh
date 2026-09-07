#!/bin/bash
# JAMFMIG-Migrate-Device.sh
# -------------------------------------------------------------------------------------------------------
# On-device step of a Jamf Pro -> Microsoft Intune macOS migration. Runs as ROOT (deploy via a Jamf
# policy, or run locally with sudo). Removes the Jamf framework locally, clears the Entra WorkplaceJoin
# certificates, and starts Intune enrollment — WITHOUT erasing the Mac or the user's data/profile.
#
# WHY THIS VERSION:
#   * NO SECRETS ON THE ENDPOINT. The Jamf API unmanage is done separately, server-side, by
#     JAMFMIG-Unmanage-Batch.sh. This script needs no Jamf credentials at all.
#   * EXPIRED / OFFLINE-SAFE. Devices whose Jamf MDM profile has already expired (the exact reason many
#     orgs migrate) are handled: the local `jamf removeFramework` runs best-effort and the script never
#     aborts just because the server could not push an unmanage command.
#   * NO WIPE. ADE devices re-enroll in place via `profiles renew`; user-approved devices enroll via
#     Company Portal. Neither path erases the Mac.
#
# PREREQUISITE FOR ADE DEVICES: the device must already be re-assigned to the *Intune* MDM server in
# Apple Business Manager, with an Intune enrollment profile assigned. Without that, `profiles renew`
# has nothing new to pull. Confirm with JAMFMIG-Get-ABMAssignments before running at scale.
#
# Provided AS IS, without warranty of any kind. Pilot before fleet use.
# -------------------------------------------------------------------------------------------------------
set -u

LOG="/Library/Logs/JamfIntuneMigration/migrate-device.log"
CP_URL="https://go.microsoft.com/fwlink?linkid=853070"   # Intune Company Portal for macOS
PROFILE_WAIT_TIMEOUT=180   # seconds to wait for local MDM profile to disappear (short, offline-safe)

mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1
echo "$(date '+%Y-%m-%d %H:%M:%S') | ---- Jamf -> Intune on-device migration starting ----"

# --- Must be root -------------------------------------------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: run as root (sudo / Jamf policy). Exiting." >&2
  exit 1
fi

logged_in_user=$(stat -f%Su /dev/console)
echo "Console user: ${logged_in_user:-<none>}"

# --- User-facing dialog helpers (osascript — no external UI dependency) -------------------------------
user_dialog() {   # message  [button]
  local msg="$1"; local btn="${2:-OK}"
  [[ -z "$logged_in_user" || "$logged_in_user" == "root" ]] && { echo "(no console user; skipping dialog)"; return 0; }
  /usr/bin/sudo -u "$logged_in_user" /usr/bin/osascript <<EOF 2>/dev/null || true
display dialog "$msg" buttons {"$btn"} default button "$btn" with title "Device Migration" giving up after 300
EOF
}

# --- Is this device ADE (Automated Device Enrollment / DEP)? ------------------------------------------
ADE_ENROLLED=false
if profiles status -type enrollment 2>/dev/null | grep -qi "Enrolled via DEP: Yes"; then
  ADE_ENROLLED=true
fi
echo "ADE enrolled: $ADE_ENROLLED"

# --- Install Company Portal if missing (non-ADE devices enroll through it) ----------------------------
install_company_portal() {
  if [[ -d "/Applications/Company Portal.app" ]]; then
    echo "Company Portal already present."
    return 0
  fi
  echo "Downloading Company Portal..."
  if curl -fsSL -o /tmp/cp.pkg "$CP_URL"; then
    installer -pkg /tmp/cp.pkg -target / && echo "Company Portal installed." || echo "WARN: Company Portal install failed."
    rm -f /tmp/cp.pkg
  else
    echo "WARN: Company Portal download failed (device may enroll via ADE instead)."
  fi
}

# --- Remove the Jamf framework locally (best-effort; never abort) -------------------------------------
remove_jamf_framework() {
  if command -v jamf >/dev/null 2>&1; then
    echo "Removing Jamf framework..."
    /usr/local/bin/jamf removeFramework >/dev/null 2>&1 \
      && echo "Jamf framework removed." \
      || echo "WARN: 'jamf removeFramework' returned non-zero (continuing)."
  else
    echo "Jamf binary not present (profile likely already expired/removed) — continuing."
  fi
}

# --- Wait (bounded) for the local MDM profile to clear; skip if already gone ---------------------------
wait_for_mdm_removal() {
  local elapsed=0
  while true; do
    local out
    out=$(profiles show -type enrollment 2>/dev/null)
    if [[ -z "$out" ]] || echo "$out" | grep -qi "There are no configuration profiles" \
       || ! echo "$out" | grep -qi "com.apple.mdm"; then
      echo "No MDM enrollment profile present."
      return 0
    fi
    if (( elapsed >= PROFILE_WAIT_TIMEOUT )); then
      echo "WARN: MDM profile still present after ${PROFILE_WAIT_TIMEOUT}s — continuing anyway."
      return 0
    fi
    sleep 5; elapsed=$((elapsed+5))
  done
}

# --- Remove Entra WorkplaceJoin (MS-Organization-Access) certs from the user's login keychain ---------
# Left behind from prior Entra device registration; can block a fresh Intune enrollment if not cleared.
remove_workplacejoin_certs() {
  [[ -z "$logged_in_user" || "$logged_in_user" == "root" ]] && { echo "No console user; skipping cert cleanup."; return 0; }
  local kc="/Users/$logged_in_user/Library/Keychains/login.keychain-db"
  [[ -f "$kc" ]] || { echo "Login keychain not found; skipping cert cleanup."; return 0; }

  local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
  sudo -u "$logged_in_user" security find-certificate -a -Z -p "$kc" 2>/dev/null > "$tmp/all.txt" || true

  local n=0 hash="" found=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^SHA-1\ hash:\ (.+)$ ]]; then
      hash="${BASH_REMATCH[1]}"
    elif [[ "$line" == "-----BEGIN CERTIFICATE-----" ]]; then
      n=$((n+1)); echo "$hash" > "$tmp/c$n.hash"; echo "$line" > "$tmp/c$n.pem"
    elif [[ -f "$tmp/c$n.pem" ]]; then
      echo "$line" >> "$tmp/c$n.pem"
    fi
  done < "$tmp/all.txt"

  local pem h
  for pem in "$tmp"/c*.pem; do
    [[ -f "$pem" ]] || continue
    if openssl x509 -noout -issuer < "$pem" 2>/dev/null | grep -qi "MS-Organization-Access"; then
      h=$(cat "${pem%.pem}.hash")
      echo "Removing WorkplaceJoin cert (SHA-1 $h)..."
      sudo -u "$logged_in_user" security delete-certificate -Z "$h" "$kc" >/dev/null 2>&1 \
        && echo "  removed." || echo "  WARN: could not remove."
      found=$((found+1))
    fi
  done

  if (( found > 0 )); then
    echo "Removed $found WorkplaceJoin cert(s); restarting identity services."
    killall identityservicesd cloudconfigurationd cfprefsd 2>/dev/null || true
    sleep 2
  else
    echo "No WorkplaceJoin certs found."
  fi
}

# --- Kick off Intune enrollment (no wipe) -------------------------------------------------------------
start_enrollment() {
  if [[ "$ADE_ENROLLED" == true ]]; then
    echo "Renewing ADE enrollment (in place — no erase)..."
    user_dialog "Your Mac is finishing its move to the new management system. If a Device Enrollment notification appears, please click it and sign in with your work account." "Got it"
    profiles renew -type enrollment 2>/dev/null || echo "WARN: 'profiles renew' returned non-zero."
    echo "ADE re-enrollment requested. On macOS 14/15 the user must accept the Device Enrollment notification."
  else
    echo "Launching Company Portal for user-driven enrollment..."
    install_company_portal
    user_dialog "To finish setup, sign in to the Company Portal app with your work account and approve the management profile in System Settings. Not signing in may cut access to email and corporate resources." "Open Company Portal"
    if [[ -n "$logged_in_user" && "$logged_in_user" != "root" ]]; then
      sudo -u "$logged_in_user" open -a "/Applications/Company Portal.app" 2>/dev/null || open -a "/Applications/Company Portal.app" 2>/dev/null || true
    fi
  fi
}

# ------------------------------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------------------------------
# Pre-stage Company Portal early so it is ready regardless of path.
install_company_portal

remove_jamf_framework
wait_for_mdm_removal
remove_workplacejoin_certs
start_enrollment

echo "$(date '+%Y-%m-%d %H:%M:%S') | ---- Migration step complete. Log: $LOG ----"
exit 0
