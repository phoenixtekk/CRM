# 3. Implementation Guide — Financial / FINRA Communications Compliance (Microsoft Purview)

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Communication Compliance**) and, where automated, via **Security &
Compliance PowerShell** (`Connect-IPPSSession`; Communication Compliance is backed by the
`SupervisoryReview*` cmdlets, the evidence layer by the `RetentionCompliance*` cmdlets) and **Microsoft
Graph**. Artifact names follow the `FINRA <Purpose> – <Scope> – <Stage>` convention below and are reused
verbatim by the scripts and tests. **Portal paths, cmdlets, and classifier availability are
plan-dependent and the portal evolves — verify against your tenant; some classifiers are in preview.**

> **Model:** Establish **role separation + supervised scope + privacy first**, design the policy from
> the firm's WSPs and lexicons, build it in **SIMULATION/TEST**, validate detection + the
> designated-principal review workflow + privacy + evidence, tune, then expand — and configure the
> **immutable retention evidence layer** under Compliance/Records approval.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
> **Outcomes and the retention/immutability decision are deferred to Compliance/Records/Legal and the
> firm's supervisory principals at every step** — this guide configures the mechanism, not the verdict.

### Named artifacts (created/used across the steps)
| Artifact | Name | Purpose |
|---|---|---|
| Supervised pilot group | `FINRA Supervised – Pilot` | The approved registered/covered persons in the pilot |
| Exclusion group | `FINRA Excluded – Privacy` | Anyone who must never be supervised |
| Reviewers group | `FINRA Principals – Pilot` | Designated supervisory principals (Analysts) |
| Keyword dictionary | `FINRA Lexicon – Conduct` | The firm's prohibited-conduct terms |
| Policy | `FINRA Supervision – Pilot – Simulation` | The supervisory-review policy (simulation-first) |
| Rule | `FINRA Conduct Rule – Pilot` | Classifiers/lexicon/conditions + sampling |
| Retention policy | `FINRA Comms Records – 17a-4` | Immutable evidence retention (evidence layer) |
| Evidence snapshots | `FINRA Supervision Roles – Evidence`, `FINRA Supervision Rollup – Evidence` | Separation + review-activity evidence |

---

## Step 1 — Confirm readiness and capture the baseline (Assess)
1. Confirm the **Communication Compliance** area is visible in the Purview portal (Requirement 2.1).
   **Verify the entitlement with Microsoft licensing — do not assume from visibility.** Note any
   regulated-conduct classifier shown as *preview*.
2. Run **`CCFIN-Discovery.ps1`** (read-only). It reports the readiness signals it can see: membership of
   each Communication Compliance role group (the **role-separation snapshot**,
   `FINRA Supervision Roles – Evidence`), any existing supervisory-review policies/rules, retention
   policies that already cover communications, and privacy/scope signals — flagging over-broad scope or
   collapsed separation.
3. **Pass/fail gate:** entitlement present, the four role groups exist, and you have a clear picture of
   current membership, policies, and retention coverage. **Do not proceed** until Compliance/Legal have
   approved the supervised population, the designated principals, the sampling rate, and the lawful
   basis (Requirements 2.2–2.4, 2.7). Fail → resolve before configuring.

## Step 2 — Configure privacy, role separation, and scope FIRST (Configure — guardrails)
1. Portal → `Settings → Communication Compliance` (Privacy): set the agreed **privacy option** — enable
   **pseudonymized usernames** in the review experience if Privacy/Legal require it (Requirement 2.7).
2. Portal → `Settings → Roles & scopes → Permissions`: populate the role groups **with separation**
   (Requirement 2.2):
   - **Communication Compliance Admin** → IT/program config staff who *build* policies.
   - **Communication Compliance Analysts** → the **designated supervisory principals** (`FINRA
     Principals – Pilot`) who *review* items.
   - **Communication Compliance Investigators** → the Compliance/Legal **escalation** handlers.
   - **Communication Compliance Viewers** → oversight (reports only, **no content**).
   Avoid the combined **Communication Compliance** role group outside a tiny pilot — it collapses
   separation.
