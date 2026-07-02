# Device Compliance Policies

> **Version 1.0.0** · Category: Intune · Solution code: DCP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Device Compliance Policies (Microsoft Intune)

**White-label · Intune Solutions**

An unmanaged device with no encryption, a weak PIN, or an outdated OS is a breach waiting to
happen — and most organizations have no automated way to *prove* a device is healthy before it
touches company data. **Device Compliance Policies** in Microsoft Intune define the health rules
every device must meet, continuously evaluate them, and feed that status to Conditional Access so
only compliant devices get in.

This is a complete, **deploy-it-today** package for implementing Device Compliance Policies with
Microsoft Intune, written for an administrator with no prior compliance-policy experience.

## What you get
- A plain-language **Solution Overview** of how compliance evaluation and enforcement work.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for local health discovery, compliance validation, tenant reporting, remediation, and conflict checking.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
A Windows compliance policy enforcing **encryption (BitLocker), Secure Boot, minimum OS, password
rules, antivirus/firewall**, with automated **actions for noncompliance** (notify, then mark
noncompliant) — ready to gate access via Conditional Access.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Provable device health, automated enforcement, and a compliance signal that powers Zero Trust
access control — deployable by a single administrator and validated before fleet rollout.


---


# 1. Solution Overview — Device Compliance Policies

## What Device Compliance Policies are
A device compliance policy is a set of health rules (encryption, OS version, password, antivirus,
threat level, and more) that Microsoft Intune evaluates on each enrolled device. The device is
marked **Compliant** or **Not compliant**, and that status becomes a signal Conditional Access
can use to allow or block access to Microsoft 365 and other apps.

## How it works
1. You define a compliance policy per platform with the rules a device must satisfy.
2. Intune evaluates the device against the rules on enrollment and on a recurring schedule.
3. The result (Compliant / Not compliant) is stored against the device in Entra ID.
4. **Actions for noncompliance** run on a schedule — notify the user, then mark the device noncompliant after a grace period.
5. **Conditional Access** can require "compliant device" to grant access, turning compliance into enforcement.

## What you can require (Windows)
- **Device health** — BitLocker, Secure Boot, Code integrity.
- **Device properties** — minimum/maximum OS version.
- **System security** — password required, length, complexity; encryption of data storage.
- **Microsoft Defender** — antivirus, antispyware, real-time protection, firewall on.
- **Defender for Endpoint** — require a machine risk score at or below a threshold (if integrated).

## Benefits
- **Provable device health** before access is granted.
- **Automated enforcement** — notify and mark noncompliant without manual effort.
- **Zero Trust foundation** — the compliance signal powers Conditional Access.
- **Visibility** — per-device and tenant-wide compliance reporting.

## Limitations (be honest with buyers)
- Compliance only **enforces** access when paired with Conditional Access (a companion solution).
- Threat-level rules require Microsoft Defender for Endpoint integration.
- A grace period means a freshly noncompliant device isn't blocked instantly (by design).
- Devices without any assigned policy are treated per your tenant default — set it deliberately.

## The standard deployment model
> **Set the no-policy default → create the compliance policy → configure actions → assign to a
> pilot group → (optionally) require compliance in Conditional Access.**
repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Device Compliance Policies

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1) for compliance; Microsoft Entra ID P1 for Conditional Access enforcement.
**Why:** Intune evaluates compliance; Entra P1 lets Conditional Access require a compliant device.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (both include Intune + Entra P1).

## 2.2 Device enrollment
**Description:** Targeted devices are enrolled in Intune.
**Why:** Compliance is only evaluated on enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Device health prerequisites
**Description:** TPM + UEFI Secure Boot for the health rules (BitLocker, Secure Boot).
**Why:** Health attestation rules require TPM/Secure Boot capable hardware.
**Verify:** `Get-Tpm`; `Confirm-SecureBootUEFI`; or run **`DCP-Discovery.ps1`**.
**Implement:** Enable TPM and Secure Boot in UEFI; this solution can be paired with the BitLocker solution to enforce encryption.

## 2.4 Microsoft Defender (for AV/firewall rules)
**Description:** Microsoft Defender Antivirus + Windows Firewall active (or a managed AV).
**Why:** Compliance can require real-time protection and firewall on.
**Verify:** `Get-MpComputerStatus`; `Get-NetFirewallProfile`.
**Implement:** Ensure Defender AV is enabled (default) and firewall profiles are on.

## 2.5 Defender for Endpoint (optional — threat level rules)
**Description:** Defender for Endpoint connector in Intune.
**Why:** Required only if you enforce a machine risk score.
**Verify:** Intune → **Endpoint security → Microsoft Defender for Endpoint** connection status = Active.
**Implement:** Connect Defender for Endpoint (see the Defender integration solution).

