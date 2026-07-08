# Implementation — Microsoft Purview Insider Risk Management

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Design → Configure → Pilot (analytics / limited scope) → Validate → Expand**) and — because
IRM is HR/privacy-sensitive — it **configures the privacy guardrails and role separation FIRST**,
before any policy exists. Every object is named verbatim so the scripts, testing, and troubleshooting
line up. Replace the `contoso.com` / sample group names with your own.

> **Portal note.** IRM policy authoring is done in the **Microsoft Purview portal**
> (`purview.microsoft.com` → **Insider Risk Management**). PowerShell (Security & Compliance PowerShell
> / Graph) is used here for **readiness, role/scope verification, and reporting** — not to invent a
> policy-authoring path IRM does not expose. Where a portal path or capability may differ by
> tenant/licence, **verify against your licensing/tenant**.

> **Hard gate before you start.** Do **not** begin Phase 2 until Requirement **R9** (HR/legal/privacy
> engagement + lawful basis + agreed anonymization rules) is satisfied **in writing**. IRM monitors
> people; the applicability is a legal determination, not a technical one.

---

## Phase 0 — Assess (confirm you can build safely)

1. **Confirm licensing (R1).** Verify E5 / E5 Compliance / IRM add-on is assigned to in-scope (and
   priority) users. IRM appears in the Purview left navigation.
2. **Confirm role separation (R2).** Run **`PURVIRM-Discovery.ps1`** (read-only). Confirm the four
   functional role groups exist with minimal, correct membership, and that **no person holds a
   conflicting combination** (Admin + Investigator, etc.). The combined **Insider Risk Management**
   role group should **not** be assigned to production operators.
   - **Gate 0a:** role separation clean → continue. Overlap → fix membership **before** proceeding.
3. **Confirm privacy posture (R3).** In **Insider Risk Management → Settings → Privacy**, confirm
   **"Show anonymized versions of usernames"** is selected. `PURVIRM-Discovery.ps1` flags this to
   confirm in-portal.
   - **Gate 0b:** anonymization **on** (or an explicit, written privacy/legal exception) → continue.
4. **Confirm the toolchain** (`global-requirements-purview.md` §3): `Connect-IPPSSession`,
   `Connect-ExchangeOnline`, and `Connect-MgGraph` all succeed with an MFA-capable admin.

## Phase 1 — Design (agree it with HR/legal, then name everything)

Decide and **record with HR/legal/privacy**:

- **Anonymization:** ON (default). Document **who** may de-anonymize, **on what basis**, with **what
  approval**, and that every de-anonymization is **audited**.
- **Scope:** the **minimum** population for each policy. Use a named pilot group first:
  `SG-IRM-Pilot`.
- **The three policies** and their verbatim names:
  - `IRM-DepartingUser-DataTheft` — template **Data theft by departing users**.
  - `IRM-DataLeaks-General` — template **Data leaks**.
  - `IRM-SecurityPolicyViolations` — template **Security policy violations**.
- **Indicators** each policy needs (Phase 3.2).
- **Triggers:** HR-connector leaver date (departing user), DLP match (data leaks), Defender for
  Endpoint alert (security policy violations).
- **Priority user groups** (if used): `PUG-Executives`, `PUG-Privileged-Admins` — defined with HR/legal.

## Phase 2 — Configure the guardrails FIRST

### 2.1 Role separation (do this before policies exist)

In **Settings → Roles & scopes → Permissions** (or Purview **Roles & scopes**), assign named people to
**one** function each:

| Function | Role group | Sees identity? | Purpose |
| --- | --- | --- | --- |
| Build policies/settings | **Insider Risk Management Admins** | No | Configure policies/indicators/connectors |
| Triage & investigate | **Insider Risk Management Analysts** | Anonymized by default | Work the alert/case queue |
| Deep investigate | **Insider Risk Management Investigators** | De-anonymized where justified | Case + content/forensic detail |
| Audit the reviewers | **Insider Risk Management Auditors** | n/a (audit log only) | Independent oversight |

