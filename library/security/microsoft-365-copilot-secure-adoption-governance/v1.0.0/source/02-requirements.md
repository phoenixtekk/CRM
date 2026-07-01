# 2. Requirements Guide — Microsoft 365 Copilot Secure Adoption & Governance

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-security.md`.

## 2.1 Microsoft 365 Copilot licensing
**Description:** A Microsoft 365 Copilot license for each pilot user, on a qualifying base plan.
**Why:** Copilot only functions for licensed users; the license is a paid add-on with base-plan prerequisites.
**Verify:** Microsoft 365 admin center (`https://admin.microsoft.com`) → **Billing → Licenses**; confirm Microsoft 365 Copilot licenses are available and unassigned enough for the pilot.
**Implement:** Acquire Microsoft 365 Copilot licenses on a qualifying Microsoft 365 plan; do **not** assign them broadly yet — assignment is gated to the pilot group in Implementation.

## 2.2 Microsoft 365 with SharePoint Online / OneDrive
**Description:** SharePoint Online and OneDrive as the content estate Copilot will reason over.
**Why:** SharePoint/OneDrive sharing is the primary control surface for oversharing — the top risk.
**Verify:** SharePoint admin center (`https://<tenant>-admin.sharepoint.com`) loads; sites and OneDrive are present.
**Implement:** Ensure Microsoft 365 with SharePoint/OneDrive is provisioned before assessing access.

## 2.3 Microsoft Purview (sensitivity labels + DLP)
**Description:** Microsoft Purview access to publish sensitivity labels and Data Loss Prevention policies.
**Why:** Labels are the protection Copilot honors; DLP-for-Copilot adds a policy layer that can exclude content.
**Verify:** Microsoft Purview portal (`https://purview.microsoft.com`) → **Information Protection** and **Data Loss Prevention** load.
**Implement:** Confirm a plan that includes sensitivity labels and DLP (e.g. Microsoft 365 E5 / E5 Compliance, or equivalent); assign the operator the required Purview roles.

## 2.4 SharePoint / OneDrive access review (oversharing assessment)
**Description:** A completed review of broad sharing: org-wide links, "Everyone / Everyone except external users", and stale external/guest access.
**Why:** This is exactly what Copilot will surface; it must be assessed and remediated before enabling Copilot.
**Verify:** Run `COPILOT-Discovery.ps1` (reports broad-sharing and external-access signals) and review `COPILOT-Report.ps1` output.
**Implement:** Complete the access review in Implementation Steps 1–2 (assess, then remediate) before the pilot gate.

## 2.5 Sensitivity labels published (or ready to publish)
**Description:** A sensitivity-label taxonomy (e.g. Public / Internal / Confidential / Highly Confidential) published to users, with protection where required.
**Why:** Copilot honors label-based access and inherits the most restrictive label of its sources; unlabeled content relies on permissions alone.
**Verify:** Purview → **Information Protection → Labels** and **Label policies** show published labels.
**Implement:** Create and publish the label taxonomy in Implementation Step 3; apply auto-labeling where available.

## 2.6 Governance roles / administrative access
**Description:** The operator holds the roles needed for Copilot, SharePoint, and Purview changes.
**Why:** Enabling Copilot, editing sharing controls, and publishing labels/DLP require elevated, scoped rights.
**Verify:** Entra → **Roles and administrators**; confirm roles such as SharePoint Administrator and the required Purview/Compliance roles (reserve Global Administrator for tenant-wide toggles).
**Implement:** Assign least-privilege roles for each surface; record who owns data governance, labels/DLP, and AI use.

## 2.7 Copilot pilot group
**Description:** An Entra security group `Copilot Adoption – Pilot Users – Pilot` for the controlled rollout.
**Why:** Copilot must be validated on a small, curated group before fleet expansion (pilot gate + rollback).
**Verify:** Entra → **Groups**; the pilot group exists. Or run `COPILOT-Set-ScopeTargeting.ps1`.
**Implement:** Create the group with `COPILOT-Set-ScopeTargeting.ps1` (or Entra → **Groups → New group → Security**), and add a few representative users.

## 2.8 AI governance / acceptable-use policy
**Description:** A documented acceptable-use policy for Copilot and named governance owners.
**Why:** AI use must be governed by humans — what Copilot may be used for, output review, and data handling.
**Verify:** An acceptable-use policy exists and is communicated to pilot users; owners are named.
**Implement:** Draft and publish the acceptable-use policy in Implementation Step 6 before pilot users get access.

## 2.9 Change control for data-access and AI-enablement changes
**Description:** A documented change/rollback process for sharing-control, label, DLP, and Copilot-enablement changes.
**Why:** Tightening access or changing labels can block legitimate work; enabling Copilot changes the data-exposure surface. A pilot gate and rollback are mandatory (see global G8).
**Verify:** A change ticket exists with an approver, a maintenance window, and a rollback step.
**Implement:** Record the change, name the pilot group, define the rollback (e.g. re-widen a link, unpublish a label, remove Copilot licenses), and get approval before production.

---
## Checklist
- [ ] Microsoft 365 Copilot licenses available (not yet broadly assigned)
- [ ] SharePoint Online / OneDrive provisioned
- [ ] Microsoft Purview (sensitivity labels + DLP) available with operator roles
- [ ] Oversharing assessment run — `COPILOT-Discovery.ps1` / `COPILOT-Report.ps1`
- [ ] Sensitivity-label taxonomy published (or ready to publish)
- [ ] Governance/admin roles assigned (SharePoint, Purview, Copilot)
- [ ] `Copilot Adoption – Pilot Users – Pilot` group created
- [ ] Acceptable-use policy drafted and owners named
- [ ] Change control / rollback documented
