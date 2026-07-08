# 3. Implementation Guide — Cloud-App DLP (Defender for Cloud Apps)

This is the exact, ordered procedure to extend DLP to third-party cloud apps with Microsoft Defender for
Cloud Apps (MDCA) — **file policies** (data at rest, via API connectors) and **session/access policies**
(real time, via Conditional Access App Control). Every enforcing control is piloted in **test mode first**:
the Entra Conditional Access policy in **report-only**, session policies set to **Monitor only**, and file
policies to **alert-only** — then tuned, enforced on a ring, then expanded. Portal paths and cmdlets are
from Microsoft's public documentation; **licensing-/plan-dependent features and evolving portal paths are
flagged "verify your licensing/tenant"** and are never asserted for your tenant. Do the phases in order.
Each phase names its artifacts (from the Overview naming table), states a **pass/fail gate**, and gives a
**rollback**.

> **Automation.** The five delivered PowerShell tools run through **Microsoft Graph** (Conditional Access,
> sensitivity labels, security alerts), **Security & Compliance PowerShell** (`Connect-IPPSSession`, SITs/
> labels), and — where a token is supplied via an environment variable — the documented **MDCA REST API**
> (read-only GET). They are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No
> credentials are stored in code.

> **Determinations deferred.** *Which* apps and data categories are in scope, *which* classifiers legally
> apply, and the *governance/session action* per category are **compliance/privacy/legal** decisions. This
> guide configures and proves the control; capture those decisions before Phase 4.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'Policy.Read.All','InformationProtectionPolicy.Read','SecurityEvents.Read.All' -NoWelcome
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\DLPCLOUD-Discovery.ps1 -CsvPath .\DLPCLOUD-Posture.csv
   ```
   It reports the sensitivity labels and SITs available for content inspection, any Conditional Access
   policies that route sessions to MDCA (CA App Control), and — if an MDCA API token is supplied — connected
   app connectors and existing file/session policies. Read-only.
3. **Confirm licensing and the two enabling planes** (Req 2.1, 2.3, 2.4): confirm the **Cloud apps** node is
   present in the Defender portal; confirm which target apps have an **API connector** (file plane) and
   whether any **CA App Control** routing exists (session plane). The readiness script (#2) checks both.

**Pass/fail gate:** you have a written baseline — labels/SITs available, connected apps, and CA App Control
state — and confirmed MDCA licensing.
**Rollback:** none (read-only).

---

## Phase 1 — Enable the two control planes (Configure the plumbing)

Neither plane works until it is wired. Do the plane(s) your scope needs.

4. **Connect the SaaS apps for file policies (data at rest).** In **Microsoft Defender portal → Cloud apps →
   App connectors → Connect an app**, connect each in-scope app (e.g. `Box – App Connector – API`) via its
   API connector, authorizing with an admin of that app. Wait for the **initial scan** to complete —
   `App connectors` shows the status. *A file policy is inert until its app is connected.*
5. **Onboard apps for session/access policies (real time).** In **Microsoft Entra → Protection → Conditional
   Access → Create policy**, create `MDCA – CA App Control – Session Routing`:
   - **Assignments → Users:** scope to `MDCA Pilot Ring – Stage1` (pilot only, for now).
   - **Target resources → Cloud apps:** the app(s) to control (e.g. a featured SaaS app).
   - **Session → Use Conditional Access App Control →** *Use custom policy* (so MDCA session policies apply).
   - **Enable policy: Report-only** (this is the test-mode setting — the policy evaluates and logs without
     enforcing).
   Confirm the app appears under **Cloud apps → Conditional Access App Control apps**. Verify the target app
   is **supported for session control** before relying on it.

**Pass/fail gate:** each in-scope app is **connected** (file plane) and/or **onboarded to CA App Control**
with the CA policy in **report-only** (session plane); the discovery/readiness scripts confirm both.
**Rollback:** disconnect the app connector (stops at-rest visibility, no data change) / set the CA policy to
**Off** (stops routing instantly).

---

## Phase 2 — Confirm the detection layer (SITs & labels)

Do **not** invent SITs/labels — reuse the Purview classification layer you already have.

6. **Confirm the SITs and labels** for each in-scope data category. **Purview portal → Data classification →
   Classifiers → Sensitive info types** (built-in + custom + EDM) and **Information protection → Labels**.
   The discovery script (#1) lists what is available. If a category has no detector, build the custom SIT/EDM
   in Purview first (out of scope for this solution's steps, but a hard dependency).
7. **Decide the match per policy:** which **SIT** (at what confidence/instance count) and/or which
   **sensitivity label** each file/session policy will match on.

**Pass/fail gate:** every in-scope data category maps to a named SIT and/or label that MDCA can inspect.
**Rollback:** none (no change — read/confirm only).

---

## Phase 3 — Build the policies in TEST mode (alert-only / Monitor-only)

Create policies with **non-enforcing** actions first. **Cloud apps → Policies → Policy management → Create
policy.**

8. **File policy — `MDCA – SaaS Files PII – File Policy`** (data at rest).
   Create a **File policy** → **Filters:** app = the connected app; and **content** filter = *the SIT(s)*
   from Phase 2 and/or *sensitivity label* = the target label; optionally *sharing level* = external/public.
   **Governance actions: alert-only first** — enable *Create an alert* and *Notify the file owner*; **do not**
   yet enable *Remove external sharing*, *Apply sensitivity label*, *Put in quarantine*, or *Trash*. Save.
9. **Session policy — `MDCA – Download Protect PII – Session Policy`** (real time).
   Create a **Session policy** → **Session control type:** *Control file download (with inspection)* →
   **Activity source / app:** the CA-App-Control app → **content inspection:** match the SIT/label from
   Phase 2 → **Action: Monitor only** (test mode — no block/protect yet). Save. (A second session policy can
   cover *upload*, *copy/paste*, or *print* — all **Monitor only** first.)
10. **Access policy (optional) — `MDCA – Unmanaged Device – Access Policy`.**
    If access-level control is in scope, create an **Access policy** filtering on device tag
    (unmanaged/non-compliant) with **Action: Monitor only** first.
11. **Keep the CA policy in report-only** (from Phase 1) while session/access policies are **Monitor only** —
    together these are the MDCA equivalent of DLP "simulation": everything evaluates and logs, nothing is
    enforced.
12. **Verify with the config helper** (delivered script #3, `-WhatIf` by default):
    ```powershell
    .\DLPCLOUD-FilePolicy.ps1 -PolicyName 'MDCA – SaaS Files PII – File Policy' -Sit 'Credit Card Number' -Label 'Confidential' -WhatIf
    ```
    It validates that the referenced SIT/label exist (S&C/Graph read), emits the exact policy specification to
    enter in the portal, and — with an MDCA API token — can list current file policies read-only. It never
    creates an enforcing policy.

**Pass/fail gate:** file policy exists with **alert-only** governance; session/access policies exist as
**Monitor only**; CA policy is **report-only**; scopes and SIT/label matches are correct.
**Rollback:** delete the policy (test-mode policies took no enforcing action, so removal is clean).

---

## Phase 4 — Measure and tune (drive false positives down)

Let the policies run in test mode for the agreed **dwell time** (Req 2.6) to capture representative activity.

13. **Review what matched.** **Cloud apps → Alerts** (file-policy alerts, session Monitor-only logs) and the
    file/activity views show every match with the file/user, the SIT/label, and the app. Export with the
    reporting script:
    ```powershell
    .\DLPCLOUD-Report.ps1 -Days 14 -CsvPath .\DLPCLOUD-Matches.csv
    ```
    (Reads Cloud-Apps alerts via the Graph security API; with an MDCA API token it also pulls file-policy
    matches and activities.)
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. a built-in *Credit Card* SIT firing on internal reference numbers; a label filter that is too broad).
15. **Tune** to reduce false positives without losing true positives:
    - Raise the SIT **confidence level** and/or **instance count** in the content filter.
    - Narrow the **app / folder / sharing-level** filter so the policy targets the real exposure.
    - Match on a **sensitivity label** instead of a broad SIT where the label is more precise.
    - Add **exclusions** (specific owner/site/service account) where justified.
16. **Re-measure** after each change. Repeat until the false-positive rate meets the validation gate
    (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the test sample, with
true positives still detected.
**Rollback:** revert the last tuning change (the policy is still non-enforcing).

---

## Phase 5 — Enforce on the pilot ring (Pilot)

Now turn on enforcement **for the ring only**, one action at a time.

17. **File policy → add governance actions.** On `MDCA – SaaS Files PII – File Policy`, enable the intended
    enforcing action per compliance's determination — start with **Remove external/public sharing** or
    **Apply sensitivity label** (reversible); reserve **Put in quarantine** / **Trash** for where required.
    Keep the file scope to the pilot ring's apps/sites.
18. **Session policy → enforce.** Move `MDCA – Download Protect PII – Session Policy` from **Monitor only** to
    **Block** (block download) or **Protect** (apply label/encryption on download). Move the **Entra CA
    policy** `MDCA – CA App Control – Session Routing` from **report-only** to **On** — for the pilot ring
    only (all other users still excluded).
19. **Confirm enforcement is live** for the ring only: a ring user's real-time download of matching content
    is now blocked/protected, and a matching at-rest file has its sharing removed / label applied. Users
    outside the ring are unaffected.
20. **Handle incidents.** Wire `MDCA Alerts – Triage – Operations`: assign the alert owner/queue (Req 2.7),
    set severities, and (optionally) forward to SIEM/Sentinel. Triage a real pilot alert end-to-end to prove
    the workflow.

**Pass/fail gate:** the ring is enforced (real-time block/protect + at-rest governance), matches raise
alerts, the triage workflow produces a dispositioned incident, and nothing outside the ring is enforced.
**Rollback:** set the CA policy back to **report-only** / session policy back to **Monitor only** (instant,
no data change); disable the file-policy governance actions. *Note: a label/quarantine/trash already applied
at rest may need manual reversal — see Troubleshooting.*

---

## Phase 6 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population: broaden the **CA policy assignment**
    (session) and the **file-policy app/site filter** (at rest), keeping documented exclusions.
22. **Escalate the action** per compliance's determination — e.g. file policy from *remove sharing* to
    *quarantine*, or session from *protect* to *block* — one app/category at a time, re-validating after each.
23. **Add coverage** for more connected apps (file) and more CA-App-Control apps (session) as scope grows,
    repeating the test-mode → tune → enforce cycle for each.
24. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    session-policy blocks and file-governance actions, keep an eye on connector health and CA App Control
    coverage, and re-tune as apps and behavior change.
25. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended apps/users with the compliance-mandated action per
category; false-positive rate steady/low; alerts triaged on cadence.
**Rollback:** any CA/session policy can be returned to **report-only/Monitor** as an immediate,
non-destructive safety switch; file-policy governance actions can be disabled per policy without affecting
others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/planes | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Enable planes | Connect app connectors; create CA App Control policy (report-only) | App connector, CA policy | Both planes wired, CA report-only | Disconnect / CA off |
| 2 Detection | Confirm SITs/labels per category | (reuse Purview SIT/label) | Every category → detector | n/a |
| 3 Build (test) | File policy **alert-only**; session/access **Monitor only** | File/Session/Access policies | All non-enforcing, correct scope | Delete policy |
| 4 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 5 Pilot | Enforce ring: governance on, CA on, Block/Protect | Enforced ring policies | Ring enforced, incident dispositioned | Back to report-only/Monitor |
| 6 Expand | Broaden scope, escalate action, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Report-only / disable |
