# 2. Requirements Guide — Microsoft 365 License Optimization & Reharvesting

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-asset-mgt.md`.

## 2.1 Microsoft 365 admin / billing role
**Description:** An account with License Administrator plus Billing Administrator (or Global Administrator for the full workflow).
**Why:** Reading subscriptions and assignments, and removing or right-sizing licenses, requires these roles.
**Verify:** Microsoft 365 admin center (`https://admin.microsoft.com`) → `Billing → Licenses` loads and shows your subscriptions; you can open a user and edit their licenses.
**Implement:** Assign License Administrator + Billing Administrator in `Roles → Role assignments`; reserve Global Administrator for tenant-wide changes.

## 2.2 Microsoft Graph PowerShell SDK
**Description:** The `Microsoft.Graph` PowerShell module installed on the analyst workstation.
**Why:** All five scripts read and (for remediation) write license data through Microsoft Graph.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication`; run `M365LIC-Discovery.ps1` (it installs the module if missing).
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.3 Graph permission scopes (consented)
**Description:** Delegated scopes: `Organization.Read.All`, `User.Read.All`, `Directory.Read.All`, `Reports.Read.All` for read; `User.ReadWrite.All` and `Organization.Read.All` for reclamation.
**Why:** Read scopes pull subscriptions, assignments, and usage; the write scope removes/changes assignments.
**Verify:** Run `M365LIC-Validation.ps1` (read-only) — it connects with the read scopes and reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, an admin approves the scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.4 Usage reports enabled and identifiable
**Description:** Microsoft 365 usage analytics available, with the privacy setting that de-identifies user names turned **off** for the analysis.
**Why:** Per-user reclamation needs real names/UPNs in the usage reports; with de-identification on, activity rows are anonymized and cannot be matched to users.
**Verify:** Admin center → `Settings → Org settings → Services → Reports` — confirm "Display concealed user, group, and site names in all reports" is **not** checked (i.e. concealment is off). Then `Reports → Usage` shows named users.
**Implement:** Uncheck the conceal setting (a Global Administrator action), wait for reports to re-render with names, run the analysis, and restore the setting afterward per your privacy policy.

## 2.5 Defined inactivity window and exclusion rules
**Description:** An agreed inactivity threshold (e.g. 90 days of no sign-in and no service activity) and a list/group of accounts that must never be reclaimed (shared mailboxes, room/resource accounts, service accounts).
**Why:** "Unused" must be defined objectively, and protected accounts must be excluded so reclamation is safe.
**Verify:** The threshold is documented and the exclusion group `Reclaim Exclusions – Shared+Service – AllStages` exists with the protected accounts as members.
**Implement:** Agree the window with stakeholders; build the exclusion group with `M365LIC-Set-ScopeTargeting.ps1` (or in Entra) and add shared/service accounts.

## 2.6 Entitlement system of record and a savings target
**Description:** The authoritative purchased-quantity / renewal record (per `global-requirements-asset-mgt.md` G3) and a stated savings goal for the campaign.
**Why:** Reclaimed seats only become savings when reflected at the next true-up/renewal; a target makes the campaign measurable.
**Verify:** You can state the purchased quantity and renewal date for each in-scope SKU, and a savings target is recorded.
**Implement:** Populate the entitlement record from purchase orders / true-up statements; set a target (e.g. reduce assigned-vs-used gap by a chosen percentage).

## 2.7 (Optional) Group-based licensing in use
**Description:** Whether any in-scope licenses are assigned via group-based licensing rather than directly.
**Why:** A group-assigned license cannot be removed from a single user directly — you change group membership instead; mixing the two without knowing leads to "removal didn't stick."
**Verify:** Run `M365LIC-Discovery.ps1` — it flags users whose assignment is inherited from a group (`assignedByGroup`).
**Implement:** For group-assigned seats, reclaim by removing the user from the licensing group (`M365LIC-Set-ScopeTargeting.ps1`), not by stripping the user license.

---
## Checklist
- [ ] License + Billing admin role confirmed
- [ ] Microsoft Graph PowerShell SDK installed
- [ ] Graph read scopes consented (write scope ready for reclamation)
- [ ] Usage reports show named users (concealment off for the analysis)
- [ ] Inactivity window agreed; `Reclaim Exclusions – Shared+Service – AllStages` built
- [ ] Entitlement record current; savings target set
- [ ] Group-based licensing identified (reclaim via group membership where used)
- [ ] `Reclaim Targets – Pilot – Stage1` and `Reclaim Targets – Broad – Stage2` groups planned
