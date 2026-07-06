# 3. Implementation Guide — Regulated Google Workspace: Assured Controls, ITAR & DFARS

Configure controlled-data boundaries in Google Workspace: **data-region residency**,
**access-management / access-approval** controls, and a **named policy set for controlled data** —
validated against the compliance requirements on a **pilot**, then expanded. Follow the **Assess →
Configure → Pilot → Validate → Expand** model with a gate at each step and a documented rollback.

> **Full Admin console navigation is given click-by-click** from Google's public documentation. Menu
> paths reflect the current **Data → Compliance** location for these controls. **Add-on-gated features
> and policy options are edition-/contract-dependent** and are flagged **"verify in your tenant."**
> **Regulatory interpretation is deferred to legal/compliance** — every "which policy / which region"
> choice is theirs (requirement 2.2), not a technical default.

> **Sign in** to the Google Admin console at `https://admin.google.com` with a **super administrator**
> account (required for Access Management). The controlled-data compliance controls live under
> **Menu → Data → Compliance**.

---

## Step 0 — Assess: baseline the current controlled-data posture
**Goal:** know the starting state before changing anything.
1. Run `GWREG-Discovery.ps1` (read-only) to enumerate, for the tenant/OUs in scope: current **data
   region** posture, **CSE** enablement per service, **Access Management / Access Approvals** state (as
   readable), and the controlled-data **OU** layout.
2. Confirm licensing: Admin console → **Billing → Subscriptions** — Assured Controls / Assured Controls
   Plus add-on present on Frontline Plus / Enterprise Plus (requirement 2.1).
3. With the stakeholders (requirement 2.2), confirm the **required** posture: target **data region**
   (typically **United States**), required **Access Management policy** (e.g. **U.S. staff only** or
   **CJIS / IRS 1075-authorized only**), whether **Access Approvals** is required, and whether **CSE** is
   relied upon.
4. **Gate:** licensing confirmed, required posture documented and **approved** by legal/compliance,
   pilot OU (`Regulated Workspace – Controlled Data – Pilot`) exists (requirement 2.7). Do not proceed
   without the approved target posture.

---

## Step 1 — Configure data-region residency (data at rest) for the pilot scope
**Goal:** pin controlled data at rest to the required region.
1. Go to **Menu → Data → Compliance → Data regions**.
2. Select the **pilot OU** (`Regulated Workspace – Controlled Data – Pilot`) — not the top OU yet.
3. Set **Data at rest** to the required region: **United States** (for ITAR/DFARS, per legal —
   requirement 2.2). Options are **No Preference / United States / Europe**.
4. **Save** (choose **Override** if prompted for a child OU).
5. **Advanced settings (cross-region processing):** go to **Data regions → Advanced settings**. Per
   service (**Gmail, Drive/Docs, Calendar, Chat, Meet**) choose **Enable** or **Disable** features that
   may process data across multiple regions. **Disable** where legal requires strict in-region
   processing — note Google's caution that disabling may remove familiar functionality. **Save /
   Override.** *(Advanced settings require the qualifying edition/add-on — verify in your tenant.)*
6. Name this configuration in your runbook as **`RES-US-Controlled`** so it is reused verbatim when you
   expand.

> **Residency is not instantaneous.** Data at rest moves to the region on Google's schedule; verify in
> the data-regions reporting (Step 4) rather than assuming immediate effect.

---

## Step 2 — Configure Access Management (limit Google support staff) for the pilot scope
**Goal:** limit which Google staff can take support actions on controlled data.
1. Go to **Menu → Data → Compliance → Access Management** (super-admin required).
2. Select the **pilot OU** (or the controlled-data group).
3. Choose the **policy required by legal/compliance** (requirement 2.2), from Google's published options:
   - **No preference** — does not limit support personnel (not for controlled data).
   - **U.S. staff only** — U.S. persons in a physical U.S. location.
   - **CJIS / IRS 1075-authorized only** — U.S. persons in a U.S. location who have completed
     appropriate background checks.
   - **EU staff** — EU staff in EU locations (where an EU posture is required instead).
4. **Save** (or **Override** for a child OU).
5. Name it **`AXM-US-Controlled`** (or **`AXM-CJIS-Controlled`**) and reuse verbatim on expansion.

> **Licensing scope matters:** Access Management policies apply **only to users in OUs that hold the
> Assured Controls license** ([Google — Access Management][am]). Confirm the pilot OU is licensed.

---

## Step 3 — Enable Access Approvals for the pilot scope
**Goal:** require Google staff to get approval before viewing data for support.
1. Go to **Menu → Data → Compliance → Access Approvals**.
2. Select the **pilot OU** (or leave top OU only when expanding tenant-wide).
3. Check **"Require Google staff to request approval before viewing data necessary for support
   services."**
4. **Save.** Approval events are surfaced in **Access Transparency** logs (Step 4).
5. Define **who approves** requests and the SLA in your runbook (an internal process, not a Google
   setting).

---

## Step 4 — Stand up the evidence surface (Access Transparency + reporting)
**Goal:** make provider-access visible and auditable.
1. Confirm **Access Transparency** logging: Admin console reporting → choose **Access Transparency log
   events** from the data-source list ([Google — Access Transparency logs][at]). These log Google-staff
   access allowed via Access Management / Access Approvals.