## 2.6 Conditional Access (for enforcement)
**Description:** A Conditional Access policy requiring a compliant device.
**Why:** Compliance reports status; Conditional Access turns it into access enforcement.
**Verify:** Entra → **Protection → Conditional Access**.
**Implement:** Pair with the Conditional Access Integration solution.

---
## Checklist
- [ ] Intune + Entra P1 licensing assigned
- [ ] Devices enrolled
- [ ] TPM + Secure Boot for health rules — `DCP-Discovery.ps1`
- [ ] Defender AV + firewall active
- [ ] (Optional) Defender for Endpoint connected for threat-level rules
- [ ] Pilot Entra group created
- [ ] Tenant "no compliance policy" default decided


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Device Compliance Policies

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A Windows compliance policy with health + password + Defender rules, actions for
> noncompliance, assigned to a pilot group — ready for Conditional Access enforcement.

## Step 1 — Set the no-policy default
1. Go to **Devices → Compliance → Compliance settings**.
2. Set **Mark devices with no compliance policy assigned as** to **Not compliant**. **Save**.

## Step 2 — Create the compliance policy
1. Go to **Devices → Compliance → Create policy**.
2. **Platform:** Windows 10 and later. Click **Create**.
3. **Name:** `Compliance - Windows - Pilot`. Click **Next**.

## Step 3 — Configure the rules
On **Compliance settings**, set:
1. **Device Health** → Require BitLocker = **Require**; Require Secure Boot = **Require**; Code integrity = **Require**.
2. **Device Properties** → Minimum OS version = your baseline (e.g. `10.0.19044`).
3. **System Security** → Require a password = **Require**; Minimum password length = **8**; Password type = **Alphanumeric** (or Device default); Encryption of data storage = **Require**.
4. **Microsoft Defender Antivirus** = **Require**; **Real-time protection** = **Require**; **Firewall** = **Require**.
5. (Optional) **Defender for Endpoint** → Require the device to be at or under machine risk score = **Medium**.
6. Click **Next**.

## Step 4 — Configure actions for noncompliance
1. On **Actions for noncompliance**, keep **Mark device noncompliant** and set schedule to **1 day** (grace period).
2. Click **Add** → **Send email to end user** → choose/create a notification → schedule **immediately**.
3. (Optional) Add **Remotely lock the noncompliant device** for higher-risk scopes. Click **Next**.

## Step 5 — Assign to the pilot group
1. On **Assignments → Included groups → Add groups →** select `Compliance-Pilot`. **Next**.

## Step 6 — Review and create
1. On **Review + create**, confirm the rules and actions. Click **Create**.

## Step 7 — (Recommended) require compliance in Conditional Access
1. Pair with the **Conditional Access Integration** solution: create a policy requiring **Require device to be marked as compliant** for the same users. Start in **Report-only** mode.

## Step 8 — Validate the pilot
1. On a pilot device, run **`DCP-Validation.ps1`** → confirms the device reports Compliant.
2. Run **`DCP-TenantReport.ps1`** → confirms compliance status across the pilot group.
3. Run **`DCP-ConflictCheck.ps1`** → flags conflicting policies. Complete the **Testing Guide**.

## Step 9 — Expand to production
1. Add a production group to the policy **Assignments**; roll out in waves.
2. Move the Conditional Access policy from **Report-only** to **On** once compliance coverage is confirmed.
3. Re-validate each wave with **`DCP-Validation.ps1`** / **`DCP-TenantReport.ps1`**.

---
### Order of operations
`No-policy default → Create policy → Rules → Actions → Assign → (CA require compliant) → Validate → Expand`


---


# 5. Testing Guide — Device Compliance Policies

Run after the pilot policy applies (Implementation Step 8) and after each production wave.

## Test 1 — Policy applied
**Do:** Intune → **Devices → Compliance →** `Compliance - Windows - Pilot` **→ Device status**.
**Expected:** Pilot devices listed; evaluation completed (no **Error**).

## Test 2 — Compliant device reports Compliant
**Do:** On a healthy pilot device, run `DCP-Validation.ps1`; check Intune → device → **Compliance**.
**Expected:** Device is **Compliant**; all required rules pass.

## Test 3 — Noncompliant device is caught
**Do:** On a test device, disable the firewall (or use a non-encrypted test VM) and force a sync.
**Expected:** The device flips to **Not compliant** for the failing rule after evaluation.

## Test 4 — Actions fire
**Do:** Leave a device noncompliant past the grace period.
**Expected:** The user receives the noncompliance email; the device is marked **Not compliant** on schedule.

## Test 5 — No policy conflicts
**Do:** Run `DCP-ConflictCheck.ps1`, and review Intune → device → **Device compliance** for conflicts.
**Expected:** No conflicting compliance settings from multiple policies.

