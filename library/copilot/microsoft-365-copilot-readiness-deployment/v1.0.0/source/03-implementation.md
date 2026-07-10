# 3. Implementation Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Follow these steps **in order**. They use several portals: the Microsoft 365 admin center (`https://admin.microsoft.com`) for licensing and usage reports, the Entra admin center (`https://entra.microsoft.com`) for groups and licensing, the SharePoint admin center (via the M365 admin center) and Microsoft Purview (`https://purview.microsoft.com`) for data hygiene and labels, and Viva Insights for the Copilot value dashboard.

> Model: assess readiness and score it, remediate the blockers, license and enable a named pilot cohort, validate value on the pilot, then expand in waves. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):
- Readiness scorecard: `Copilot Readiness - Tenant - Assess`
- Cohort roster group (Entra): `Copilot Enablement - Pilot Cohort - Pilot`
- License-assignment group (Entra): `Copilot License - Pilot Cohort - Pilot`
- Rollout wave groups: `Copilot Enablement - Wave 1 - Production`, `... - Wave 2 - Production`

## Step 1 — Assess readiness and build the scorecard

1. Run `CPLTREADY-Discovery.ps1` → captures licensing (available Copilot seats), Entra identity/MFA posture, and workload provisioning for the tenant.
2. Run `CPLTREADY-OversharingScan.ps1` → captures the data-hygiene signal: broadly shared sites/links reachable in scope.
3. Record both outputs as the baseline `Copilot Readiness - Tenant - Assess`, and rank the blockers (identity → oversharing → unsupported configs). This scorecard is what the pilot gate compares against.

## Step 2 — Remediate the blockers (before any enablement)

1. **Identity:** ensure the pilot users are cloud identities with MFA enforced and healthy sign-in (see the Entra category solutions for hardening). Confirm Conditional Access does not inadvertently block the Copilot experiences.
2. **Data hygiene:** for the pilot scope, remediate the broad-access sites and links found in Step 1 — remove "Everyone/Everyone except external"/anonymous links on sensitive content. *Deep, tenant-wide oversharing remediation may need SharePoint Advanced Management (verify availability) or a dedicated engagement.*
3. **Information protection:** confirm a published sensitivity-label baseline exists in Purview (Requirement 2.5); publish one if not.
4. **Client/network:** move the cohort to a supported Microsoft 365 Apps channel/build and confirm endpoints are reachable (Requirement 2.6). *Verify current client requirements.*
5. Re-run the Step 1 scripts and confirm the ranked blockers are cleared for the pilot scope.

## Step 3 — Create the cohort and licensing groups

1. `entra.microsoft.com` → `Groups` → `New group` → create `Copilot Enablement - Pilot Cohort - Pilot` (the roster) and add the pilot users.
2. Create `Copilot License - Pilot Cohort - Pilot` for group-based licensing (you can nest or mirror the roster).
3. Keep the groups small and representative (a cross-section of roles) so pilot results generalize.

## Step 4 — Assign Copilot licenses to the pilot cohort

1. `entra.microsoft.com` → `Groups` → `Copilot License - Pilot Cohort - Pilot` → `Licenses` → `Assignments` → add the **Microsoft 365 Copilot** license → confirm the required base-plan services are enabled → `Save`. *Verify the current Copilot SKU/base-plan prerequisite in your tenant.*
2. Alternatively run `CPLTREADY-AssignLicenses.ps1` (default `-WhatIf` preview) to assign the Copilot SKU to the cohort group members via Microsoft Graph, then re-run with `-WhatIf:$false` to apply.
3. Confirm in `admin.microsoft.com` → `Billing` → `Licenses` that seats are consumed by the cohort.

## Step 5 — Enable and onboard the pilot cohort

1. Confirm Copilot is available to the licensed cohort in the Microsoft 365 apps (Word/Excel/Outlook/Teams) and Microsoft 365 Chat. Licensing is what enables the experience; there is no separate per-user "on" switch beyond the license and supported client.
2. Send the cohort a short enablement note: where Copilot appears, three or four starter prompts for their role, and how to give feedback.
3. Confirm audit for Copilot is on in Purview (Requirement 2.8) so interactions are auditable.

## Step 6 — Stand up the value dashboard

1. Open the **Microsoft Copilot Dashboard** in Viva Insights (in Teams or `https://viva.microsoft.com`) for adoption and impact signals. *Verify current availability and any Viva prerequisite in your tenant.*
2. In `admin.microsoft.com` → `Reports` → `Usage` → `Microsoft 365 Copilot`, review activation and active-usage figures for the cohort.
3. Run `CPLTREADY-Report.ps1` to compile a readiness-and-adoption snapshot against the Step 1 scorecard and the Requirement 2.7 success metrics.

## Step 7 — Validate the pilot (the gate)

1. Run `CPLTREADY-Validate.ps1` → confirms the cohort is licensed, the groups are correct, labels are published, and no ranked blocker is outstanding for the scope.
2. Run `CPLTREADY-Report.ps1` → confirms adoption/active-use against the success metrics (Requirement 2.7).
3. Pilot gate: do not begin waves until (a) the ranked blockers are cleared, (b) the cohort is actively using Copilot, and (c) the value signal meets the agreed threshold.

## Step 8 — Expand in waves

1. Create `Copilot Enablement - Wave 1 - Production` (and later waves), each a manageable population; remediate that wave's data-hygiene blockers *before* licensing it — the same order as the pilot.
2. Assign licenses to each wave's group (Step 4 pattern), enable, and add the wave to the value dashboard.
3. Advance to the next wave only when the current wave's blockers are cleared and adoption is tracking.
4. Re-run `CPLTREADY-OversharingScan.ps1` and `CPLTREADY-Report.ps1` each wave so new oversharing is caught before it becomes AI exposure and value stays visible to leadership.

---

### Order of operations

`Assess & score -> remediate blockers (identity, oversharing, labels, clients) -> cohort & licensing groups -> assign licenses -> enable & onboard cohort -> value dashboard -> validate pilot (gate) -> expand in waves (remediate-then-license each wave)`
