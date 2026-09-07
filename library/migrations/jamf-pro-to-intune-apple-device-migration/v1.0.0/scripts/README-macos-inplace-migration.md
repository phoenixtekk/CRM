# macOS in-place Jamf → Intune migration (two-part, secret-free on endpoints)

These two scripts replace the single all-in-one migration script pattern that embeds Jamf API
credentials in a file deployed to every Mac. Splitting the work fixes both the security exposure and
the failure mode where devices with an already-expired Jamf profile abort mid-migration.

## The parts

1. **`JAMFMIG-Unmanage-Batch.sh`** — run **once, from a trusted admin Mac**. Reads Jamf API
   credentials from **environment variables only** (never hardcoded, never written to disk, never
   echoed) and sends the *remove-MDM-profile* command to a batch of serials. Devices that are offline
   or already unmanaged are reported and skipped — they're finished by the on-device script.

2. **`JAMFMIG-Migrate-Device.sh`** — deploy to the endpoints (Jamf policy or run with `sudo`).
   **Contains no credentials of any kind.** Removes the Jamf framework locally (best-effort), clears
   Entra WorkplaceJoin certs, and starts Intune enrollment **without erasing the Mac or the user's
   data/profile** — ADE devices re-enroll in place via `profiles renew`; user-approved devices enroll
   via Company Portal.

## What changed vs. the common single-script approach
- **No secret on endpoints.** The Jamf API client secret stays on one admin workstation.
- **Expired/offline-safe.** The on-device step never aborts because the server couldn't push an
  unmanage command; the local `jamf removeFramework` runs regardless, and the MDM-profile wait is
  bounded (180s) and skipped when no profile is present.
- **No external UI dependency** on-device (uses `osascript`, not a downloaded dialog binary).

## Run order
```bash
# 1) Admin Mac — credentials via environment, then batch-unmanage
export JAMF_PRO_URL="https://your.jamf.server"
export JAMF_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
read -rs JAMF_CLIENT_SECRET; export JAMF_CLIENT_SECRET   # typed, not pasted into a file
./JAMFMIG-Unmanage-Batch.sh --dry-run serials.txt        # verify resolution first
./JAMFMIG-Unmanage-Batch.sh serials.txt

# 2) Endpoints — deploy JAMFMIG-Migrate-Device.sh via Jamf policy (runs as root)
```

## Prerequisites
- **ADE devices:** re-assign the device to the **Intune** MDM server in Apple Business Manager with an
  Intune enrollment profile assigned **before** the on-device step. Verify with
  `JAMFMIG-Get-ABMAssignments`. Without it, `profiles renew` has nothing new to pull.
- **Jamf API role** (10.49+ API Roles & Clients): `Read Computers` + `Send Computer Remove MDM Profile
  Command`.
- **macOS 14/15:** ADE re-enrollment surfaces a *Device Enrollment* notification the user must accept.

## Security
If a Jamf API client secret was ever embedded in a script that reached an endpoint, **rotate that API
client immediately** (Jamf Pro → Settings → API Roles and Clients). These scripts never place a secret
on a managed device.

Provided AS IS, without warranty. Pilot on a small wave before fleet use.
