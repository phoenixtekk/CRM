# 2. Requirements Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (Entra tenant, Intune subscription, admin roles,
network access, a pilot group) are in `global-requirements-intune-solutions.md` — confirm those first.

> Note: the category global requirements reference a *Windows* baseline (G6). For this solution that
> requirement is replaced by the **supported macOS baseline** in 2.4 below.

## 2.1 Microsoft Entra ID P1 licensing
**Description:** Microsoft Entra ID P1 (included with Microsoft 365 E3/E5 and Business Premium).
**Why:** Conditional Access is a P1 feature; without it you cannot create the CA policy that enforces
the compliance signal.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** — a plan that includes Entra ID P1 is
assigned to the pilot users.
**Implement:** Assign Microsoft 365 E3/E5 or Business Premium to the targeted users.

## 2.2 Macs enrolled in Intune and Entra-registered
**Description:** The target Macs are enrolled in Microsoft Intune and appear as devices in Entra.
**Why:** A compliance policy only reaches enrolled Macs, and the **Require compliant device** control
only works if the Mac is registered in Entra so its compliance state can be read at sign-in.
**Verify:** Intune → **Devices → All devices** — the Mac appears with OS **macOS**; run
**`MACCA-Discovery.ps1`** to list enrolled Macs and their current compliance state.
**Implement:** Enroll Macs via **Automated Device Enrollment (ADE)** or the Company Portal /
user enrollment, so they become Intune-managed and Entra-registered.

## 2.3 Microsoft Defender for Endpoint on macOS (for the machine-risk signal)
**Description:** Defender for Endpoint deployed and onboarded on the Macs, with the **Intune ↔
Defender for Endpoint connector** enabled.
**Why:** The **machine-risk** compliance signal reads each Mac's Defender risk score; without the
connector, that signal cannot be evaluated and should be omitted.
**Verify:** Intune → **Endpoint security → Microsoft Defender for Endpoint** — the macOS connection
status is **Enabled** and *Connect macOS devices … to Microsoft Defender for Endpoint* is **On**.
**Implement:** Deploy Defender for Endpoint on macOS (companion **Defender for Endpoint (macOS)
onboarding** solution), then turn on the connector. *Flag: if you are not using Defender on Macs yet,
build the policy with the first three signals and add the machine-risk rule later.*

## 2.4 Supported macOS baseline
**Description:** Macs on a currently supported macOS version (a recent major release with security
updates).
**Why:** The **Minimum OS version** compliance rule assumes the fleet can meet a supported floor; set
the floor to a version your fleet can actually reach so you do not block healthy Macs.
**Verify:** On a Mac,  → **About This Mac**; or Intune → device → **Hardware → Operating system
version**. Run **`MACCA-Discovery.ps1`** to see the OS-version spread across enrolled Macs.
**Implement:** Update Macs to a supported release (e.g. via an Intune macOS **update policy** or the
built-in Software Update) before setting a high minimum-version floor.

## 2.5 FileVault posture (encryption signal)
**Description:** Macs can have FileVault enabled (either already on, or enforced via an Intune
disk-encryption policy).
**Why:** The encryption compliance rule marks a Mac non-compliant if FileVault is off; if you have no
way to turn it on, users will be blocked with no path to remediate.
**Verify:** Intune → **Endpoint security → Disk encryption** — a FileVault policy exists/targets the
Macs; or **`MACCA-Discovery.ps1`** reports encryption state.
**Implement:** Create an Intune **Disk encryption (FileVault)** policy so Macs can become — and stay —
encrypted, then apply the compliance rule.

## 2.6 Pilot Entra security group
**Description:** A Microsoft Entra security group for the pilot Macs/users, named
`macOS-ZeroTrust-Pilot`.
**Why:** Both the compliance policy and the CA policy are targeted at the pilot first, never the whole
fleet.
**Verify:** Entra → **Groups** — `macOS-ZeroTrust-Pilot` exists; or use
**`MACCA-Set-ScopeTargeting.ps1`** (default `-WhatIf`) to preview membership.
**Implement:** Entra → **Groups → New group → Security** → `macOS-ZeroTrust-Pilot` → add pilot
members. **`MACCA-Set-ScopeTargeting.ps1`** can build this membership from your Mac inventory.

## 2.7 Sign-in log / reporting access
**Description:** The operator can read Entra sign-in logs and Conditional Access results.
**Why:** Report-only impact and allow/block decisions are reviewed in the sign-in logs before and
after enforcement.
**Verify:** Entra → **Monitoring → Sign-in logs** loads and shows a **Report-only** / **Conditional
Access** tab on a sign-in.
**Implement:** Grant the operator **Security Reader** or **Reports Reader** in Entra.

## 2.8 Break-glass / exclusion accounts (lockout safety)
**Description:** Emergency-access accounts (and any needed service exceptions) that are **excluded**
from the CA policy.
**Why:** A device-based CA policy *can* block people; break-glass accounts guarantee you can always
get back in.
**Verify:** Entra → **Users** — dedicated emergency accounts exist and are excluded from CA policies.
**Implement:** Follow the **Conditional Access Integration** solution's break-glass guidance (two
cloud-only Global Admins with offline passwords), and exclude them from
`CA - macOS - Require Compliant Device`.

---
## Checklist
- [ ] Entra ID P1 licensing assigned to pilot users
- [ ] Target Macs enrolled in Intune and Entra-registered — `MACCA-Discovery.ps1`
- [ ] Defender for Endpoint (macOS) + connector enabled *(or plan to add the machine-risk rule later)*
- [ ] Supported macOS baseline achievable across the pilot Macs
- [ ] FileVault can be enabled (disk-encryption policy in place)
- [ ] `macOS-ZeroTrust-Pilot` security group created
- [ ] Sign-in log / Report-only access for the operator
- [ ] Break-glass / exclusion accounts identified and excluded from the CA policy
