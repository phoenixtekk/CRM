# Implementation — Departing-Employee Data-Theft Monitoring Quickstart

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Design → Configure → Pilot (limited scope) → Validate → Expand**) and — because this
capability is HR/privacy-sensitive — it **configures the privacy guardrails and role separation FIRST**,
before the policy exists. Every object is named verbatim so the scripts, testing, and troubleshooting
line up. Replace the `contoso.com` / sample group names with your own.

> **Portal note.** Insider-risk policy authoring is done in the **Microsoft Purview portal**
> (`purview.microsoft.com` → **Insider Risk Management**). PowerShell (Security & Compliance PowerShell /
> Graph) is used here for **readiness, role/scope verification, and reporting** — not to invent a
> policy-authoring path IRM does not expose. Where a portal path or capability may differ by
> tenant/licence, **verify against your licensing/tenant**.

> **Hard gate before you start.** Do **not** begin Phase 2 until Requirement **R9** (HR/legal/privacy
> engagement + lawful basis + agreed anonymization rules) is satisfied **in writing**. This policy
> monitors people; the applicability is a legal determination, not a technical one.

---

## Named objects (verbatim — used across docs, scripts, tests)

| Object | Name | Notes |
| --- | --- | --- |
| Pilot scope group | `SG-Departing-Pilot` | Small pilot population; becomes the standing monitored-leaver group at Expand. |
| Priority user group (optional) | `PUG-HighRisk-Leavers` | Executives / R&D / privileged admins, if used (R8). |
| Policy | `IRM-DepartingUser-DataTheft` | From MS template **Data theft by departing users**. |
| Role groups | Insider Risk Management **Admins / Analysts / Investigators / Auditors** | Avoid the combined **Insider Risk Management** group for operators. |

---

## Phase 0 — Assess (confirm you can build safely)

1. **Confirm licensing (R1).** Verify E5 / E5 Compliance / IRM add-on is assigned to in-scope users. IRM
   appears in the Purview left navigation.
2. **Confirm role separation (R2).** Run **`IRMDEPART-Discovery.ps1`** (read-only). Confirm the four
   functional role groups exist with minimal, correct membership, and that **no person holds a
   conflicting combination** (Admin + Investigator, etc.). The combined **Insider Risk Management** role
   group should **not** be assigned to production operators.
   - **Gate 0a:** role separation clean → continue. Overlap → fix membership **before** proceeding.
3. **Confirm privacy posture (R3).** In **Insider Risk Management → Settings → Privacy**, confirm **"Show
   anonymized versions of usernames"** is selected. `IRMDEPART-Discovery.ps1` flags this to confirm
   in-portal.
   - **Gate 0b:** anonymization **on** (or an explicit, written privacy/legal exception) → continue.
4. **Confirm the toolchain** (`global-requirements-purview.md` §3): `Connect-IPPSSession`,
   `Connect-ExchangeOnline`, and `Connect-MgGraph` all succeed with an MFA-capable admin.
5. **Confirm audit ingestion + readiness.** Run **`IRMDEPART-Test-HRConnector.ps1`** (read-only): unified
   audit-log ingestion on, HR-connector presence/freshness where readable, and the indicator/device
   portal checks.

## Phase 1 — Design (agree it with HR/legal, then name everything)

Decide and **record with HR/legal/privacy**:

- **Anonymization:** ON (default). Document **who** may de-anonymize, **on what basis**, with **what
  approval**, and that every de-anonymization is **audited**.
- **Scope:** the **minimum** population. Pilot with `SG-Departing-Pilot`; production is the standing set
  of actual/imminent leavers, expanded deliberately.
- **The policy** and its verbatim name: `IRM-DepartingUser-DataTheft` — template **Data theft by
  departing users**.
- **Trigger:** HR-connector resignation/termination date (preferred) — or Entra account deletion
  (fallback).
- **Indicators:** Office exfiltration (download / external share / email to external-personal) + Device
  exfiltration (USB / personal cloud / print) — device indicators need onboarding (R5).
- **Priority users (optional):** `PUG-HighRisk-Leavers` — with HR/legal.

## Phase 2 — Configure the guardrails FIRST

### 2.1 Role separation (do this before the policy exists)

In **Settings → Roles & scopes → Permissions** (or Purview **Roles & scopes**), assign named people to
**one** function each:

| Function | Role group | Sees identity? | Purpose |
| --- | --- | --- | --- |
| Build policy/settings | **Insider Risk Management Admins** | No | Configure the policy/indicators/connector |
| Triage | **Insider Risk Management Analysts** | Anonymized by default | Work the alert/case queue |
| Deep investigate | **Insider Risk Management Investigators** | De-anonymized where justified | Case + content/forensic detail |
| Audit the reviewers | **Insider Risk Management Auditors** | n/a (audit log only) | Independent oversight |

- **Do not** assign the combined **Insider Risk Management** role group to operators.
- **Pass/fail:** re-run `IRMDEPART-Discovery.ps1` — separation clean, no conflicting combinations.
- **Rollback:** remove any mis-assigned membership; role groups are additive and safe to correct.

### 2.2 Privacy and global settings

In **Insider Risk Management → Settings**:

- **Privacy** → **Show anonymized versions of usernames** (ON).
- **Policy indicators** → enable the Office and Device families the policy needs (2.3).
- **Policy timeframes** → set the **activation window** (detection window after the trigger, e.g. 30
  days) and **past activity** (look-back, e.g. 90 days) per your HR/legal agreement — for a leaver,
  the look-back is what lets you see exfiltration that began *before* the resignation was recorded.