2. Enable the bundled evidence features included with the add-on where required:
   **policy-compliance log events**, **data-regions advanced reporting**, and **compliance data
   exports** ([Google — About Assured Controls][ac]).
3. Point the evidence at your retention/SIEM destination (requirement 2.8).
4. Run `GWREG-Report.ps1` to compile a **coverage/evidence** report (residency, Access Management/
   Approvals state, CSE, and Access-Transparency availability) for the pilot scope.

---

## Step 5 — (If legal requires) configure Client-Side Encryption for controlled services
**Goal:** make controlled content indecipherable to Google, if the ITAR e2ee carve-out is relied upon.
> **Only perform this step if legal/compliance requires CSE** (requirement 2.2 / 2.5). CSE is a legal
> position, not a default.
1. Go to **Menu → Data → Compliance → Client-side encryption**; confirm the external **key service /
   IdP** is connected (stand up per Google's CSE documentation — deferred to vendor docs).
2. Enable CSE for the required services (e.g. **Drive/Docs, Gmail, Meet, Calendar**) scoped to the
   **pilot controlled-data OU**.
3. Record the scope and key-management ownership in the runbook; note CSE functional tradeoffs for
   users.

---

## Step 6 — Pilot & Validate against the compliance requirements
**Goal:** prove the configuration satisfies the *required* posture on the pilot before expanding.
1. Run `GWREG-Validation.ps1` against the pilot OU — it checks each configured control **against the
   required posture** you recorded in Step 0 (residency = target region, Access Management = required
   policy, Access Approvals on, CSE where required) and reports **pass/fail per control per scope**.
2. Run `GWREG-Report.ps1` to produce the coverage/evidence report for the pilot.
3. Test functionally: confirm pilot users can work; confirm data-regions reporting shows in-region
   residency; generate a support interaction (if feasible) and confirm it appears in **Access
   Transparency** and was gated by **Access Approvals**.
4. **Have legal/compliance review the validation output and evidence** and sign off that the pilot
   posture meets the requirement. *(This is their determination — not a script pass.)*
5. **Gate:** all required controls **pass** for the pilot **and** legal/compliance has signed off.
   Otherwise remediate (Step 7) and re-validate.

**Rollback (if the pilot fails):** revert data region to **No Preference**, set Access Management back to
the prior policy, uncheck Access Approvals, and (if enabled) disable CSE for the OU — all per the
change ticket, then re-baseline with `GWREG-Discovery.ps1`.

---

## Step 7 — Remediate gaps (safe, -WhatIf by default)
**Goal:** close any control that failed validation.
1. Run `GWREG-Remediation.ps1` — it **defaults to `-WhatIf`** and only **previews** the changes needed
   to bring a scope to the required posture (e.g. set data region, set Access-Management policy, enable
   Access Approvals).
2. Review the preview with the change approver.
3. Re-run with `-Execute` (or `-WhatIf:$false`) **only** inside the approved change window, then
   re-validate (Step 6).

---

## Step 8 — Expand to the full controlled-data population
**Goal:** roll the proven, named configuration to all controlled-data OUs.
1. Apply the **same named configurations** — `RES-US-Controlled`, `AXM-US-Controlled` (or
   `AXM-CJIS-Controlled`), Access Approvals, and CSE where required — to the remaining controlled-data
   OUs/groups (use `GWREG-Set-ScopeTargeting.ps1` to grow the scope consistently).
2. Confirm each expanded OU is **Assured Controls-licensed** before applying Access Management.
3. Run `GWREG-Validation.ps1` and `GWREG-Report.ps1` across the expanded scope; attach the evidence to
   the audit record.
4. **Gate:** full controlled scope passes validation and legal/compliance sign-off is recorded. Leave
   general (non-controlled) OUs unchanged.

---

## Deployment summary
| Step | Action | Admin path | Evidence |
|---|---|---|---|
| 0 | Assess baseline & confirm required posture | Billing → Subscriptions; `GWREG-Discovery.ps1` | Baseline report |
| 1 | Data-region residency (`RES-US-Controlled`) | Data → Compliance → Data regions (+ Advanced settings) | Data-regions reporting |
| 2 | Access Management (`AXM-US-Controlled`) | Data → Compliance → Access Management | Access Transparency |
| 3 | Access Approvals | Data → Compliance → Access Approvals | Access Transparency |
| 4 | Evidence surface | Reporting → Access Transparency log events; add-on exports | Logs / exports |
| 5 | CSE (if legal-required) | Data → Compliance → Client-side encryption | CSE / policy logs |
| 6 | Pilot & validate + legal sign-off | `GWREG-Validation.ps1` / `GWREG-Report.ps1` | Pass/fail + evidence |
| 7 | Remediate (`-WhatIf` default) | `GWREG-Remediation.ps1` | Change record |
| 8 | Expand | `GWREG-Set-ScopeTargeting.ps1` + re-validate | Coverage report |

---
[ac]: https://support.google.com/a/answer/13880647 "About Assured Controls and Assured Controls Plus — Google Workspace Admin Help"
[am]: https://support.google.com/a/answer/10343878 "Access Management — Google Workspace Admin Help"
[at]: https://support.google.com/a/answer/9230474 "Access Transparency — Google Workspace Admin Help"