3. Create/confirm the **supervised** group `FINRA Supervised – Pilot` (the **minimum approved**
   registered population) and the **exclusion** group `FINRA Excluded – Privacy` (Requirement 2.3).
4. **Pass/fail gate:** privacy setting matches Privacy/Legal's decision; role membership is separated (no
   one is silently both builder and reviewer, and **no reviewer supervises themselves**); the supervised
   and excluded groups exist and are approved. Re-run `CCFIN-Discovery.ps1` and confirm the snapshot
   reflects the intended separation. **Rollback:** remove any mistaken role-group membership — separation
   errors are corrected here, before any policy exists.

## Step 3 — Design the supervision policy from the WSPs and lexicons (Design)
1. With Compliance, translate the **WSP supervision section** (Requirement 2.4) into concrete detection:
   which **regulated-conduct trainable classifiers** to use — e.g. **Money laundering, Stock/market
   manipulation, Unauthorized disclosure, Regulatory collusion, Gifts & entertainment, Customer
   complaints** (*availability plan-dependent; some in preview — verify in your tenant*).
2. Capture the firm's prohibited-conduct terms as the **keyword dictionary (lexicon)** `FINRA Lexicon –
   Conduct` — guarantees/"can't lose", selling-away, undisclosed-outside-business, unregistered-activity,
   and complaint language the firm wants surfaced. **Compliance supplies the terms; do not invent them.**
3. Add any **sensitive information types** for data-leak detection (e.g. account/SSN patterns), and
   define **conditions** (direction, attachments, message size) and the **risk-based sampling
   percentage** from the WSPs.
4. Confirm the **channels** in scope (Teams / Exchange / Viva Engage / connected sources — Requirement
   2.5) and the **reviewers** (`FINRA Principals – Pilot`, from Analysts).
5. Record the design as `FINRA Supervision – Pilot – Simulation` with rule `FINRA Conduct Rule – Pilot`.

## Step 4 — Build the policy in SIMULATION/TEST (Configure — pilot-first)
1. Build the policy in the portal (**Communication Compliance → Policies → Create policy**) or with
   **`CCFIN-Configuration.ps1 -Commit`** (default is `-WhatIf` — it prints what it *would* create and
   changes nothing until you pass `-Commit`). The script uses the documented `New-SupervisoryReviewPolicyV2`
   / `New-SupervisoryReviewRule` cmdlets; **verify cmdlet availability in your tenant.**
2. Scope the policy to `FINRA Supervised – Pilot`, exclude `FINRA Excluded – Privacy`, assign reviewers
   `FINRA Principals – Pilot`, attach the classifiers, the `FINRA Lexicon – Conduct` dictionary, the
   sensitive info types, the conditions, and the sampling percentage — the **lexicons** pillar.
3. **Keep it in simulation/test / limited-pilot mode.** Do **not** expand scope beyond the pilot group
   yet. If simulation surfaces items, they are **for tuning only** — not yet a live supervisory review.
4. **Pass/fail gate:** the policy exists, is scoped to the pilot (not "everyone"), has the intended
   reviewers, classifiers, lexicon, conditions, and sampling, and is confined to the pilot. Confirm with
   `CCFIN-Validation.ps1`. **Rollback:** disable/delete `FINRA Supervision – Pilot – Simulation` via the
   portal or `CCFIN-Configuration.ps1 -Remove -Commit` — no supervised communications are affected.

## Step 5 — Validate detection with test communications (Pilot / Validate — lexicons)
1. From a **pilot user only**, send test communications that **should** match (sample language matching a
   selected classifier and/or a `FINRA Lexicon – Conduct` term) and ordinary communications that should
   **not**. Allow processing time.
2. Confirm matching items appear for `FINRA Supervision – Pilot – Simulation` and that clean messages do
   not — using the portal and `CCFIN-Report.ps1`.
3. **Pass/fail gate:** true positives surface; clean messages don't. **Fail** → tune the lexicon and
   classifier/condition selection (Step 8) — never widen scope to compensate.

## Step 6 — Exercise the designated-principal review workflow (Pilot / Validate — review)
1. As a **designated principal (Analyst)**, open a surfaced item, examine it **in context**, and apply a
   **remediation action**: **tag** (compliant / questionable / non-compliant), add a **note**, **resolve**,
   **notify**, or **escalate** to an **Investigator**. This is the Rule 3110 review mechanic.
2. As an **Investigator**, confirm an escalation arrives with context. As a **Viewer**, confirm you see
   **reports only, no message content**.
3. Confirm the **reviewer trail** (who reviewed what, when, with what disposition) is captured — the
   defensible-supervision evidence — via `CCFIN-Report.ps1` (`FINRA Supervision Rollup – Evidence`) and
   the unified audit log.
4. **Pass/fail gate:** a principal can triage end-to-end; escalation reaches an Investigator; a Viewer
   sees no content; the reviewer trail is recorded. **Fail** → correct role membership (Step 2).
   **Determination reminder:** tagging an item is a **supervisory-principal judgment**, not a technical
   result — the workflow records the judgment, it does not make it.

## Step 7 — Configure the immutable retention evidence layer (Configure — evidence)
1. **Only after Compliance/Records approve** the retention period and the immutability decision
   (Requirement 2.6), configure a retention policy `FINRA Comms Records – 17a-4` over the supervised
   communications (Exchange/Teams/Viva Engage as scoped), using **`RetentionCompliance*`** cmdlets or the
   portal (**Data Lifecycle Management / Records Management**). `CCFIN-EvidenceCheck.ps1` reports current
   coverage read-only.
2. Where the records decision requires **immutability**, apply **Preservation Lock**
   (`Set-RetentionCompliancePolicy -Identity 'FINRA Comms Records – 17a-4' -RestrictiveRetention $true`)
   — this makes the policy **tamper-evident and irreversible: it cannot be disabled, shortened, or
   deleted**, only made more inclusive.
   > ⚠️ **Preservation Lock is permanent.** Apply it **only** with explicit, written Compliance/Records
   > approval and after the schedule is confirmed. `CCFIN-EvidenceCheck.ps1` and `CCFIN-Configuration.ps1`
   > require **`-Commit`** *and* an explicit lock switch, and refuse to lock by default.
3. **Pass/fail gate:** the supervised communications are covered by retention for the approved period;
   where required, immutability is in effect and verified; review activity is captured in the audit log.
   **Rollback:** an **unlocked** retention policy can be adjusted/removed under change control; a
   **locked** one **cannot** — which is why the lock is gated on written approval.

## Step 8 — Tune, then expand under change control (Validate → Expand/enforce)
1. Using the pilot results, tune the **lexicon** and **classifier/condition** selection and the
   **sampling percentage** to reduce noise while preserving coverage — re-running Steps 5–6 after each
   change.
2. When Compliance signs off the pilot, **expand** the supervised scope from `FINRA Supervised – Pilot`
   toward the full approved registered population and move the policy from simulation to **active**
   supervision, in **rings** under change control. Rename/clone to `FINRA Supervision – Production`.
3. Confirm the evidence layer covers the expanded scope, and that reporting (`CCFIN-Report.ps1`) produces
   the supervision-activity rollup examiners expect.
4. **Pass/fail gate:** each expansion ring passes the same validation as the pilot; evidence retention
   tracks the scope; reporting is complete. **Rollback:** revert a ring by returning its policy to
   simulation / narrowing scope — **without** touching the (possibly locked) evidence retention.

---

## Rollback summary
| Step | Change | Rollback |
|---|---|---|
| 2 | Role/scope/privacy | Remove mistaken membership; reset privacy option (no policy exists yet) |
| 4 | Policy in simulation | Disable/delete `FINRA Supervision – Pilot – Simulation`; no comms affected |
| 5–6 | Lexicon/review tuning | Revert lexicon/classifier/sampling changes |
| 7 | Retention (unlocked) | Adjust/remove under change control |
| 7 | Retention (**locked**) | **Not reversible** — gated on written Compliance/Records approval |
| 8 | Expansion ring | Return ring to simulation / narrow scope; leave evidence retention intact |

*Every step defers the **verdict** (is this a violation? what action?) and the **records decision**
(period, immutability) to the firm's supervisory principals, Compliance, Records, and Legal. This guide
delivers the configured, piloted, validated **mechanism and evidence** — not the determination.*
