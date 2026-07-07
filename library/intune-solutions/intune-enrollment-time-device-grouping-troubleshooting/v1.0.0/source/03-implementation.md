# Implementation

Follow these ordered steps to stand up Enrollment-Time Device Grouping correctly on **both**
platforms, using the reference-design artifact names. Pilot first, validate against explicit gates,
then expand. A rollback is documented at the end of each phase.

> **Naming convention** (`<Purpose> – <Scope> – <Stage>`), reused in Testing, Troubleshooting, and
> the scripts:
> - Windows target group: **`Autopilot – Devices – Pilot`** → **`Autopilot – Devices – Prod`**
> - Apple target group: **`iOS – Shared Devices – Pilot`** → **`iOS – Shared Devices – Prod`**
> - Windows enrollment policy: **`Autopilot DevicePrep – Shared – Prod`**
> - Apple enrollment profile: **`ADE Enrollment – Shared iOS – Prod`**
> - Apple enrollment token: **`ADE Token – Corporate – Prod`**

---

## Phase 0 — Assess (before you change anything)

**Step 0.1 — Baseline the group (if one already exists).** Run
`ETDG-Assess-GroupReadiness.ps1 -GroupName "Autopilot – Devices – Pilot"`. It reports Type,
MembershipType, `onPremisesSyncEnabled`, `mailEnabled`, `isAssignableToRole`, member count, and
whether AppId `f1346770-5b25-470b-88bd-d5744ab7952c` is already an Owner — pass/fail per prerequisite
(R1–R7).

**Step 0.2 — Confirm the service principal exists and check RBAC scope.** Run
`ETDG-Test-EnrollmentGroupPrereqs.ps1 -GroupName "Autopilot – Devices – Pilot"`. It validates R1–R9,
confirms the Intune Provisioning Client SP is present in the tenant (by AppId), and lists the
operating admin's Intune role assignments / scope groups.

**Gate 0 (pass/fail):** Proceed only when you know exactly which prerequisites are unmet. If the SP
is **absent**, resolve that first (Step B.0). **Do not** open a policy Save until the group is to
spec and owned.

---

## Phase A — Create the target group to spec

Do this for the **Pilot** group first (`Autopilot – Devices – Pilot` and/or
`iOS – Shared Devices – Pilot`), then repeat for **Prod** in Phase E.

**Step A.1 — New Security, Assigned, cloud-only group.**
Entra admin center → **Groups → New group**:
- **Group type:** Security
- **Group name:** `Autopilot – Devices – Pilot` (or `iOS – Shared Devices – Pilot`)
- **Membership type:** **Assigned** (do **not** choose Dynamic Device or Dynamic User) — **R2**
- Leave **Microsoft Entra roles can be assigned to the group = No** — **R5** (cannot be changed
  later)
- Do **not** mail-enable it — **R4**
- Add **no members** yet — **R6**

**Step A.2 — Confirm it is cloud-only.** After creation, open the group → confirm **Source =
Cloud** (not "Windows Server AD") — **R3**. If it shows as directory-synced, you selected a synced
group; create a genuinely cloud-only one.

**Step A.3 — Confirm the admin can manage it.** Verify you can open **Owners** and **Members**
without an access error — **R8**.

**Pass/fail (Gate A):** `ETDG-Assess-GroupReadiness.ps1 -GroupName "Autopilot – Devices – Pilot"`
reports **all of R1–R6 = PASS**. If any fails, fix per **02 — Requirements** before continuing.

**Rollback A:** Delete the newly created group (Entra → Groups → `<group>` → Delete). Nothing is
wired to a policy yet, so deletion has no enrollment impact.

---

## Phase B — Add the Intune Provisioning Client as **Owner**

**Step B.0 — Provision the service principal if it is missing.** If Step 0.2 reported the SP
absent: sign in to **`https://intune.microsoft.com` once as a Global Administrator** to trigger
first-party SP provisioning, then re-run `ETDG-Test-EnrollmentGroupPrereqs.ps1`. If it still does
not appear, open a **Microsoft support case** to have the Intune Provisioning Client initialized.

**Step B.1 — Add the owner (portal).** Entra → **Groups → `Autopilot – Devices – Pilot` → Owners →
Add owners**. Search by AppId **`f1346770-5b25-470b-88bd-d5744ab7952c`** (or by name — **Intune
Provisioning Client** *or* **Intune Autopilot ConfidentialClient**; **match by AppId**, the name
varies by tenant). Select it → **Add**.

**Step B.1 (alt) — Add the owner (script).** Run
`ETDG-Set-ProvisioningClientOwner.ps1 -GroupName "Autopilot – Devices – Pilot"` to preview
(`-WhatIf` default), then `-WhatIf:$false` to commit.

**Step B.2 — Wait for propagation.** Entra can take **5–10 minutes** to propagate the ownership.
Refresh the **Owners** blade and confirm an owner with **Application ID**
`f1346770-5b25-470b-88bd-d5744ab7952c` is listed before proceeding.

