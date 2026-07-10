# 3. Implementation Guide — Entra Privileged Identity Management (PIM) — Government (GCC High)

This is the **Government (GCC High)** edition: it mirrors the commercial PIM method, adapted for
Microsoft's US Government national cloud (Azure Government / GCC High). Follow these steps in order.
Most steps are in the GCC High Microsoft Entra admin center (`https://entra.microsoft.us`) or the
**Azure Government portal** (`https://portal.azure.us` -> `Identity governance -> Privileged Identity
Management`); discovery, validation, and conversion use the included scripts, which target the US Gov
cloud (`Connect-MgGraph -Environment USGov`). *Verify the current GCC High portal URLs against
Microsoft Government documentation — DoD (IL5) tenants use different endpoints (see
`gcc-high-parity-notes.md`).*

> Model: protect break-glass first, discover standing access, set activation policy, convert a pilot
> cohort of roles to eligible, validate activation and audit, then expand to all privileged roles and
> Azure resource roles with access reviews and alerts. Every change is staged and reversible, and
> break-glass accounts stay excluded throughout.

## Step 1 — Protect the break-glass accounts (do this first)
1. Entra -> `Users`. Confirm two cloud-only accounts exist:
   `bg-admin-01@contoso.onmicrosoft.com` and `bg-admin-02@contoso.onmicrosoft.com`, each with the
   Global Administrator role assigned **permanently active (not via PIM)**.
2. Exclude both from broad Conditional Access and MFA-enforcement policies (they keep a strong,
   separately stored credential instead).
3. Create a sign-in alert for both accounts. Run `ENTPIMG-Alerting.ps1` to confirm they are excluded
   from PIM and that alerting is in place. **Never** make a break-glass account PIM-eligible.

## Step 2 — Discover standing privileged access
1. Entra -> `Identity governance -> Privileged Identity Management -> Microsoft Entra roles ->
   Assignments -> Active assignments` to see who holds directory roles now.
2. Run `ENTPIMG-Discovery.ps1`. It lists every active privileged assignment — account, role, and whether
   it is permanent — for Entra roles, and (with `-IncludeAzureResources`) Azure resource roles. Save the
   output; it is your baseline and your conversion worklist.
3. Flag the standing Global Administrators especially — Microsoft recommends keeping the number of
   permanent Global Administrators very small (break-glass only). *Verify current guidance in your tenant.*

## Step 3 — Set the activation policy per role (role settings)
1. Entra -> `Privileged Identity Management -> Microsoft Entra roles -> Settings`. Open a role you will
   onboard (start with a lower-risk role for the pilot, e.g. `User Administrator`).
2. Click `Edit` and set, per your Step 2.6 tiering:
   - `Activation` -> maximum duration (e.g. 8 hours for standard roles; 4 hours for Tier-0).
   - `Require Azure AD Multi-Factor Authentication on activation` -> On.
   - `Require justification on activation` -> On.
   - `Require ticket information on activation` -> On for change-controlled roles (optional).
   - `Require approval to activate` -> On for Tier-0 roles; set approvers to
     `PIM Privileged Role Approvers - Tenant - Steady`.
   - `Notification` -> enable alerts to admins on eligible assignment and activation.
3. Save. Repeat for each role in scope, most-privileged roles getting approval + shortest duration.

## Step 4 — Create eligible assignments for the pilot cohort
1. Entra -> `Privileged Identity Management -> Microsoft Entra roles -> Assignments -> Eligible
   assignments -> Add assignments`.
2. Select the role, add the members of `PIM Pilot Admins - Pilot - Pilot`, and set the assignment type
   to `Eligible` with an appropriate eligibility window (e.g. 6–12 months, or per your policy). Assign.
3. Communicate to the pilot admins how to activate (Step 6) before removing their standing access.

## Step 5 — Remove the matching standing (active) assignments — staged
1. Preview first: run `ENTPIMG-Set-EligibleAssignments.ps1` with its default `-WhatIf`. It reports, for
   the pilot cohort, the active assignments it would remove now that an eligible assignment exists —
   nothing is changed, and break-glass accounts are always excluded.
2. Confirm the preview: every pilot admin has an eligible assignment for each role you are about to
   de-activate, and no break-glass account is in the list.
3. Re-run with `-WhatIf:$false` scoped to the confirmed pilot cohort to remove the standing
   assignments. To do one in the portal instead: `Active assignments ->` the assignment `-> Remove`.

## Step 6 — Validate activation end-to-end (pilot)
1. As a pilot admin: Entra -> `Privileged Identity Management -> My roles -> Microsoft Entra roles ->
   Activate` the eligible role. Complete MFA, enter the justification (and approval, for Tier-0).
2. Confirm the role is granted for the set duration and that admin work now succeeds.
3. Wait for (or end) the activation and confirm the role auto-expires and privilege is gone.
4. Run `ENTPIMG-Report.ps1` and confirm the activation appears in the audit with actor, role,
   justification, and time. Complete the Testing Guide.

## Step 7 — Add access reviews for privileged roles
1. Entra -> `Privileged Identity Management -> Microsoft Entra roles -> Access reviews -> New`.
2. Create `Privileged Role Access Review - Tenant - Quarterly`: scope to the privileged roles, set a
   recurring quarterly schedule, reviewers = the role's owners or the approver group, and enable
   `auto-apply results` so unapproved eligibility is removed.
3. Save and start. Run `ENTPIMG-Report.ps1 -AccessReviews` to confirm the review is active.

## Step 8 — Onboard Azure resource roles (if in scope)
1. Entra -> `Privileged Identity Management -> Azure resources -> Discover resources`; onboard the
   target subscription/management group.
2. Repeat Steps 3–5 for Azure roles (e.g. `Owner`, `Contributor`, `User Access Administrator`): set
   role settings (MFA/justification/approval/duration), add eligible assignments, and remove standing
   ones via `ENTPIMG-Set-EligibleAssignments.ps1 -IncludeAzureResources` (preview first).

## Step 9 — Expand tenant-wide, with alerts on a schedule
1. Work the full Step 2 baseline in batches — onboard the remaining privileged roles, create eligible
   assignments, and remove standing access (preview, confirm, apply) until only break-glass accounts
   hold permanent Global Administrator.
2. Entra -> `Privileged Identity Management -> Microsoft Entra roles -> Alerts`. Review and enable the
   built-in alerts (too many Global Administrators, roles activated too frequently, roles being assigned
   outside of PIM, no MFA on activation). Run `ENTPIMG-Alerting.ps1` on a schedule to report alert state.
3. Re-run `ENTPIMG-Discovery.ps1` and `ENTPIMG-Report.ps1` monthly so new standing assignments are caught
   and activations stay audited.

---
### Order of operations
`Protect break-glass -> discover standing access -> set activation policy -> eligible assignments
(pilot) -> remove standing (pilot) -> validate activation + audit -> access reviews -> Azure resource
roles -> expand + alerts`

### Rollback
- Removed a standing assignment in error: re-add it in `Active assignments -> Add assignments`
  (immediate). Because conversion is confirmed per account from a `-WhatIf` preview, only reviewed
  accounts are ever changed, and break-glass accounts are always excluded.
- Activation policy too strict (e.g. no approver available): `Role settings -> Edit` the role and relax
  approval or duration; changes apply to the next activation.
- Locked out entirely: sign in with a break-glass account and revert the offending policy.
