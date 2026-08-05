# Testing & Validation

The operating model is proven not by whether the documents exist, but by whether the **gates hold**
under real traffic. This section defines the pass/fail tests. Run the structural gates (1–4) after
Section 3's build, and the behavioural gates (5–8) during the Step 13 pilot.

Each gate has an explicit **PASS** condition. A gate that does not pass is not "mostly done" — it is
a hole in the model, and the section it belongs to must be corrected before you expand.

> **Government tenants:** the console URLs in the manual gates are `endpoint.microsoft.us` and
> `portal.azure.us`; add `-GraphEnvironment USGov` to every script invocation.

---

## Gate 1 — The structural objects exist (automated)

**Test:** Run the validation script.
```
powershell -ExecutionPolicy Bypass -File .\APPOPS-Validation.ps1 -CsvPath .\Validation.csv
```
**PASS when** every one of these lines reports `PASS`:
- Scope tag: `Scope – App Management – Prod`
- Scope tag: `Scope – App Management – Pilot`
- Custom role: `Role – App Deployment Engineer`
- Group: `APPGOV – Application Owners`, `APPGOV – Technical Owners`, `APPGOV – Security Reviewers`,
  `APPGOV – Deployment Engineers`
- Group: `PILOT – App Ring 1 – Validation`, `PILOT – App Ring 2 – Early Adopters`,
  `PROD – App Ring 3 – Broad`

**If it fails:** the named object is missing. Return to the step that creates it (Step 4 for APPGOV
groups, Step 5 for scope tags and the role, Step 6 for ring groups) and confirm you used the name
**verbatim**, including the en dash and single spaces.

---

## Gate 2 — The custom role grants exactly the intended rights (manual)

**Test:** Sign in to the console **as a member of `APPGOV – Deployment Engineers`** (not as an Intune
Administrator). Attempt each action:

| Action | Expected |
|---|---|
| Open **Apps → All apps** and edit an app carrying a `Scope – App Management – *` tag. | **Allowed.** |
| Open **Devices → Configuration** and try to create a configuration profile. | **Blocked / not visible.** |
| Open **Endpoint security → Conditional Access**. | **Blocked / not visible.** |
| Edit an app that carries **only** the Default scope tag. | **Blocked** (out of the role's scope). |

**PASS when** the deployment engineer can change **applications within the scope tags** and can do
**nothing else**. If they can edit device configuration or compliance, the role in Step 5b has excess
permissions — remove them.

---

## Gate 3 — Broad grants have been removed (manual)

**Test:** Navigate to `https://entra.microsoft.com` → **Identity → Roles & admins → Roles & admins →
Intune Administrator → Assignments**.

**PASS when** the only standing Intune Administrator assignments are the platform administrators who
genuinely need tenant-wide rights. Anyone whose work is *application deployment only* must have been
moved to `Role – App Deployment Engineer` (Step 5c, step 8). A long list of standing Intune
Administrators is a finding, not a pass.

---

## Gate 4 — Every application is governed (automated)

**Test:** Run the discovery script and read the governance baseline block.
```
powershell -ExecutionPolicy Bypass -File .\APPOPS-Discovery.ps1
```
**PASS when**, after Step 12, all four counts read **0**:
- Orphaned (no assignment): `0`
- All Users/All Devices: `0`
- No governed owner: `0`
- No scope tag (Default): `0`

A residual count is the exact list of applications still to remediate. Zero orphaned and zero
broad-target are the two that matter most for risk.

---

## Gate 5 — The intake gate returns non-conforming requests (behavioural)

**Test:** During the pilot, deliberately submit an intake request with **no named Application Owner**
and a second with **no business justification**.

**PASS when** both are **returned within the 3-business-day SLA**, not queued for the board, with a
clear statement of what is missing. If either reached the ARB agenda, the triage gate in Step 8 is
not being enforced — the point of the front door is that it is a filter, not a letterbox.

---

## Gate 6 — The board's decision rights are real (behavioural)

**Test:** Confirm two things over the pilot's two cycles:
1. Every application that reached `Approved – production` has a matching entry in the
   `ARB Decision Record` list with a decision of `Approved` or `Approved with conditions`, recorded
   within 1 business day.
2. At least one item was **deferred or rejected** (or, if the pilot genuinely had no rejectable
   items, that a Security-data item with no Security Reviewer present was correctly deferred).

**PASS when** approvals and their evidence are traceable one-to-one, and the board demonstrably said
"not yet" to at least one item. A board that approves everything is a rubber stamp; the deferral is
the proof the gate has teeth.

---

## Gate 7 — Ringed deployment and rollback work (behavioural)

**Test:** Take one approved pilot application through the full ring progression. Then, on a test
application, execute a **rollback** from Ring 1.

**PASS when:**
- The application was assigned to `PILOT – App Ring 1 – Validation` first, dwelt the minimum time,
  and was promoted to Ring 2 and Ring 3 only after meeting the promotion gate in Step 6.
- No approved application in the pilot is assigned directly to *All Users* or *All Devices* (confirm
  with Gate 4).
- The rollback was executed by a Deployment Engineer **without requiring any approval**, and
  completed within the expected duration recorded in the runbook.

---

## Gate 8 — Change classification is applied consistently (behavioural)

**Test:** Take three real changes from the pilot — ideally one version update, one new app, and one
higher-risk change — and check each against the Step 10 matrix.

**PASS when** each change's actual approval path matched its tier: the version update went through as
a pre-approved standard change (no ARB slot consumed); the new app went through ARB approval; and the
higher-risk change carried the additional Security Reviewer sign-off (and CAB notification/approval
where applicable). A Tier 1 change that consumed an ARB slot, or a Tier 3 change that skipped
Security, is a misclassification to correct in the retrospective.

---

## The overall pass condition

The model is ready to expand (Step 14) when **Gates 1–4 pass automatically** and **Gates 5–8 pass
across the two pilot cycles**. Record the results alongside the Step 1 baseline; the contrast between
the ungoverned baseline and the passing gates is the evidence you present to the executive sponsor to
authorise tenant-wide rollout.
