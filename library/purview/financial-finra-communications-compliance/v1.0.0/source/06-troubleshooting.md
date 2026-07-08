# 6. Troubleshooting Guide — Financial / FINRA Communications Compliance (Microsoft Purview)

Issues are grouped by symptom. Each gives the **likely cause** and **what to do**. Purview features are
**licensing-/plan-dependent and some are in preview**, and the portal evolves — where a path/cmdlet
isn't where this guide says, **verify against your current tenant.** None of these fixes changes who owns
the **determination**: the verdict on a communication and the retention/immutability decision remain with
the firm's supervisory principals, Compliance, Records, and Legal.

---

## A. Entitlement, portal, and classifiers

**Communication Compliance area isn't visible / policies won't create.**
- *Cause:* Missing entitlement (E5 / E5 Compliance) or insufficient role (Requirements 2.1–2.2).
- *Do:* Confirm the entitlement with Microsoft licensing (not just portal visibility); confirm you hold
  a Communication Compliance role. Assign licensing/role under change control, then retry.

**A regulated-conduct classifier isn't available to select.**
- *Cause:* Classifier is plan-gated or **in preview** in your tenant, or not yet provisioned.
- *Do:* Verify the specific classifier's availability for your licensing; treat *preview* classifiers as
  a Compliance risk decision before relying on them. Proceed with the available classifiers plus the
  `FINRA Lexicon – Conduct` dictionary and revisit when the classifier is GA.

**`Get-SupervisoryReviewPolicyV2` / `New-SupervisoryReviewRule` not recognized.**
- *Cause:* Not connected to Security & Compliance PowerShell, wrong module, or the cmdlet set differs in
  your tenant version.
- *Do:* `Connect-IPPSSession` with a modern-auth admin (GR §3). If a cmdlet/parameter name differs,
  complete that step in the portal and use the scripts for the read-only checks — cmdlet surface for
  Communication Compliance varies by tenant; **verify, don't assume.**

## B. Role separation

**`CCFIN-Discovery.ps1` warns an identity is both builder and reviewer.**
- *Cause:* Someone is in **Communication Compliance Admin** *and* **Analysts/Investigators**, or the
  combined **Communication Compliance** role group is in use (Requirement 2.2).
- *Do:* Remove the overlapping membership (Implementation Step 2) unless Compliance/Legal explicitly
  accepted it. Never let a reviewer supervise themselves. Re-run Discovery to confirm the snapshot.

**Reviewers can't open items / see the review queue.**
- *Cause:* The designated principals aren't in **Communication Compliance Analysts**, or aren't assigned
  as the policy's reviewers.
- *Do:* Add them to Analysts and set them as reviewers on the policy (Steps 2, 4). Confirm with
  `CCFIN-Validation.ps1` (“Policy has designated reviewers”).

**A Viewer can see message content.**
- *Cause:* The person is in a content-bearing role (Analyst/Investigator), not **Viewers**.
- *Do:* Correct role membership — Viewers get reports/dashboards only, no content (Step 6, Test 9).

## C. Scope and privacy

**`CCFIN-EvidenceCheck.ps1` flags scope as over-broad/empty.**
- *Cause:* The policy is scoped to "everyone" or has no supervised users (Requirement 2.3).
- *Do:* Scope to the approved `FINRA Supervised – Pilot` (registered population) and apply the
  `FINRA Excluded – Privacy` exclusion (Step 2). Scope is a Compliance determination — get it confirmed.

**Usernames aren't pseudonymized in review (privacy requirement).**
- *Cause:* The privacy option isn't set (Requirement 2.7).
- *Do:* `Settings → Communication Compliance` → enable pseudonymized usernames; don't run live without
  Privacy/Legal sign-off on the lawful basis (Test 2).

## D. Detection (lexicons)

**A message that should match doesn't surface (false negative).**
- *Cause:* Classifier/lexicon/condition not attached, sampling too low, the channel isn't covered, or
  processing latency.
- *Do:* Allow processing time; confirm the classifier and `FINRA Lexicon – Conduct` are attached
  (`CCFIN-Validation.ps1`, Test 4); raise the risk-based sampling if the WSPs allow; verify the channel
  (Test 7). Don't widen the *population* to compensate.

**Clean messages surface constantly (false positives / reviewer overload).**
- *Cause:* Lexicon too broad, classifier too aggressive, sampling too high.
- *Do:* Tune the lexicon terms and conditions and right-size sampling to reviewer capacity
  (Implementation Step 8); re-run Tests 5–6 after each change. Keep the lexicon Compliance-owned.

**A channel registered persons use (e.g. text/IM) isn't monitored.**
- *Cause:* The data connector for that source isn't configured/healthy (Requirement 2.5).
- *Do:* `Data connectors` → stand up/repair the connector and confirm data is flowing before treating
  that channel as supervised. An omitted channel is a known examination finding.

## E. Review workflow

**No review activity / reviewer trail appears in `CCFIN-Report.ps1`.**
- *Cause:* No items yet (fresh pilot), auditing not enabled, or `Get-SupervisoryReviewActivity`
  unavailable in your tenant.
- *Do:* Generate a pilot test item (Test 5); confirm unified auditing is on; if the activity cmdlet is
  unavailable, use `Search-UnifiedAuditLog -RecordType ComplianceSupervisionExchange` and the portal
  Reports (the report script prints this fallback).

**Escalation to an Investigator doesn't arrive.**
- *Cause:* No one in **Communication Compliance Investigators**, or escalation not configured.
- *Do:* Populate Investigators and confirm the escalation action (Step 6, Test 8).

**Review backlog is growing.**
- *Cause:* Sampling exceeds reviewer capacity, or too few designated principals.
- *Do:* Right-size sampling to the WSP-defined capacity and/or add principals; a backlog of unreviewed
  items is a supervision gap (Best Practices → Review workflow).

## F. Evidence (retention / immutability)

**`CCFIN-EvidenceCheck.ps1` reports no evidence-retention policy.**
- *Cause:* The evidence layer isn't configured (Requirement 2.6, Step 7).
- *Do:* Create `FINRA Comms Records – 17a-4` over the supervised comms with the **Compliance/Records-
  approved** period. Do not lock yet.

**Immutability required but retention isn't locked.**
- *Cause:* Preservation Lock not applied.
- *Do:* Apply the lock **only** with written Compliance/Records approval:
  `Set-RetentionCompliancePolicy -Identity 'FINRA Comms Records – 17a-4' -RestrictiveRetention $true`
  (or `CCFIN-Configuration.ps1 -ConfigureRetention -ApplyPreservationLock -Commit`). **It is
  irreversible** — a locked policy can only be broadened, never shortened, disabled, or deleted.

**We locked the wrong policy / need to shorten a locked policy.**
- *Cause:* Preservation Lock was applied prematurely.
- *Do:* You **cannot** reverse it. This is why the lock is gated on written approval and the scripts
  refuse to lock by default. Escalate to Compliance/Records/Legal; the only forward path is to broaden
  or supersede, not shorten.

**Detection scope expanded but evidence retention didn't follow.**
- *Cause:* Retention scope wasn't extended when supervision expanded (Step 8).
- *Do:* Extend the evidence retention to match the new supervised scope under Compliance/Records
  approval — supervising a channel you don't preserve is a recordkeeping gap.

---

### When to stop and escalate
- Any question of **whether a communication is a violation**, **which rule applies**, the **retention
  period**, or **whether to apply an irreversible lock** → stop and route to the firm's designated
  supervisory principals, Compliance, Records, or Legal. These are **determinations**, not technical
  fixes. This solution provides the method and the evidence; the verdict and the records decision are
  theirs.
