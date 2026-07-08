# 3. Implementation Guide — Microsoft Purview Communication Compliance

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Communication Compliance**) and, where automated, via **Security &
Compliance PowerShell** (`Connect-IPPSSession`; the `SupervisoryReview*` cmdlets back Communication
Compliance) and **Microsoft Graph**. Artifact names follow the `<Purpose> – <Scope> – <Stage>`
convention from the Overview and are reused verbatim. **Portal paths and cmdlets are plan-dependent and
the portal evolves — verify against your tenant.**

> **Model:** Configure the **privacy + role-separation guardrails first**, design the policy, build it
> in a **pilot/simulation** scope, validate detection + reviewer workflow + privacy, tune, then expand.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
> **Outcomes are deferred to HR/legal at every step** — this guide configures the mechanism, not the
> verdict.

---

## Step 1 — Confirm readiness and capture the separation baseline (Assess)
1. Confirm licensing (Requirement 2.1): the **Communication Compliance** area is visible in the Purview
   portal. **Verify entitlement with Microsoft licensing — do not assume.**
2. Run `PURVCC-Discovery.ps1` (read-only). It reports the readiness signals it can see, the membership
   of each Communication Compliance role group (the **role-separation snapshot**,
   `Comms Role Separation – Evidence`), any existing `SupervisoryReview` policies/rules, and privacy/scope
   signals — and flags an over-broad scope or collapsed separation.
3. **Pass/fail gate:** licensing present, the four role groups exist, and you have a clear picture of
   current membership and any existing policies. **Do not proceed** until HR/legal have approved scope,
   reviewers, and the lawful basis (Requirement 2.3). Fail → resolve before configuring.

## Step 2 — Configure privacy and role separation FIRST (Configure — guardrails)
1. Portal → `Settings → Communication Compliance` (Privacy): set the agreed **privacy option** — if your
   privacy stakeholders require it, enable **pseudonymized/anonymized usernames** in the review
   experience (Requirement 2.4).
2. Portal → `Settings → Roles & scopes → Permissions`: populate the role groups with **separation**
   (Requirement 2.2):
   - **Communication Compliance Admin** → the program owners / IT config staff who *build* policies.
   - **Communication Compliance Analysts** → the agreed HR/compliance **reviewers** who triage alerts.
   - **Communication Compliance Investigators** → the compliance/legal **escalation** handlers.
   - **Communication Compliance Viewers** → oversight (reports only, no content).
   Avoid the combined **Communication Compliance** role group except for a tiny pilot; it collapses the
   separation.
3. Define the **exclusion group** `Comms Excluded – Privacy` for anyone who must never be monitored, and
   the pilot supervised group `Comms In-Scope – Pilot` (the **minimum** approved population).
4. **Pass/fail gate:** privacy setting matches the privacy stakeholders' decision; membership is
   separated (no one is silently both builder and reviewer unless HR/legal accepted it). Re-run
   `PURVCC-Discovery.ps1` and confirm the evidence snapshot reflects the intended separation.
   **Rollback:** remove any mistaken role-group membership; separation errors are corrected here before
   any policy exists.

## Step 3 — Design the pilot policy (Design)
1. With HR/compliance, decide the **detection intent** for the pilot: e.g. **offensive language /
   harassment** monitoring for a business unit, or **regulatory conduct** monitoring for a
   trading/advice desk, or **sensitive-data leak** detection.
2. Choose the **classifiers, sensitive info types, keywords, and conditions** (Requirement 2.6) and a
   **sampling percentage** appropriate to the review capacity.
3. Confirm the **channels** in scope (Teams / Exchange / Viva Engage / connected sources — Requirement
   2.5) and the **reviewers** (from the Analysts group) who will triage this policy's alerts.
4. Record the design as the policy `Comms Policy – Pilot – Simulation` with reviewers
   `Comms Reviewers – Pilot`.

## Step 4 — Build the pilot policy in SIMULATION/TEST (Configure — policy, pilot-first)
1. Preferred (portal): Communication Compliance → `Policies → Create policy` (a template such as
   *Detect inappropriate text* or a **custom** policy). Set:
   - **Users/groups to supervise** = `Comms In-Scope – Pilot`; **exclude** `Comms Excluded – Privacy`.
   - **Reviewers** = the approved Analysts (`Comms Reviewers – Pilot`).
   - **Channels** = the approved subset.
   - **Conditions** = the chosen classifiers / SITs / keyword dictionary / conditions and **sampling %**.
