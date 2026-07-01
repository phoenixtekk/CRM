# 3. Implementation Guide — Microsoft 365 License Optimization & Reharvesting

Follow these steps **in order**. Inventory and usage come from the **Microsoft 365 admin center**
(`https://admin.microsoft.com`) and **Microsoft Graph**; reclamation is run safely with `-WhatIf`
first. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are
reused verbatim.

> **Model:** Build the baseline, classify the waste, reclaim a safe **pilot** set first, validate that
> savings landed and nobody broke, then expand and stand up the recurring campaign.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Step 1 — Pull the license inventory (Assess)
1. Admin center → `Billing → Licenses`. Note each subscription, its purchased quantity, and assigned count — the purchased-minus-assigned gap is the first, zero-risk saving (cancel unassigned seats at renewal).
2. Run `M365LIC-Discovery.ps1` to capture the authoritative inventory via Graph (`subscribedSkus` plus every user's `assignedLicenses`). It writes the export `License Inventory – M365 – Discovery`.
3. Confirm the script flags group-assigned seats (`assignedByGroup`) so you know which seats must be reclaimed via group membership later.

## Step 2 — Pull real usage (Assess)
1. Admin center → `Reports → Usage` — review the Microsoft 365 activity reports (Exchange, Teams, SharePoint, OneDrive) and confirm users are shown by name (Requirement 2.4).
2. Run `M365LIC-Report.ps1` to pull last-activity dates per user from the Graph usage reports and last sign-in from the directory. It writes the export `Usage Activity – M365 – Discovery` and joins it to the inventory.
3. Set the inactivity window you agreed (e.g. 90 days) as the script parameter so "unused" is defined objectively.

## Step 3 — Classify the candidates (Configure)
1. Run `M365LIC-Validation.ps1` to classify every assigned seat into the three levers and produce the list `Reclaim Candidates – M365 – Validation`:
   - **Unused / leaver** — no sign-in and no service activity across the full window.
   - **Duplicate** — a user carrying two SKUs that grant the same service.
   - **Over-tier** — a user on a higher SKU whose high-tier-only services show no activity (e.g. E5 features never used → E3 fits).
2. The script applies the exclusion group `Reclaim Exclusions – Shared+Service – AllStages` and drops any shared mailbox, room/resource, or service account from the candidate list.

## Step 4 — Build the targeting groups (Configure)
1. Run `M365LIC-Set-ScopeTargeting.ps1` to create/populate the Entra groups:
   - `Reclaim Exclusions – Shared+Service – AllStages` — protected accounts (build this first; never reclaimed).
   - `Reclaim Targets – Pilot – Stage1` — a small, safe subset of validated candidates (e.g. obvious leavers from one department).
   - `Reclaim Targets – Broad – Stage2` — the remaining validated candidates.
2. Tag the campaign as `Savings Campaign – M365 – Recurring` so each cycle's actions roll up to one savings line.

## Step 5 — Dry-run the reclamation (Pilot, no changes yet)
1. Run `M365LIC-Remediation.ps1 -WhatIf -TargetGroup "Reclaim Targets – Pilot – Stage1"`. With `-WhatIf` (the default) it makes **no changes** — it prints exactly which license each user would lose or how each would be right-sized.
2. Read every line. Confirm each user is genuinely a leaver / duplicate / over-tier case and that no protected account appears. For any leaver, confirm data-retention implications (mailbox/OneDrive grace) before proceeding.

## Step 6 — Reclaim the pilot set (Pilot)
1. Re-run `M365LIC-Remediation.ps1 -Execute -TargetGroup "Reclaim Targets – Pilot – Stage1"` to apply only the validated pilot changes (remove unused/duplicate licenses; right-size over-tier users).
2. For any seat assigned by group, the script reclaims it by removing the user from the licensing group rather than stripping the user license (Requirement 2.7).

## Step 7 — Validate the pilot (Validate)
1. Run `M365LIC-Validation.ps1` again — the reclaimed pilot users should no longer appear as candidates.
2. Run `M365LIC-Report.ps1` to produce `Savings Report – M365 – Report` — confirm the assigned count dropped and the recovered monthly cost is quantified.
3. Wait a short observation period and check no reclaimed user filed an access ticket. Complete the **Testing Guide** before expanding.

## Step 8 — Expand and reclaim the broad set (Expand)
1. Once the pilot passes the gate, run `M365LIC-Remediation.ps1 -WhatIf -TargetGroup "Reclaim Targets – Broad – Stage2"`, review, then `-Execute` it the same way as the pilot.
2. Re-run `M365LIC-Report.ps1` to update `Savings Report – M365 – Report` with the full recovered amount and reflect freed seats in your entitlement record for the next true-up/renewal.

## Step 9 — Stand up the recurring campaign (Expand)
1. Schedule the read-only chain monthly: `M365LIC-Discovery.ps1` → `M365LIC-Report.ps1` → `M365LIC-Validation.ps1`. Each run refreshes `Reclaim Candidates – M365 – Validation` with newly inactive/over-tier seats.
2. Each cycle, refresh the target groups with `M365LIC-Set-ScopeTargeting.ps1`, dry-run, then execute under the `Savings Campaign – M365 – Recurring` tag — keeping the tenant right-sized as the population changes.

---
### Order of operations
`Inventory → Usage → Classify → Build targeting groups → Dry-run (-WhatIf) → Reclaim pilot → Validate savings → Expand to broad → Recurring campaign`
