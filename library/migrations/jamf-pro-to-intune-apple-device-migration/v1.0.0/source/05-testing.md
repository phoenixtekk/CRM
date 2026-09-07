# Testing & Validation

## After Phase 1 (assess)
1. `JAMFMIG-Export-JamfInventory.ps1` produced the computer, mobile-device, PreStage, and profile CSVs,
   and the IntuneEquivalent column is filled in.
2. `JAMFMIG-Get-IntuneReadiness.ps1` shows a valid **Apple MDM push cert**, at least one **ADE token**,
   and a connected **VPP token**, none near expiry.
3. `JAMFMIG-Get-ABMAssignments.ps1` shows which serials Intune's ADE token already knows about.

## After Phase 2 (build the target)
1. ADE profiles exist: `ADE – macOS – Corp`, `ADE – iPadOS – Shared`, `ADE – iOS – Users`.
2. Configuration and compliance policies exist per platform and are assigned to the platform groups.
3. macOS: `Config – macOS – FileVault` (escrow to Intune) and `Config – macOS – SSO` exist; VPP + PKG
   apps are assigned. iOS/iPadOS: SCEP/PKCS profiles and VPP apps are assigned.

## After Phase 3 (pilot wave) — the proof, per platform
1. **Supervised (wipe-and-enroll):** after ABM re-assign + erase, Setup Assistant shows **Remote
   Management** and the device **auto-enrolls into Intune**; it appears managed in **Intune → Devices**.
2. **BYOD (unenroll/re-enroll):** the device left Jamf and re-enrolled into Intune with no wipe.
3. **macOS:** FileVault recovery key is **escrowed to Intune**; SSO works; Defender re-onboarded.
4. **iOS/iPadOS:** VPP apps installed; Wi-Fi, per-app VPN, and certificates present; restrictions apply.
5. `JAMFMIG-Validate-Migration.ps1` (with the wave serials) shows the pilot devices **enrolled and
   compliant** by platform; `JAMFMIG-Track-Waves.ps1` shows them **Migrated**.
6. The pilot devices **no longer check in to Jamf**.

## After each production wave (Phase 4)
1. `JAMFMIG-Validate-Migration.ps1` shows the wave enrolled and compliant.
2. VPP licenses were **revoked in Jamf** and re-assigned in Intune (no license exhaustion).
3. `JAMFMIG-Track-Waves.ps1` shows the wave **Migrated** and the remaining **Pending** count dropping.

## Before Phase 5 (decommission)
1. `JAMFMIG-Track-Waves.ps1` reports **Pending: 0** — every Jamf device is enrolled in Intune.
2. All waves validated; the final inventory + validation reports are retained.

## Rollback validation
- **BYOD:** device unenrolled from Intune and back in Jamf.
- **Supervised:** ABM re-assigned to Jamf and the device erased re-enrolls into Jamf.