## Test 6 — Conditional Access sees the signal (if configured)
**Do:** With a Report-only CA policy requiring compliant device, review **Entra → Sign-in logs → Conditional Access**.
**Expected:** Compliant devices satisfy the control; noncompliant devices would be blocked (report-only shows "would block").

## Test 7 — Tenant report
**Do:** Run **`DCP-TenantReport.ps1`**.
**Expected:** A compliance breakdown (Compliant / Not compliant / In grace) for the pilot group.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 (and 6 if CA configured) pass for the pilot group |
| **Wave pass** | Tests 1–3, 7 pass before the next wave |


---


# 6. Troubleshooting Guide — Device Compliance Policies

Use **`DCP-Validation.ps1`** / **`DCP-Discovery.ps1`** to confirm device state and
**`DCP-Remediation.ps1`** for safe fixes.

## A. Device shows Not compliant unexpectedly
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant device marked Not compliant | A required rule isn't met (firewall off, AV stale, OS below min) | Run `DCP-Discovery.ps1` to find the failing facet; remediate; sync |
| "Compliant" but no policy | No policy assigned + tenant default = Not compliant | Assign the policy to the device's group |
| Stuck "In grace period" | Grace period not elapsed | Wait for the scheduled action, or shorten the grace period |

## B. Evaluation / sync issues
| Symptom | Cause | Remediation |
|---|---|---|
| Status not updating | Device hasn't checked in | Run `DCP-Remediation.ps1` (forces MDM sync); confirm device online |
| BitLocker/Secure Boot "not evaluated" | Health attestation not reporting | Ensure TPM + Secure Boot enabled; reboot; allow attestation to report |

## C. Policy conflicts
- Multiple compliance policies with conflicting settings → Intune uses the most restrictive, but mixed assignments cause confusion. Run `DCP-ConflictCheck.ps1`; consolidate to one authoritative policy per scope.
- A legacy GPO/another MDM setting the same security control can fight Intune — remove the duplicate.

## D. Conditional Access interplay
- Users blocked unexpectedly → a CA policy requires compliant device but the device is Not compliant. Verify with **Entra → Sign-in logs**; fix the compliance failure or scope the CA policy.
- Always pilot CA in **Report-only** first to see impact before enforcing.

## E. Defender for Endpoint threat-level rule
- Threat-level rule always failing → the Defender for Endpoint connector isn't Active, or the device isn't onboarded. Confirm the connector and onboarding (see the Defender integration solution).

## F. Diagnostics quick reference
```powershell
Get-MpComputerStatus                 # Defender AV / real-time protection
Get-NetFirewallProfile               # firewall state
manage-bde -status                   # BitLocker
Confirm-SecureBootUEFI               # Secure Boot
```
Intune: **Devices → device → Device compliance** shows per-setting pass/fail.

## G. When to escalate
If `DCP-Discovery.ps1` shows all facets healthy but the device still reports Not compliant after a
sync and attestation cycle, collect the compliance evaluation details and open a Microsoft support case.


---


# 7. Best Practices — Device Compliance Policies

- **Always pilot first.** Apply to a small group and confirm healthy devices report Compliant before fleet rollout.
- **Set the no-policy default to Not compliant.** Otherwise unmanaged devices are treated as compliant — the opposite of what you want.
- **Use a grace period.** Mark noncompliant after ~1 day so a transient failure doesn't instantly block a user; notify the user immediately.
- **One authoritative policy per scope.** Avoid overlapping compliance policies with conflicting settings; consolidate.
- **Pair with Conditional Access in Report-only first.** See who *would* be blocked before enforcing, to avoid lockouts.
- **Match rules to reality.** Don't require BitLocker/Secure Boot on hardware that can't support it; segment by capability.
- **Notify users.** A clear email on noncompliance ("your device needs an update / encryption on") drives self-remediation.
- **Layer with the encryption/Defender solutions.** Compliance *checks* health; BitLocker and Defender solutions *deliver* it.
- **Review the tenant report regularly.** Track compliance percentage and chase persistent failures with `DCP-TenantReport.ps1`.
- **Document the baseline.** Record the required rules and rationale for audits and repeatability.


---


# 8. Deliverables Summary — Device Compliance Policies

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What compliance policies are, how evaluation/enforcement work, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DCP-Discovery.ps1` | Local health facts: BitLocker, Secure Boot, Defender AV, firewall, OS version |
| `DCP-Validation.ps1` | Confirms the device reports Compliant and which rules pass/fail |
| `DCP-TenantReport.ps1` | Tenant-wide compliance status breakdown (Microsoft Graph) |
| `DCP-Remediation.ps1` | Safe remediation; forces sync and fixes common failures (firewall/AV) |
| `DCP-ConflictCheck.ps1` | Flags conflicting/overlapping compliance policy assignments (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Provable device health and automated enforcement that powers Zero Trust Conditional Access.
