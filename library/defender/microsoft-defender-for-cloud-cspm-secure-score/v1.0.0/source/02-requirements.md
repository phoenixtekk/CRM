# 2. Requirements Guide — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, network access, pilot scope, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to enabling Defender for Cloud CSPM and running a Secure-Score remediation program**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 At least one Azure subscription and a pilot scope
**Description:** An Azure subscription under the Entra tenant, and a decision on the **pilot subscription** to onboard first: `CSPM Scope – Pilot Sub – Pilot`.
**Why:** Defender for Cloud plans, Secure Score, and recommendations operate per subscription; the pilot limits blast radius and cost while you validate.
**Verify:** `portal.azure.com` → **Subscriptions**; run `DEFCSPM-Discovery.ps1` to list subscriptions and current plan status.
**Implement-if-missing:** Create/associate a subscription and choose the pilot subscription.

## 2.2 Rights to enable plans and manage governance
**Description:** **Security Admin** (plus **Owner** or **Contributor** at the subscription for plan changes and remediation), and **Security Reader** for read-only reporting accounts.
**Why:** Enabling Defender CSPM, agentless scanning, governance rules, and continuous export requires these rights; reporting only needs read.
**Verify:** Azure → **Access control (IAM)** at the pilot subscription; `DEFCSPM-Discovery.ps1` reports the running account's effective access.
**Implement-if-missing:** Assign the minimum roles at the narrowest scope; prefer PIM eligible activation over standing access.

## 2.3 Defender CSPM plan decision (paid) 
**Description:** A decision to enable the paid **Defender CSPM** plan (for agentless scanning, attack paths, risk hunting) versus staying on free foundational CSPM.
**Why:** Attack-path analysis, agentless scanning, and the security graph are **Defender CSPM** features; foundational CSPM alone gives Secure Score and recommendations only.
**Verify:** `portal.azure.com` → **Microsoft Defender for Cloud → Environment settings → <subscription> → Defender plans**; `DEFCSPM-Discovery.ps1` reports plan tiers. *Verify current Defender CSPM pricing and availability in your tenant.*
**Implement-if-missing:** Enable Defender CSPM on the pilot subscription (Implementation Step 2); keep it scoped to the pilot until validated.

## 2.4 Resource providers registered
**Description:** The **Microsoft.Security** resource provider (and **Microsoft.PolicyInsights** for the underlying assessments) registered on the subscription.
**Why:** Defender for Cloud assessments and Secure Score require the providers registered.
**Verify:** Azure → **Subscriptions → Resource providers** shows **Microsoft.Security** as Registered; `DEFCSPM-Validate.ps1` checks this.
**Implement-if-missing:** Register the provider (`Register-AzResourceProvider -ProviderNamespace Microsoft.Security`).

## 2.5 Log Analytics workspace for continuous export
**Description:** A Log Analytics workspace to receive **continuous export** of recommendations and Secure Score: destination for `CSPM Continuous Export – Pilot Sub – Prod`.
**Why:** Long-term trending, workbooks, and integration land in a workspace (per `global-requirements-defender.md` G7).
**Verify:** `portal.azure.com` → **Log Analytics workspaces**; `DEFCSPM-Discovery.ps1` reports available workspaces.
**Implement-if-missing:** Provision a workspace (or reuse the SIEM/observability one) with least-privilege access.

## 2.6 Regulatory-standard selection (compliance owns the choice)
**Description:** The regulatory standard(s) to display in the **regulatory-compliance dashboard** (e.g. a cloud security benchmark plus any required framework).
**Why:** The dashboard maps posture to a standard; without a selected standard there is nothing to measure against.
**Verify:** `portal.azure.com` → **Microsoft Defender for Cloud → Regulatory compliance → Manage compliance policies**; confirm the standard(s) assigned.
**Implement-if-missing:** Assign the Microsoft cloud security benchmark by default; **which additional standards apply is the compliance/legal team's determination** — add those they specify.

## 2.7 Agentless scanning prerequisites
**Description:** The permissions and scope for **agentless machine scanning** (part of Defender CSPM / Defender for Servers).
**Why:** Agentless scanning assesses VMs/disks without an agent but requires the plan and permission to snapshot/scan.
**Verify:** `portal.azure.com` → **Environment settings → <subscription> → Defender CSPM → Settings** shows agentless scanning availability; `DEFCSPM-Validate.ps1` reports its state. *Verify current agentless scanning requirements.*
**Implement-if-missing:** Enable agentless scanning in the Defender CSPM plan settings on the pilot subscription.

## 2.8 Multicloud connector decision (AWS/GCP, optional)
**Description:** Whether to extend posture to **AWS/GCP** via connectors, and the cloud accounts/roles required.
**Why:** Multicloud posture requires a connector and a role/service account in the target cloud; it is optional and scoped separately.
**Verify:** `portal.azure.com` → **Environment settings → Add environment (AWS/GCP)**; `DEFCSPM-Discovery.ps1` lists existing connectors.
**Implement-if-missing:** Add AWS/GCP connectors only after the Azure pilot is validated; keep to high-level posture at first.

## 2.9 Change control, pilot scope, and rollback
**Description:** An approved change record, the named pilot subscription, and a documented rollback before enabling paid plans or applying remediation broadly.
**Why:** Paid plans incur cost and remediation changes real resources; the pilot-first, preview-first approach and rollback are the safety net.
**Verify:** An approved change record, the pilot scope, and a written back-out (disable the plan / revert the change) exist.
**Implement-if-missing:** Capture the current posture with `DEFCSPM-Report.ps1 -SaveBaseline`, define the pilot scope, and write the rollback.

---
## Checklist
- [ ] Azure subscription + pilot subscription chosen — `DEFCSPM-Discovery.ps1`
- [ ] Security Admin + Owner/Contributor (change) and Security Reader (report) roles
- [ ] Defender CSPM (paid) plan decision made
- [ ] Microsoft.Security provider registered — `DEFCSPM-Validate.ps1`
- [ ] Log Analytics workspace for continuous export
- [ ] Regulatory standard(s) selected (compliance owns the choice)
- [ ] Agentless scanning prerequisites confirmed
- [ ] Multicloud (AWS/GCP) connector decision made
- [ ] Change window, pilot scope, and rollback documented