- **Do not** assign the combined **Insider Risk Management** role group to operators.
- **Pass/fail:** re-run `PURVIRM-Discovery.ps1` — separation clean, no conflicting combinations.
- **Rollback:** remove any mis-assigned membership; role groups are additive and safe to correct.

### 2.2 Privacy and global settings

In **Insider Risk Management → Settings**:

- **Privacy** → **Show anonymized versions of usernames** (ON).
- **Policy indicators** → enable the families the three policies need (2 below references these).
- **Policy timeframes** → set the **activation window** (detection window after a trigger, e.g. 30 days)
  and **past activity** (look-back, e.g. 90 days) per your HR/legal agreement.
- **Intelligent detections** → keep default alert-volume and file-type exclusions; note MDLP alert
  import if you use endpoint DLP.
- **Priority user groups** → create `PUG-*` groups only if used (with HR/legal).
- **Analytics** → ensure Analytics is enabled (used in Phase 4).

### 2.3 Turn on indicators (global switch policies draw from)

Under **Settings → Policy indicators**, enable at least:

- **Office indicators:** SharePoint download, file shared externally, email sent to external/personal
  recipient. *(Data theft by departing users; Data leaks.)*
- **Device indicators:** file copied to USB/removable media, file copied to personal cloud, file
  printed, file downloaded from cloud to device. *(Requires device onboarding — R5. Data theft;
  Data leaks.)*
- **Microsoft Defender for Endpoint indicators.** *(Security policy violations — requires the MDE
  integration/connection.)*
- **Cumulative exfiltration detection / sequence detection** (risk boosters) as agreed.

## Phase 3 — Wire triggers and connectors

### 3.1 HR connector (departing-user / job-change trigger)

1. **Settings → Data connectors** (or M365 admin center → **Data connectors**) → create the **HR
   connector**.
2. Register the **Entra app** the connector requires, note the **connector job ID**, and configure the
   **CSV/API upload** Microsoft documents (resignation date, termination date, and optionally job-level
   change). **No secrets in scripts** — the upload credential lives in the connector app, not in code.
3. Schedule regular uploads and confirm the connector shows **recent successful ingestion**.
4. **Alternative trigger:** if you have no HR feed, the departing-user policy can trigger on **Entra
   account deletion** — coarser, but no connector required.
- **Pass/fail:** `PURVIRM-Test-Readiness.ps1` reports connector presence/freshness; portal shows a
  recent successful upload.

### 3.2 (Optional) Physical badging connector

Only if your scenario needs physical correlation (R7): create the **physical badging connector** and
confirm physical-access indicators appear under **Policy indicators**. Skip otherwise.

### 3.3 Defender for Endpoint connection (for security-policy-violation triggers)

Confirm the **Microsoft Defender for Endpoint** connection/integration is enabled so its alerts can act
as the **trigger** and **indicator** source for `IRM-SecurityPolicyViolations`. Verify in the Purview
IRM indicator settings and the Defender portal.

## Phase 4 — Pilot with analytics first, then a limited-scope policy

### 4.1 Run Insider Risk analytics (no policy, aggregate, safest first look)

1. **Insider Risk Management → Analytics** → **run scan** (opt-in). Analytics evaluates aggregate risk
   **without a policy and without naming individuals**, so you learn *where* risk concentrates and
   *which templates matter* before scoping anyone.
2. Review the analytics report with HR/legal to size the program.
- **Gate 4a:** analytics completed and reviewed → proceed to a scoped policy.

### 4.2 Build the three policies from templates — scoped to the pilot group

For each policy, **Insider Risk Management → Policies → Create policy**, choose the template, and scope
to **`SG-IRM-Pilot`** only:

1. **`IRM-DepartingUser-DataTheft`** — template **Data theft by departing users**.
   - Trigger: HR-connector leaver date (or Entra account deletion).
   - Indicators: Office + device exfiltration indicators (2.3).
   - Scope: `SG-IRM-Pilot`.