**Pass/fail (Gate B):** `ETDG-Assess-GroupReadiness.ps1` reports **Provisioning Client owner =
PASS** (found by AppId). If not present after 10 minutes, re-add and wait again.

**Rollback B:** Remove the SP from **Owners** (Entra → Groups → `<group>` → Owners → remove). The
group reverts to a plain security group; no devices are affected until a policy is wired.

---

## Phase C — Confirm admin management + RBAC scope

**Step C.1 — Manage check.** Confirm the operating admin can still edit the group's Owners/Members
(**R8**).

**Step C.2 — RBAC scope (custom Intune RBAC only).** If your tenant uses custom Intune RBAC: Intune
→ **Tenant administration → Roles → `<admin's role assignment>` → Scope (Groups)** and confirm the
target group (or a parent scope group containing it) is in scope (**R9**).
`ETDG-Test-EnrollmentGroupPrereqs.ps1` lists the admin's scope groups.

**Pass/fail (Gate C):** Admin can manage the group **and** (if custom RBAC) the group is in the
admin's scope. Tenants using only built-in roles pass C automatically.

---

## Phase D — Wire the group to the enrollment policy (pilot), then Save

Do the platform(s) you are deploying. Use the **Pilot** group in this phase.

### D-Windows — Autopilot device preparation

**Step DW.1 — Open the policy.** Intune → **Devices → Enrollment → Windows → Device preparation
policies** → create or edit **`Autopilot DevicePrep – Shared – Prod`** (name a pilot copy
`Autopilot DevicePrep – Shared – Pilot` if you prefer to keep pilot and prod separate).
*(Verify the exact blade name in your tenant — the device-preparation experience is newer and
labels vary.)*

**Step DW.2 — Set the Device Group.** In the policy's **Device group** setting, select
**`Autopilot – Devices – Pilot`**. This is the group devices join at enrollment.

**Step DW.3 — Save.** Click **Save/Create**. **Enrollment-Time Grouping is established here** — if
the owner (Phase B) is correct and propagated, Save commits. If you see *"…the Intune Provisioning
Client application is not an owner,"* stop and go to **06 — Troubleshooting** (do not disable
anything).

### D-Apple — ADE enrollment profile

**Step DA.1 — Locate the enrollment token.** Intune → **Devices → Enrollment → Apple → Enrollment
program tokens** → open **`ADE Token – Corporate – Prod`** → **Profiles**.
*(Path/label may read "Enrollment Program Tokens" or "ADE tokens" — verify in your tenant.)*

**Step DA.2 — Create/edit the ADE enrollment profile.** Create or edit **`ADE Enrollment – Shared
iOS – Prod`**. Set **User affinity = Enroll without user affinity** (shared devices). In the
profile's **Device Group** option, select **`iOS – Shared Devices – Pilot`**.

**Step DA.3 — Save.** Save the profile. The **same backend** establishes Enrollment-Time Grouping
here; the same owner requirement applies. Watch for the generic **"Updating device group for Apple
enrollment policy"** notification — if it hangs or fails, go to **06 — Troubleshooting**.

**Pass/fail (Gate D):** The pilot enrollment policy **Saves without the "not an owner" error** on
each platform you deployed.

**Rollback D:** Clear the **Device Group** setting on the policy/profile and Save (or delete the
pilot policy). Enrollment continues **without** enrollment-time grouping; devices fall back to
post-enrollment (dynamic/manual) group membership.

---

## Phase E — Validate, then Expand to Prod

**Step E.1 — Enroll a pilot device.** Enroll one Windows Autopilot device-prep device and/or one
Apple ADE device against the pilot policy.

**Step E.2 — Confirm enrollment-time membership.** After enrollment, confirm the device appears as
a **Member** of `Autopilot – Devices – Pilot` / `iOS – Shared Devices – Pilot`, and that
group-targeted apps/config apply. See **05 — Testing** for the exact checks and pass/fail.

**Step E.3 — Expand to Prod.** Repeat **Phases A–D** for the **Prod** groups
(`Autopilot – Devices – Prod`, `iOS – Shared Devices – Prod`) and the **Prod** enrollment policies,
then re-validate.

**Pass/fail (Gate E):** A pilot device **joins the group at enrollment** and receives the group's
assignments. Only then promote to Prod.

**Rollback E:** Point the Prod policy back at the previously working configuration (or clear its
Device Group). Because the group and owner are additive, rollback never removes protection from
already-enrolled devices — it only stops future enrollment-time additions.

---

## Order of operations (must not be reordered)

1. Group exists **to spec** (R1–R6) → 2. Owner added (R7) → 3. **Wait 5–10 min** for propagation →
4. Wire to policy → 5. **Save**. Saving before the owner has propagated is the most common
self-inflicted failure.
