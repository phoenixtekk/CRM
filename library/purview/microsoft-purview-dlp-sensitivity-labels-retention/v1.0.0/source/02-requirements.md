# 2. Requirements Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-security.md`.

## 2.1 Microsoft 365 + Purview licensing
**Description:** Licensing that includes sensitivity labels, DLP, and retention. Sensitivity labels
and basic DLP ship in Microsoft 365 E3 / Business Premium; auto-labeling at rest, endpoint DLP, and
advanced records management require Microsoft 365 E5 (or the E5 Compliance / Information Protection
and Governance add-on).
**Why:** The Purview features this solution configures are gated by plan; auto-labeling and endpoint
DLP will not appear without the higher plan.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; run `PURVIEW-Discovery.ps1`.
**Implement:** Assign the required plan (E3/Business Premium for labels + basic DLP; E5 or the E5
Compliance add-on for auto-labeling at rest, endpoint DLP, and advanced records).

## 2.2 Microsoft Purview roles
**Description:** The operator holds the roles needed to create labels, DLP, and retention — for
example **Compliance Administrator** (or **Information Protection Admin** plus **Data Loss Prevention
roles**) in the Purview portal.
**Why:** Creating and publishing labels, DLP policies, and retention policies requires these roles;
Global Administrator alone is not the least-privilege choice.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership.
**Implement:** Add the operator to **Compliance Administrator** (or **Information Protection Admin** +
DLP roles). Reserve Global Administrator for tenant-wide changes.

## 2.3 Sensitivity-label taxonomy defined
**Description:** A short, agreed set of labels with a clear meaning for each — the taxonomy this
solution publishes as `Sensitivity Label - Confidential - All Users` and its siblings.
**Why:** Labels only work if users understand them; too many labels confuse, too few under-protect.
**Verify:** A one-page taxonomy exists (label name, meaning, protection, who applies it).
**Implement:** Agree a 3–5 label taxonomy with data owners before configuring (see the Implementation
Guide, Step 1).

## 2.4 Data owners and a classification decision
**Description:** Named business owners who decide what is sensitive and how long it must be kept.
**Why:** DLP conditions and retention durations are business decisions, not IT defaults; without an
owner the policies will be wrong.
**Verify:** A named owner (and a retention schedule source) exists per data category.
**Implement:** Identify data owners; capture the sensitive data types and the required retention
periods.

## 2.5 Pilot scope (users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group of pilot users for label/DLP/retention piloting, and
— for endpoint DLP — devices onboarded to Microsoft Purview.
**Why:** Every policy is piloted before fleet rollout; DLP in particular must run in audit on a pilot
before it can enforce safely.
**Verify:** Entra → **Groups**; the pilot group `Purview - Pilot Users` exists. Purview → **Settings
→ Device onboarding** shows pilot devices onboarded (endpoint DLP only).
**Implement:** Build the pilot group with `PURVIEW-Set-ScopeTargeting.ps1`; onboard pilot devices via
the Purview device onboarding package.

## 2.6 Endpoint onboarding (endpoint DLP only)
**Description:** Windows devices onboarded to Microsoft Purview so endpoint DLP can monitor file
activity.
**Why:** Endpoint DLP conditions (copy to USB, upload to a browser, print) require onboarded devices;
un-onboarded devices are invisible to endpoint DLP.
**Verify:** Purview → **Settings → Device onboarding → Devices**; run `PURVIEW-Discovery.ps1`.
**Implement:** Deploy the onboarding configuration (Intune or the script package) to the pilot group.

## 2.7 Audit logging enabled
**Description:** Microsoft Purview audit (unified audit log) is turned on.
**Why:** DLP tuning and coverage reporting read audit/activity data; without it you cannot review the
audit gate or report classification.
**Verify:** Purview → **Audit**; searching returns results. Run `PURVIEW-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time for events to populate.

## 2.8 Change control for enforce-mode changes
**Description:** A documented change-control / rollback process for switching any DLP policy from
audit to enforce, or for activating a retention policy that deletes content.
**Why:** Enforce-mode DLP can block user work and retention deletion is irreversible; a pilot gate and
rollback are mandatory.
**Verify:** A change ticket exists with an approver, a pilot scope, and a documented rollback (revert
the DLP policy to test/audit; disable the retention policy).
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
enforcing.

---
## Checklist
- [ ] Microsoft 365 + Purview licensing (E3/Business Premium for labels + basic DLP; E5/add-on for auto-labeling at rest, endpoint DLP, advanced records) — `PURVIEW-Discovery.ps1`
- [ ] Purview roles assigned (Compliance Administrator / Information Protection + DLP)
- [ ] Sensitivity-label taxonomy defined (3–5 labels)
- [ ] Data owners named; sensitive types + retention periods captured
- [ ] Pilot scope group `Purview - Pilot Users` created — `PURVIEW-Set-ScopeTargeting.ps1`
- [ ] Endpoint devices onboarded (endpoint DLP only) — `PURVIEW-Discovery.ps1`
- [ ] Purview audit logging enabled — `PURVIEW-Report.ps1`
- [ ] Change control + rollback for enforce-mode / retention deletion
