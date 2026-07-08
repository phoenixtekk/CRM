# Testing & Validation

Run these validations in order. Each has an **expected pass/fail** so you can prove a migrated
cohort is healthy before promoting the next wave. The scripts referenced are described in **08 —
Deliverables Summary**.

> **Verification note.** Tests V2 and V5 depend on **current Microsoft guidance** for what a
> migrated (AMAPI) device and the correct enrollment/re-enrollment behavior look like. Read the
> current status surface — do not judge pass/fail against an assumed behavior.

---

## V1. Binding is healthy (R1)

**How:** `AMAPIMIG-Config.ps1 -HealthSummary`.
**Pass:** Managed Google Play binding `bindStatus` is connected/bound and `lastAppSyncDateTime` is
recent.
**Fail:** Unbound / stale sync → repair the binding before migrating or interpreting any other
result (a degraded binding fails app delivery downstream).

## V2. Devices manage under AMAPI (the core outcome)

**How:** In the Intune admin center, confirm the migrated cohort reflects the post-migration
(AMAPI) management state Microsoft's **current guidance** describes; corroborate device presence
and check-in with `AMAPIMIG-Get-PostMigrationValidation.ps1 -GroupName "AMAPIMIG – <Model> –
<Stage>"`.
**Pass:** Devices are present, checking in, and shown in the AMAPI-managed state per current
Microsoft guidance.
**Fail:** Devices absent, not checking in, or still shown under the legacy state after the
migration action → **verify against current Microsoft guidance**, then **06 — Troubleshooting**.

## V3. End-user / re-enrollment impact matches the documented statement (R4)

**How:** Compare the **observed** pilot behavior (Phase 3) against the impact statement you
committed for that enrollment model.
**Pass:** The real user experience (no change / re-consent / re-enrollment / work-profile reset)
**matches** what you documented and communicated for that model.
**Fail:** The device did something you did **not** document (e.g. an unexpected re-enrollment or
work-profile reset) → **stop expanding that model**, update the statement, re-communicate, and
re-pilot before any further wave.

## V4. Managed Google Play apps deliver

**How:** `AMAPIMIG-Get-PostMigrationValidation.ps1` reports managed-app install status for the
cohort; confirm on a real device that a targeted managed Google Play app **installs**.
**Pass:** Targeted managed Google Play apps install / remain installed on migrated devices
(install status = installed for the required apps).
**Fail:** Apps fail to install or disappear after migration → confirm V1 (binding) first, then app
assignment against the wave group, then **06 — Troubleshooting**.

## V5. Managed Google account adds / is present

**How:** On a migrated device (per model), confirm the managed Google account is present and app
sign-in works; the validation report surfaces account/ownership signals.
**Pass:** The managed Google account is present and managed Google Play functions on the device.
**Fail — "can't add a Google account":** the classic Android enrollment failure → check network
reachability to Google/Microsoft endpoints (Global Requirements), the binding (V1), and
cross-reference the **Android enrollment troubleshooting (Google account / AMAPI)** solution.

## V6. Devices remain compliant and Conditional Access passes

**How:** `AMAPIMIG-Get-PostMigrationValidation.ps1` reports `complianceState`; confirm a migrated
user can still reach a CA-gated resource.
**Pass:** Migrated devices are **compliant** and CA-gated access works.
**Fail:** Devices non-compliant or users blocked after migration → check whether re-enrollment
reset compliance grace; review the CA/compliance policies noted in R6 before expanding.

## V7. Wave repeatability

**How:** After Wave1 validates, migrate and validate **Wave2** the same way.
**Pass:** Each subsequent wave produces the same PASS results as the pilot — confirming the
process is durable, not a one-off.
**Fail:** Inconsistent results across waves → capture the differing cohort and re-run the estate
assessment + validation; do not promote to Prod until consistent.

---

**Promotion gate:** V1–V6 all **PASS** for a cohort before the next wave migrates; V2, V4, and V5
(**manage under AMAPI, apps deliver, accounts add**) are the non-negotiable trio. Re-run V1–V6
after each wave and after the final Prod cutover.
