# Troubleshooting

A **symptom → root-cause decision tree** for Enrollment-Time Device Grouping. Match the exact
string or behavior you see, apply the fix, and re-test with the referenced script. The single most
common cause is a **missing or not-yet-propagated Provisioning Client owner** — start there.

---

## Decision tree (start at the top)

```
Did the enrollment policy SAVE?
├─ NO — error: "...Intune Provisioning Client application is not an owner"   → §1
├─ NO — error: "...could not find the security group you selected"          → §2
├─ NO — Apple: "Updating device group for Apple enrollment policy" hangs    → §3
├─ Seeing AuthorizationFailed / microsoft.insights errors in Azure log      → §4 (IGNORE — red herring)
└─ YES it saved, but devices never join the group at enrollment            → §7

Owner IS present, spec passes, still fails on Save                          → §8 (escalate)
Service principal cannot be found at all (by AppId or name)                 → §6
Using custom Intune RBAC and can't see/select the group                    → §5
```

Fast triage: `ETDG-Get-DiagnosticReport.ps1 -Symptom <NotAnOwner|CouldNotFindGroup|AppleUpdatingHang|AzureAuthorizationFailed|SavedButNoMembership|Unknown> -GroupName "<group>"`.

---

## §1 — "…the Intune Provisioning Client application is not an owner" (the definitive error)

**Full string:** *"Unable to save device group for `<name>`. You cannot update this configuration
because we could not find the security group you selected or the Intune Provisioning Client
application is not an owner."*

**When:** After you click **Save** on the enrollment policy/profile (Windows Autopilot device-prep
or Apple ADE). The failure appears **only after Save** because that is when Intune establishes the
group relationship.

**Root cause:** The Intune Provisioning Client service principal (AppId
`f1346770-5b25-470b-88bd-d5744ab7952c`) is **not an Owner** of the group — or you added it but it
**has not propagated yet**.

**Fix:**
1. Confirm the owner: `ETDG-Assess-GroupReadiness.ps1 -GroupName "<group>"` → **R7**. Or Entra →
   Groups → `<group>` → **Owners**, looking for **Application ID** `f1346770-…` (name may read
   *Intune Provisioning Client* or *Intune Autopilot ConfidentialClient* — **match by AppId**).
2. If missing, add it: `ETDG-Set-ProvisioningClientOwner.ps1 -GroupName "<group>" -WhatIf:$false`,
   or portal → Owners → **Add owners** → search by AppId → Add.
3. **Wait 5–10 minutes** for Entra propagation. Refresh the Owners blade, confirm it is listed.
4. Retry **Save**.

> If the SP genuinely does not exist in the tenant, go to **§6** first.

---

## §2 — "…could not find the security group you selected"

**Root cause (one of):**
- The group was **deleted or renamed** after you selected it.
- The group is **off-spec** — e.g. it is a **Dynamic**, **role-assignable**, or **directory-synced**
  group and cannot serve as an enrollment-time target.
- **Custom Intune RBAC scope** — the group is **outside** the operating admin's scope groups, so
  the service cannot resolve it for that admin (see **§5**).

**Fix:** `ETDG-Assess-GroupReadiness.ps1 -GroupName "<group>"` to confirm the group exists and is
Security / Assigned / cloud-only / not role-assignable. If it is off-spec on a create-only attribute
(Dynamic, role-assignable, synced), **create a fresh group to spec** (see 03 — Implementation,
Phase A). If the group is fine, check RBAC scope (**§5**).

---

## §3 — Apple: "Updating device group for Apple enrollment policy" hangs or fails

**When:** Saving the ADE enrollment profile's Device Group. The generic notification appears and
then stalls or errors (Apple surfaces a less specific message than Windows).

**Root cause:** The **same backend** as Windows. It is almost always the **missing/unpropagated
owner** (**§1**) or an **off-spec group** (**§2**) — Apple just gives you a vaguer symptom.

**Fix:** Treat it as **§1** then **§2**: run `ETDG-Assess-GroupReadiness.ps1` on the Apple group
(`iOS – Shared Devices – Pilot/Prod`), fix any FAIL (owner first), wait for propagation, re-save the
profile.

> **Documentation gap (be honest with stakeholders):** Microsoft documents Enrollment-Time Grouping
> for Windows Autopilot device preparation; **there is little Apple-specific Microsoft documentation**
> for the ADE Device Group option even though it uses the same mechanism. Do not expect an
> Apple-specific KB to match the Windows one — **verify control names/behavior in your tenant**.

---

## §4 — Azure Activity Log `AuthorizationFailed` / `microsoft.insights/...` — RED HERRING, ignore