- **Intelligent detections** → keep the default alert-volume and file-type exclusions initially.
- **Priority user groups** → create `PUG-HighRisk-Leavers` only if used (with HR/legal).

### 2.3 Turn on indicators (global switch the policy draws from)

Under **Settings → Policy indicators**, enable at least:

- **Office indicators:** SharePoint/OneDrive download, file shared externally, email sent to
  external/personal recipient.
- **Device indicators:** file copied to USB/removable media, file copied to personal cloud, file
  printed, file downloaded from cloud to device. *(Requires device onboarding — R5.)*
- **Cumulative exfiltration detection / sequence detection** (risk boosters) as agreed — useful for a
  leaver quietly taking many files over days.

## Phase 3 — Wire the trigger (HR connector)

1. **Settings → Data connectors** (or M365 admin center → **Data connectors**) → create the **HR
   connector**.
2. Register the **Entra app** the connector requires, note the **connector job ID**, and configure the
   **CSV/API upload** Microsoft documents (resignation date, termination date, and optionally job-level
   change). **No secrets in scripts** — the upload credential lives in the connector app, not in code.
3. Schedule regular uploads and confirm the connector shows **recent successful ingestion**.
4. **Alternative trigger:** if you have no HR feed, the departing-user policy can trigger on **Entra
   account deletion** — coarser (fires as the account is removed), but no connector required.

- **Pass/fail:** `IRMDEPART-Test-HRConnector.ps1` reports connector presence/freshness and audit
  ingestion; the portal shows a recent successful upload.

## Phase 4 — Build the one policy (scoped to the pilot)

**Insider Risk Management → Policies → Create policy**, choose the template, and scope to
**`SG-Departing-Pilot`** only:

1. **`IRM-DepartingUser-DataTheft`** — template **Data theft by departing users**.
   - **Trigger:** HR-connector leaver date (or Entra account deletion).
   - **Indicators:** Office + Device exfiltration indicators (2.3).
   - **Scope:** `SG-Departing-Pilot` (add `PUG-HighRisk-Leavers` scoring only if used).

- **Pilot rule:** keep scope at `SG-Departing-Pilot`; leave default thresholds initially. **Do not**
  widen scope yet.
- **Pass/fail:** the policy shows **Status = On** and **healthy** (no configuration warning) in the
  policy list. `IRMDEPART-Set-Policy.ps1 -WhatIf` validates prerequisites and prints the intended
  configuration/plan before you build in the portal.
- **Rollback:** set **Status = Off**; the policy is inert while off and scores no one.

## Phase 5 — Validate (run the gates)

Work the gates in `05-testing.md`:

- Role separation clean (no conflicting combinations).
- Anonymization **on** in the reviewer experience.
- Office + Device indicators enabled; devices onboarded; HR connector fresh (or account-deletion trigger
  chosen deliberately).
- The policy **On + healthy**, scoped to `SG-Departing-Pilot`.
- A **sanctioned test**: a pilot test account, marked as a leaver in the HR feed, performs a **benign**
  exfiltration action (e.g. copying a harmless test file to removable media on an **onboarded** device,
  or emailing a test file to an external test address) within the detection window → produces **scored
  activity → an alert**.
- The alert can be **triaged** and **escalated into a case**, and the case shows the **audited** reviewer
  trail.
- **Do not proceed to Expand until every gate passes** and HR/legal confirm the alert→case→hand-off
  workflow is acceptable.

## Phase 6 — Operate the review flow (and hand off to HR/legal)

1. **Triage** (Analyst): review the alert queue; for each alert **confirm** (real risk) or **dismiss**
   (benign), with a note. Reviewers see the **anonymized** experience by default.
2. **Escalate to a case** (Analyst/Investigator): confirmed, meaningful alerts become **cases** — the
   container with the user's scored activity, notes, and case actions.
3. **Investigate** (Investigator): where justified and role-permitted, view content/forensic detail and
   **de-anonymize identity** — this action is **audited** (Auditors can see it).
4. **Case actions:** send a **notification**, **escalate to eDiscovery** or **Communication Compliance**,
   or **resolve**. **Determination and any disciplinary outcome are HR/legal's** — the policy routes
   evidence to them; it does not decide.
5. **Audit** (Auditor): periodically review the **IRM audit log** to confirm reviewers acted within
   policy (especially de-anonymizations). `IRMDEPART-Report.ps1` gives a privacy-respecting rollup.

## Phase 7 — Expand (only after the gate passes)

Widen scope **deliberately** — from `SG-Departing-Pilot` to the standing monitored-leaver population —
using `IRMDEPART-Set-Scope.ps1` (`-WhatIf` first). In production, keep the scope group **in step with
your leaver process**: ideally the HR connector / a joiner-mover-leaver automation adds imminent leavers
to the group. Re-run the gates after each expansion. Keep anonymization on and role separation intact.

---

### Rollback summary

| Change | Rollback |
| --- | --- |
| Role assignment error | Remove the mis-assigned member from the role group (additive, safe). |
| Policy too noisy in pilot | Set policy **Status = Off**, tune thresholds/exclusions, re-pilot. |
| Anonymization mis-set | Re-select **Show anonymized versions of usernames** (Settings → Privacy). |
| Scope expanded too far | Remove the added members from `SG-Departing-Pilot` (`IRMDEPART-Set-Scope.ps1`). |
| HR connector bad data | Pause uploads, correct the source export, re-upload; trigger re-evaluates. |

> **Never** delete cases or audit records to "clean up" — they are the defensible, HR/legal-facing
> evidence trail. Retention/disposition of IRM records is a **records/legal determination**.
