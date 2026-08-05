# 5. Testing & Validation — Microsoft Intune First-Time Setup for Windows

Do not declare success until **both** enrollment paths pass. The exit criterion for this solution is:
**a user-enrolled Windows PC AND an Autopilot-provisioned Windows PC are both Microsoft Entra joined,
Intune-enrolled, managed, and reporting compliant.**

Run the included scripts to gather evidence, and record each gate PASS/FAIL.

---

## Test 1 — User-driven enrolled device lands managed & compliant
**Setup:** the PC from implementation Step 5 (`Access work or school → Join this device to Microsoft
Entra ID`).

| # | Check | How | PASS criteria |
|---|---|---|---|
| 1.1 | Device is Entra joined | On device: `dsregcmd /status` | `AzureAdJoined : YES` |
| 1.2 | Device is Intune-enrolled | On device: `dsregcmd /status` shows an `MdmUrl`; or Intune → **Devices → All devices** lists it | Device present, **Managed by: Intune (MDM)** |
| 1.3 | Enrollment method is correct | Intune → device → **Overview** / run `INTBASE-Report-Enrollment.ps1` | Method shows user-driven (Entra join), not Autopilot |
| 1.4 | Baseline compliance applied | Intune → device → **Device compliance** | `INTBASE - Compliance - Windows Pilot` evaluated |
| 1.5 | Device reports compliant | Intune → device → **Overview → Compliance** | **Compliant** (allow one check-in cycle) |

**Gate 1 — PASS only if 1.1–1.5 all pass.**

## Test 2 — Autopilot device provisions and lands managed & compliant
**Setup:** the registered device from Steps 7–11, factory-reset and taken through OOBE.

| # | Check | How | PASS criteria |
|---|---|---|---|
| 2.1 | Device is registered for Autopilot | Intune → **Devices → Enrollment → Windows → Devices** | Serial present, profile **`INTBASE - Autopilot - Pilot`** assigned |
| 2.2 | Device is in the assigned group | Entra → **Groups → `INTBASE - Autopilot Devices` → Members** | Device is a member |
| 2.3 | OOBE applied the profile | At OOBE | Org branding + Autopilot flow shown; user signs in once |
| 2.4 | ESP completed | On device during setup | `INTBASE - ESP - Pilot` reaches completion, device usable |
| 2.5 | Device is Entra joined + Intune-enrolled | `dsregcmd /status`; Intune → **All devices** | `AzureAdJoined : YES`, **Managed by: Intune (MDM)** |
| 2.6 | Enrollment method is correct | `INTBASE-Report-Enrollment.ps1` | Method shows **Windows Autopilot** |
| 2.7 | Device reports compliant | Intune → device → **Overview → Compliance** | **Compliant** |

**Gate 2 — PASS only if 2.1–2.7 all pass.**

## Test 3 — Automated validation (scripts)
1. Run **`INTBASE-Preflight.ps1`** — confirms licensing, roles, MDM authority, auto-enrollment scope, and
   that the Intune Provisioning Client owns `INTBASE - Autopilot Devices`. Expect all **PASS**.
2. Run **`INTBASE-Validate-Enrollment.ps1 -DeviceName <name>`** for each pilot PC — confirms Entra join,
   Intune enrollment, and compliant state. Expect **PASS** for both devices.
3. Run **`INTBASE-Report-Enrollment.ps1`** — the two pilot devices appear, one **User-driven** and one
   **Autopilot**.

**Gate 3 — PASS only if Preflight is all-PASS and both devices validate.**

---

## Overall exit criteria
- **Gate 1 PASS** (user-driven device managed & compliant) **and**
- **Gate 2 PASS** (Autopilot device managed & compliant) **and**
- **Gate 3 PASS** (scripts confirm both).

Only when all three gates pass is the first-time Windows setup complete. Then expand per implementation
Step 13.