**Symptom:** While troubleshooting, the Azure portal shows **`AuthorizationFailed`** errors on
**`microsoft.insights/eventtypes/values/read`** across one or more subscriptions.

**Root cause:** These are **Azure Monitor Reader-access** errors surfaced by the Intune/Azure portal
background — a permissions gap on **Azure Monitor**, **completely unrelated** to Enrollment-Time
Grouping.

**Fix:** **Ignore them for this problem.** Do **not** start granting subscription-level RBAC or
Monitor Reader roles hoping to fix the enrollment error — it will not. Return to **§1/§2** and
diagnose the actual Save error. (`ETDG-Get-DiagnosticReport.ps1 -Symptom AzureAuthorizationFailed`
restates this.)

---

## §5 — Custom Intune RBAC: cannot see or select the group

**Symptom:** The group exists and is to spec, but you cannot select it, or Save reports "could not
find the security group" for a specific admin only.

**Root cause:** With **custom Intune RBAC**, an admin can only act on objects within their assigned
**scope groups**. The target group (or a parent scope group) is not in the admin's scope.

**Fix:** Intune → **Tenant administration → Roles → `<admin's role assignment>` → Scope (Groups)**;
add the target group (or a parent scope group that contains it). Or perform setup as an admin whose
scope already includes it. `ETDG-Test-EnrollmentGroupPrereqs.ps1` lists role assignments / scope
groups. Tenants using **built-in roles only** are unaffected.

---

## §6 — The service principal cannot be found at all

**Symptom:** Searching Owners by AppId `f1346770-…` or by name (either *Intune Provisioning Client*
or *Intune Autopilot ConfidentialClient*) returns **nothing**; `ETDG-Test-EnrollmentGroupPrereqs.ps1`
reports **SP present = FAIL**.

**Root cause:** The Intune first-party service principal is **not yet provisioned** in the tenant.

**Fix:**
1. Sign in to **`https://intune.microsoft.com` once as a Global Administrator** — opening the Intune
   portal typically provisions the Intune first-party service principals.
2. Re-run `ETDG-Test-EnrollmentGroupPrereqs.ps1`. If the SP now appears, proceed to add it as owner
   (**§1**).
3. If it **still** does not appear, open a **Microsoft support case** to have the Intune
   Provisioning Client initialized.

---

## §7 — Policy saved, but devices never join the group at enrollment

**Root cause (one of):**
- The **owner was removed** from the group after Save (routine "cleanup" that silently breaks it).
- The device enrolled through a **different policy/profile** that lacks the Device Group setting.
- The group was **changed off-spec** after the fact.

**Fix:** Re-run `ETDG-Assess-GroupReadiness.ps1` and confirm **R7 (owner) still PASS**; confirm the
exact enrollment policy the device used still has the correct Device Group; re-enroll a test device
(**05 — Testing**, T5). `ETDG-Get-DiagnosticReport.ps1 -Symptom SavedButNoMembership -GroupName
"<group>"` corroborates live state.

---

## §8 — Owner is present and correct, spec passes, Save STILL fails (escalation)

**When:** `ETDG-Assess-GroupReadiness.ps1` reports everything PASS (owner by AppId confirmed, group
to spec), propagation time has elapsed, and Save still fails.

**Root cause:** Likely a **tenant/service-side backend issue**, not your configuration.

**Fix (capture the real error, then escalate):**
1. Reproduce the Save with **browser dev tools** open (F12 → **Network**), or replay the operation
   via **Microsoft Graph**, and capture the **actual failing request/response** — the backend error
   is more specific than the portal banner.
2. Open a **Microsoft support case** with that payload (the group id, the SP AppId `f1346770-…`
   confirmed as owner, timestamps, and the captured backend error).

---

## Quick reference — error string → cause → action

| You see… | Cause | Do this |
|----------|-------|---------|
| "…Provisioning Client application is not an owner" | Owner missing / not propagated | §1 — add SP owner by AppId, wait 5–10 min, retry Save |
| "…could not find the security group you selected" | Group deleted/renamed, off-spec, or out of RBAC scope | §2 / §5 |
| Apple "Updating device group…" hangs | Same backend — usually owner/spec | §3 → §1/§2 |
| Azure `AuthorizationFailed` / `microsoft.insights` | Azure Monitor noise, unrelated | §4 — **ignore** |
| SP not found by AppId or name | SP not provisioned | §6 — open Intune as Global Admin / support |
| Saved but no membership | Owner removed / wrong policy / changed group | §7 |
| All PASS but Save fails | Service-side backend issue | §8 — capture via Graph/dev tools, support case |