2. **`IRM-DataLeaks-General`** — template **Data leaks**.
   - Trigger: **DLP policy match** (select the DLP policy whose high-severity matches should trigger
     IRM; if you have none, create/point to a baseline DLP policy first) or exfiltration activity.
   - Indicators: Office + device exfiltration indicators.
   - Scope: `SG-IRM-Pilot`.
3. **`IRM-SecurityPolicyViolations`** — template **Security policy violations**.
   - Trigger: **Microsoft Defender for Endpoint** alert.
   - Indicators: Defender for Endpoint indicators.
   - Scope: `SG-IRM-Pilot`.

- **Pilot rule:** keep scope at `SG-IRM-Pilot`; leave default thresholds initially. **Do not** widen
  scope yet.
- **Pass/fail:** each policy shows **Status = On** and **healthy** (no configuration warning) in the
  policy list. `PURVIRM-Set-PolicyFromTemplate.ps1 -WhatIf` validates prerequisites and prints the
  intended configuration/plan before you build in the portal.

## Phase 5 — Validate (run the gates)

Work the gates in `05-testing.md`:

- Role separation clean (no conflicting combinations).
- Anonymization **on** in the analyst experience.
- Indicators enabled; HR connector fresh; MDE connected.
- Each policy **On + healthy**, scoped to pilot.
- A **test exfiltration** by a pilot user (e.g. copying a benign file to USB on an onboarded device,
  in a **sanctioned test**) produces a **scored activity → alert** within the detection window.
- The alert can be **triaged** and **escalated into a case**, and the case shows the **audited**
  reviewer trail.
- **Do not proceed to Expand until every gate passes** and HR/legal confirm the alert→case→hand-off
  workflow is acceptable.

## Phase 6 — Operate the alert → case workflow (and hand off to HR/legal)

1. **Triage** (Analyst): review the alert queue; for each alert **confirm** (real risk) or **dismiss**
   (benign), with a note. Reviewers see the **anonymized** experience by default.
2. **Escalate to a case** (Analyst/Investigator): confirmed, meaningful alerts become **cases** — the
   investigation container with the user's scored activity, notes, and case actions.
3. **Investigate** (Investigator): where justified and role-permitted, view content/forensic detail and
   **de-anonymize identity** — this action is **audited** (Auditors can see it).
4. **Case actions:** send a **notification** (policy-tip / reminder), **escalate to eDiscovery** or
   **Communication Compliance**, or **resolve**. **Determination and any disciplinary outcome are
   HR/legal's** — IRM routes evidence to them; it does not decide.
5. **Audit** (Auditor): periodically review the **IRM audit log** to confirm reviewers acted within
   policy (especially de-anonymizations).

## Phase 7 — Expand (only after the gate passes)

Widen scope **deliberately** — group-by-group, not tenant-wide in one move — using
`PURVIRM-Set-Scope.ps1` (`-WhatIf` first) to stage `SG-IRM-Pilot` → broader groups. Re-run the gates
after each expansion. Keep anonymization on and role separation intact as you scale.

---

### Rollback summary

| Change | Rollback |
| --- | --- |
| Role assignment error | Remove the mis-assigned member from the role group (additive, safe). |
| Policy too noisy in pilot | Set policy **Status = Off**, tune thresholds/exclusions, re-pilot. |
| Anonymization mis-set | Re-select **Show anonymized versions of usernames** (Settings → Privacy). |
| Scope expanded too far | Remove the added members from the scope group (`PURVIRM-Set-Scope.ps1`). |
| HR connector bad data | Pause uploads, correct the source export, re-upload; trigger re-evaluates. |

> **Never** delete cases or audit records to "clean up" — they are the defensible, HR/legal-facing
> evidence trail. Retention/disposition of IRM records is a **records/legal determination**.
