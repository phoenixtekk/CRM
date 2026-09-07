# Troubleshooting

## A supervised device won't move to Intune after re-assigning in ABM
- **Expected until it's erased.** Re-assigning the MDM server in ABM does not migrate a *supervised*
  device in place — it only changes which MDM the device will use at the **next Setup Assistant**.
  Erase the device (Erase All Content and Settings); on reboot it enrolls into Intune.

## Setup Assistant does not show "Remote Management" after the wipe
- The device's serial is **not assigned to the Intune ADE token**, or its ADE **profile is not
  assigned**. Run `JAMFMIG-Get-ABMAssignments.ps1` — if the serial isn't listed, re-assign it to the
  Intune MDM server in ABM and sync the token in Intune. Then confirm the ADE profile
  (`ADE – macOS – Corp` / `ADE – iPadOS – Shared` / `ADE – iOS – Users`) is assigned to the device's
  group. Erase again.

## The device still shows a Jamf management profile / still checks in to Jamf
- For **BYOD**, the Jamf MDM profile was not removed — remove it (Settings → General → VPN & Device
  Management, or unenroll via Jamf) before re-enrolling into Intune. For **supervised**, the erase was
  not completed; a re-assign alone leaves Jamf in control until the wipe.

## VPP apps won't install in Intune — "no licenses available"
- The licenses are **still assigned in Jamf**. Revoke them in Jamf (or unassign the app) so Intune can
  claim them; there is one license per device per app. Confirm the **VPP token** is connected in Intune
  (`JAMFMIG-Get-IntuneReadiness.ps1`).

## FileVault key isn't in Intune after migrating a Mac
- The Jamf-escrowed key does **not** transfer. Deploy the Intune FileVault policy
  (`Config – macOS – FileVault`) so Intune **escrows/rotates** the key, and confirm it is retrievable in
  Intune → Devices → the Mac → Recovery keys. Until then, treat the Mac as not fully migrated.

## Duplicate device records in Intune
- A device that was enrolled, wiped, and re-enrolled can leave a stale record. Remove the stale/duplicate
  managed-device entry in Intune once the live record is confirmed compliant.

## Certificates missing on iOS/iPadOS after migration
- The Jamf-issued certs did not carry over. Ensure the **SCEP/PKCS** certificate profiles are assigned
  to the platform group and the **certificate connectors** are healthy; re-sync the device.

## The Apple push certificate expired mid-migration
- The **entire** Apple fleet unenrolls. Renew the push cert with the **same Apple ID** immediately in
  Intune → Devices → Enrollment → Apple → Apple MDM push certificate. Do not create a new one with a
  different Apple ID — that forces re-enrollment of everything.

## Rollback of a supervised device
- There is no in-place rollback for supervised devices: re-assign the serial to the **Jamf** MDM server
  in ABM and **erase** the device to re-enroll into Jamf. This is why each wave is validated before the
  next begins.

## GCC High: a step or endpoint looks different
- Use the `*.microsoft.us` portals (`intune.microsoft.us` / `endpoint.microsoft.us`). Confirm your
  tenant's **VPP/ABM token** and **account-driven user enrollment** availability; the migration steps
  are otherwise identical.