2. Or automate the create with `PURVCC-Configuration.ps1` — it composes the
   `New-SupervisoryReviewPolicyV2` + `New-SupervisoryReviewRule` call for `Comms Policy – Pilot –
   Simulation`. **It runs with `-WhatIf` by default** and prints exactly what it would create; add
   `-Commit` only after HR/legal sign-off to apply.
3. **Keep the pilot narrow.** Build it against `Comms In-Scope – Pilot` only, and treat the initial run
   as a **test/tuning** phase — you are validating detection and workflow, not enforcing outcomes.
4. **Pass/fail gate:** the policy exists, scoped to the pilot group, with the intended reviewers,
   classifiers/conditions, and the exclusion applied. Fail → correct scope/conditions.
   **Rollback:** disable or delete `Comms Policy – Pilot – Simulation`; because scope is the pilot group,
   blast radius is contained.

## Step 5 — Wire the reviewer workflow and remediation (Configure — workflow)
1. Confirm each pilot reviewer can open **Communication Compliance → Alerts** and see **only** this
   policy's alerts (their access is bounded by the Analysts role and the policy assignment). Use
   `PURVCC-ReviewerWorkflow.ps1` (`-WhatIf` default) to set/verify the policy's **reviewers** and the
   role-group membership that enforces separation; add `-Commit` to apply.
2. Agree the **remediation actions** reviewers will use in the portal on an alert: **resolve**, **tag**
   (compliant / questionable / non-compliant), **notify the user**, **escalate** to an Investigator, or
   **create/escalate to a case** (eDiscovery/legal). Configure any **notice templates** the workflow
   uses.
3. Document the **escalation path** to Investigators/legal and the **evidence** an escalation carries.
   **Remediation outcomes are HR/legal's determination** — reviewers surface and route; they do not
   adjudicate.
4. **Pass/fail gate:** a pilot reviewer can triage a test alert end-to-end (open → examine in context →
   tag/resolve/escalate) and an Investigator can receive an escalation; a Viewer sees reports but **no**
   content. Fail → fix role membership / reviewer assignment.

## Step 6 — Validate in the pilot (Pilot → Validate)
1. Generate representative test communications within the pilot group (e.g. sample messages that should
   and should not match) and let the policy process them.
2. Run the Testing Guide (`05-testing.md`). Confirm: matches raise **alerts**; reviewers can **action**
   them; **non-matching** messages don't alert (false-positive check); **privacy** controls are in
   effect (pseudonymization if enabled; excluded users not monitored); and **separation** holds
   (Viewers can't see content).
3. Run `PURVCC-Report.ps1` for the **alert/review rollup** (`Comms Review Rollup – Report`) and the
   separation evidence.
4. **Pass/fail gate:** detection is accurate enough to be useful, reviewers can work the queue, privacy
   and separation controls verified. Fail → **tune** (Step 7) and re-validate.

## Step 7 — Tune (Validate)
1. Reduce noise: adjust **classifiers/conditions**, tighten **keywords**, and set an appropriate
   **sampling percentage**; refine the in-scope population if too broad.
2. Use `PURVCC-Set-Scope.ps1` (`-WhatIf` default) to adjust the policy's scope/reviewers/conditions;
   `-Commit` to apply. Re-validate after each change.
3. **Pass/fail gate:** false positives are at a level reviewers can sustain and true violations are
   still caught. Iterate until the gate passes.

## Step 8 — Expand to the broad scope (Expand — enforce)
1. With HR/legal approval, create/clone the tuned policy as `Comms Policy – Broad – Enforce` scoped to
   `Comms In-Scope – Broad` (still excluding `Comms Excluded – Privacy`), with the production reviewer
   set. Use `PURVCC-Configuration.ps1 -Commit` or the portal.
2. **Expand deliberately** — widen scope in rings if the population is large, so review load and any
   privacy concerns scale gracefully.
3. Stand up the **maintenance cadence**: periodic review of scope, reviewers (joiners/leavers),
   classifiers, channels, and the separation evidence snapshot. Re-run `PURVCC-Report.ps1` on a schedule.
4. **Pass/fail gate:** broad policy detecting, production reviewers actioning, privacy + separation
   enforced, and a recurring review scheduled. **Rollback:** the broad policy can be disabled without
   touching the pilot; scope can be narrowed at any time.

---

### What this guide does NOT decide
- Whether a flagged message **is** a violation, and **what happens to the person** — an **HR/privacy/legal
  determination**. This guide configures detection, the reviewer workflow, and the guardrails, and
  produces the evidence; the verdict and any employment/regulatory action are made by those functions.
- **Regulatory applicability** (which conduct rules apply, retention of review records, legal hold on a
  case) — deferred to compliance/records/legal.
