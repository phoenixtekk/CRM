# 2. Requirements Guide — Solution Optimization: Endpoint Security with Microsoft Intune

Verify **every** requirement before tuning. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to optimizing an existing Intune endpoint-security deployment**. Because this is a **tuning** engagement, the defining prerequisite is that Intune endpoint security is **already deployed and applying** — not a green field. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 An existing, working Intune endpoint-security deployment
**Description:** Intune already manages devices with **endpoint-security policies** (baselines, antivirus, disk encryption, firewall, EDR/ASR) and **compliance policies** applied — not a new deployment.
**Why:** This solution *tunes* an existing estate; there must be enrolled devices, applied policies, and compliance results to optimize.
**Verify:** `intune.microsoft.com` → **Endpoint security** shows policies with device-assignment results, and **Devices → Compliance** shows evaluated devices; run `SOPEIS-Discovery.ps1`.
**Implement-if-missing:** If endpoint security is not deployed through Intune, stop — deploy it first, then return to optimize.

## 2.2 A defined pilot device ring
**Description:** A named Entra group of representative pilot devices to tune first: **`Intune Optimize – Pilot Ring – Pilot`**.
**Why:** Baseline migration, conflict consolidation, and compliance/CA changes are validated on a ring before estate-wide rollout (per `global-requirements-defender.md` G6).
**Verify:** The Entra group exists and contains a representative sample (one of each OS/build/role); `SOPEIS-Discovery.ps1` lists groups and their device counts.
**Implement-if-missing:** Create the pilot group in **Entra → Groups** (dynamic or assigned) before applying any change.

## 2.3 Current security-baseline version awareness
**Description:** Knowledge of which **security-baseline version(s)** are currently applied versus the latest version Microsoft publishes.
**Why:** Devices on an older baseline version drift from current guidance; migration is a core tuning lever, and the version must be known to plan it.
**Verify:** `intune.microsoft.com` → **Endpoint security → Security baselines**; note each baseline's version and whether a newer one is available. *Baseline versions change — verify current.*
**Implement-if-missing:** Record the applied versions and the latest available (Implementation Step 2 migrates them).

## 2.4 Rights to change endpoint-security and compliance policy
**Description:** **Endpoint Security Manager** (and **Intune Administrator** where full policy authoring/assignment is needed), plus **Intune Read Only Operator** / **Security Reader** for reporting accounts. Reviewing Conditional Access impact needs at least **Security Reader** in Entra.
**Why:** Editing baselines, resolving conflicts, tuning compliance, and changing assignments require write access; reporting and CA review only need read.
**Verify:** Intune → **Tenant admin → Roles**; Entra → **Roles and administrators**; `SOPEIS-Discovery.ps1` reports the running account's effective scopes.
**Implement-if-missing:** Assign the minimum roles at the narrowest scope; prefer PIM eligible activation over standing access.

## 2.5 A before-state baseline (conflicts, compliance, coverage)
**Description:** A saved snapshot of current **conflict/error counts**, **non-compliant proportion**, and **coverage** (devices receiving each policy type) — the "before" for before/after measurement.
**Why:** Optimization is only credible if the improvement is **measured**; the baseline is the reference every later report compares against.
**Verify:** A baseline file exists; run `SOPEIS-Report.ps1 -SaveBaseline`.
**Implement-if-missing:** Run `SOPEIS-Report.ps1 -SaveBaseline` before making any change (Implementation Step 1).

## 2.6 Conditional Access impact understood before enforcing
**Description:** A read of the **Conditional Access** policies that grant/block on device compliance, so tightening compliance doesn't unexpectedly lock users out.
**Why:** Compliance state feeds Conditional Access; a stricter compliance policy can turn a benign device non-compliant and block sign-in. The blast radius must be understood first.
**Verify:** `entra.microsoft.com` → **Conditional Access**; identify policies with a **Require device to be marked compliant** grant. Use **Report-only** / the What-If tool. *CA changes are the identity team's decision.*
**Implement-if-missing:** Put new/stricter CA grants in **Report-only** first; model impact before enforcing (Implementation Step 4).

## 2.7 Change control, pilot scope, and rollback
**Description:** An approved change record, the named pilot ring, and a documented rollback before migrating baselines, consolidating conflicts, or tightening compliance.
**Why:** These changes affect device configuration and user access; the pilot-first, report-only-first approach and a written back-out are the safety net.
**Verify:** An approved change record, the pilot scope, and a written rollback (revert to the prior baseline/policy, restore prior assignment) exist.
**Implement-if-missing:** Capture the baseline (2.5), define the pilot ring (2.2), and write the rollback before Step 2.

## 2.8 Response/enforcement governance
**Description:** Confirmation of the agreed posture for **compliance actions** (mark non-compliant immediately vs after a grace period; notify vs restrict) and that disruptive enforcement stays staged.
**Why:** Compliance actions can restrict access; the organization must decide the guardrails and grace periods (per `global-requirements-defender.md` G8).
**Verify:** A documented compliance-action posture exists; new stricter actions are staged with a grace period first.
**Implement-if-missing:** Define the compliance-action posture and grace periods with the security/identity team. *Enforcement decisions are theirs; this guide covers the technical configuration.*

---
## Checklist
- [ ] Existing, applying Intune endpoint-security + compliance deployment — `SOPEIS-Discovery.ps1`
- [ ] Pilot device ring `Intune Optimize – Pilot Ring – Pilot` defined
- [ ] Current vs latest security-baseline versions known
- [ ] Endpoint Security Manager (+ Intune Admin) and read-only/Security Reader roles
- [ ] Before-state baseline saved — `SOPEIS-Report.ps1 -SaveBaseline`
- [ ] Conditional Access compliance impact reviewed (report-only first)
- [ ] Change window, pilot scope, and rollback documented
- [ ] Compliance-action posture / grace periods agreed
