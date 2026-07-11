# 2. Requirements Guide — Proof-of-Concept Kit: Microsoft Defender for Cloud

Verify **every** requirement before enabling anything. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running a scoped Defender-for-Cloud proof of concept**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 A pilot Azure subscription (or resource group)
**Description:** One **non-production Azure subscription** (or a scoped resource group) to run the PoC.
**Why:** Defender for Cloud is enabled per subscription; the PoC deliberately uses one so it can be disabled cleanly with no impact elsewhere.
**Verify:** `POCMDC-Enable.ps1 -WhatIf` lists the subscription and its current Defender state; you can sign in with `Connect-AzAccount`.
**Implement-if-missing:** Choose a test/dev subscription (or create a pilot resource group `MDC PoC – Pilot RG – Pilot`).

## 2.2 Azure roles to enable and tear down
**Description:** **Security Admin** and **Contributor** (or Owner where a plan requires it) on the pilot subscription.
**Why:** Enabling/disabling Defender plans and deploying/removing the benign test resource require these roles.
**Verify:** `portal.azure.com` → **Subscriptions → Access control (IAM)** confirms your roles; `POCMDC-Enable.ps1 -WhatIf` reports permission gaps.
**Implement-if-missing:** Assign Security Admin + Contributor on the pilot subscription for the running account.

## 2.3 Awareness of Defender plan pricing
**Description:** Acknowledgement that **Defender workload plans are billed while enabled**.
**Why:** A PoC that leaves a plan on becomes an open-ended cost; the kit keeps the window short and disables at teardown.
**Verify:** Review current Defender-for-Cloud pricing for the plan you will enable. *Verify current pricing before enabling.*
**Implement-if-missing:** Confirm the cost owner accepts the short PoC billing window, and diarise the teardown.

## 2.4 A pilot workload to protect (optional VM/resource)
**Description:** Optionally, a **pilot VM or resource** in the pilot subscription to exercise a workload plan (e.g. a test VM for Defender for Servers, or a storage account for Defender for Storage).
**Why:** A workload plan needs a resource to protect so the CWPP demonstration (e.g. EICAR on a server) has a target.
**Verify:** `POCMDC-Enable.ps1 -WhatIf` lists candidate resources.
**Implement-if-missing:** Deploy a small test VM (or use an existing test resource) in `MDC PoC – Pilot RG – Pilot`.

## 2.5 A Log Analytics workspace (where required)
**Description:** A **Log Analytics workspace** for continuous export / server assessment where the chosen plan uses one.
**Why:** Some Defender-for-Cloud data and server assessments land in a workspace (per `global-requirements-defender.md` G7).
**Verify:** A workspace exists and is access-controlled; `POCMDC-Enable.ps1 -WhatIf` reports it.
**Implement-if-missing:** Provision (or reuse) a workspace scoped to the pilot subscription.

## 2.6 Evaluation criteria agreed up front
**Description:** A short, written list of what "pass" means — e.g. *the misconfiguration produced a recommendation, Secure Score changed, a security alert fired, and regulatory-compliance data populated.*
**Why:** A PoC is only conclusive if the bar is set **before** you run it; the scorecard maps observations to these criteria.
**Verify:** A criteria list exists; `POCMDC-Scorecard.ps1` accepts it as input.
**Implement-if-missing:** Draft 5–8 criteria with the evaluating stakeholders before Step 1. *What counts as "good enough" is the customer's decision.*

## 2.7 Read access for validation
**Description:** **Security Reader** on the subscription (and `ThreatHunting.Read.All` where hunting is used).
**Why:** The validate and scorecard scripts read recommendations, Secure Score, and alerts.
**Verify:** `POCMDC-Validate.ps1` returns data; `Get-AzSecurityAlert` / `Get-AzSecuritySecureScore` succeed.
**Implement-if-missing:** Grant Security Reader on the pilot subscription to the running account.

---
## Checklist
- [ ] A pilot Azure subscription (or resource group `MDC PoC – Pilot RG – Pilot`) — `POCMDC-Enable.ps1 -WhatIf`
- [ ] Security Admin + Contributor to enable/tear down
- [ ] Awareness that Defender plans are billed while enabled — *verify current pricing*
- [ ] (Optional) a pilot VM/resource to exercise a workload plan
- [ ] A Log Analytics workspace where the plan requires one
- [ ] Evaluation criteria agreed and written down — `POCMDC-Scorecard.ps1`
- [ ] Security Reader (and hunting read) for validation
