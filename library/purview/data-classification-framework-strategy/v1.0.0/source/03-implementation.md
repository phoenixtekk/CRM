# 3. Implementation Guide — Data Classification Framework & Strategy

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and **Security & Compliance PowerShell** (`Connect-IPPSSession`).
Every write is run `-WhatIf` first, every high-impact policy is **piloted in a small ring**, and the
**tier-aligned DLP baseline is created in *test* mode** before it is ever enforced. Artifact names
follow the `CLS <Type> – <Scope> – <Stage>` convention (and the tier names) from the Overview and are
reused verbatim. Portal paths are current at authoring — **verify in your tenant**, as the portal is
evolving.

> **Model:** Assess the posture, design the tier model + crosswalk (the standard), build the reference
> implementation (tier labels; DLP baseline in **test**; retention labels), pilot to a ring, validate
> the tiers map coherently, then **expand and enforce.** Pattern: **Assess → Design → Configure →
> Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Governance/records deferral:** the tier definitions, DLP enforcement decisions, and retention
> periods/actions below are **placeholders** — confirm each with the accountable owner before
> enforcing (see §2 deferral note).

## Step 1 — Assess the current classification posture (Assess)
1. Run `CLSFRAME-Discovery.ps1` (read-only). It inventories existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`), **DLP policies** and their **mode** (`Get-DlpCompliancePolicy`), and **retention labels** (`Get-ComplianceTag`) and **retention policies** (`Get-RetentionCompliancePolicy`) — then reports which of the four framework tiers already have an artifact in each control family.
2. Review the output: what already exists, whether any DLP is already enforced (not test), and whether encryption/retention is already in use. This is your baseline — **do not** duplicate or collide with existing artifacts.
3. **Gate:** you have a written baseline of every existing label/DLP/retention object and a first view of where the framework is already partially present (so you extend, not collide).

## Step 2 — Design the tier model and the crosswalk (Design)
1. With your governance owners, finalize the **tier model** (§2.4) — number of tiers, names, definitions, handling rules — using the four-tier model in the Overview as a starting point.
2. Fill in the **crosswalk**: for each tier, the sensitivity label, the DLP posture (and which sensitive info types trigger it, §2.5), and the retention treatment (period/action — records/legal sign-off). This crosswalk table **is** the classification standard's core.
3. Write the **classification standard document** (tier definitions + handling rules + crosswalk) and get it signed off.
4. **Gate:** a signed-off standard exists — tier definitions, handling rules, and a complete crosswalk (every tier has a label, a DLP posture, and a retention treatment) — before any artifact is created.

## Step 3 — Build the tier sensitivity labels (Configure, -WhatIf first)
1. Run `CLSFRAME-FrameworkConfig.ps1 -WhatIf` (the default). It prints exactly which tier labels it would create with `New-Label` — `Public` (marking only), `Internal` (footer marking), `Confidential` (encrypt), `Restricted` (encrypt + watermark) — in tier order, **without making changes**.
2. Review every line: confirm each encrypting label's rights definition targets the correct group (§2.7) and the label order matches the signed-off tier model.
3. Re-run `CLSFRAME-FrameworkConfig.ps1 -Commit` to create the labels. They exist but are **not yet published** — labels only appear once a policy publishes them (Step 4).
4. **Gate:** `Get-Label` shows the four tier labels with the intended protection; none is published yet.

## Step 4 — Publish the tier labels to the pilot ring (Pilot)
1. Run `CLSFRAME-FrameworkConfig.ps1 -PublishLabels -PolicyName "CLS Policy – Pilot – Ring1" -PilotGroup "<pilot-group>" -WhatIf`. It shows the `New-LabelPolicy` it would run — publishing the ordered tier label set to the pilot group only.
2. Re-run with `-Commit` to create `CLS Policy – Pilot – Ring1`.
3. In the Purview portal (**Information Protection → Label policies**) confirm the policy is published to the pilot group and the tier labels appear in Office for a pilot user (allow client sync time).
4. **Gate:** pilot users see the four tier labels in Word/Excel/PowerPoint/Outlook; an encrypting tier (`Confidential`/`Restricted`), applied by a pilot user, actually protects the file (open as an unauthorized user → access denied). Rollback: `Remove-LabelPolicy "CLS Policy – Pilot – Ring1"` unpublishes without deleting the labels.

## Step 5 — Build the tier-aligned DLP baseline **in test mode** (Configure / test)
1. Run `CLSFRAME-FrameworkConfig.ps1 -BuildDlp -DlpName "CLS DLP – Tier2-3 – Test" -WhatIf`. It shows the `New-DlpCompliancePolicy` **in test mode** (`-Mode TestWithNotifications`) plus the `New-DlpComplianceRule` conditions it would create — matching the Tier 2/3 sensitive info types (and/or the `Confidential`/`Restricted` labels) and restricting external sharing. **No user action is blocked in test mode.**
2. Review the conditions against the crosswalk (§2.5) — confirm the sensitive info types and the target locations (Exchange/SharePoint/OneDrive/Teams) are correct.
3. Re-run with `-Commit` to create the DLP policy **in test mode**. Policy tips and reports are generated; nothing is blocked yet.
4. **Gate:** `Get-DlpCompliancePolicy` shows `CLS DLP – Tier2-3 – Test` with `Mode` a **Test** value (never `Enable`). Rollback: `Set-DlpCompliancePolicy "CLS DLP – Tier2-3 – Test" -Mode Disable`.

## Step 6 — Build the tier-aligned retention labels (Configure, -WhatIf first)
1. Run `CLSFRAME-FrameworkConfig.ps1 -BuildRetention -WhatIf`. It shows the `New-ComplianceTag` calls for each tier retention label (`CLS Retain – Public/Internal/Confidential/Restricted`) — with the **period and action confirmed by records/legal** (§2 deferral).
2. Review each: retention action (Keep / Delete / Keep-and-Delete / disposition review), duration, and trigger (creation vs modification). **Do not** mark anything as a *record* unless records/legal has declared it so.
3. Re-run with `-Commit` to create the retention labels. They exist but are **not published** yet.
4. **Gate:** `Get-ComplianceTag` lists the four tier retention labels with the signed-off period/action; none is published.

## Step 7 — Publish retention labels to the pilot ring (Pilot)
1. Run `CLSFRAME-FrameworkConfig.ps1 -PublishRetention -PolicyName "CLS Retain Publish – Pilot – Ring1" -PilotGroup "<pilot-group>" -WhatIf`, review the `New-RetentionCompliancePolicy` + `New-RetentionComplianceRule -PublishComplianceTag`, then `-Commit`.
2. Confirm pilot users can apply the tier retention labels in Office/SharePoint/Outlook.
3. **Gate:** pilot users see and can apply the tier retention labels. For any tier with a **delete** action, confirm the disposition behavior in a controlled test item before broad reliance (see Testing §5). Rollback: `Remove-RetentionCompliancePolicy "CLS Retain Publish – Pilot – Ring1"` unpublishes without deleting the labels.

## Step 8 — Validate the crosswalk is coherent (Validate)
1. Run `CLSFRAME-Validation.ps1`. It checks, **per tier**, that the sensitivity label, the DLP posture, and the retention label all exist and are consistently named — i.e. every tier row in the crosswalk is fully implemented, with no orphan (a label with no retention, a DLP posture with no label, etc.).
2. Run `CLSFRAME-Crosswalk.ps1 -CsvPath .\crosswalk.csv` to export the **live** tier→label→DLP→retention crosswalk from the tenant and compare it to the signed-off standard.
3. **Gate:** the live crosswalk matches the standard — every tier has its label (published to pilot), its DLP posture (in **test**), and its retention label (published to pilot); no orphans; the DLP baseline is still in test mode. Do **not** enforce until this gate passes.

## Step 9 — Measure classification coverage (Validate)
1. Run `CLSFRAME-Coverage.ps1` to report health of the framework artifacts and, where licensed, pull **labeling activity** (`Export-ActivityExplorerData`) to see how content is being classified per tier. **Activity/content explorer is E5-tier — verify your licensing/tenant.**
2. Review whether pilot content is landing in sensible tiers and whether the DLP test policy is generating the expected match reports.
3. **Gate:** the pilot shows content classifying into the tiers as designed and the DLP test policy is matching Tier 2/3 content as expected — evidence the scheme works before enforcing.

## Step 10 — Expand and enforce (Expand)
1. Complete the **Testing Guide (§5)**. Only after every gate passes: re-publish the labels from `CLS Policy – Pilot – Ring1` to `CLS Policy – Broad – AllUsers` (`CLSFRAME-FrameworkConfig.ps1 -PublishLabels -PolicyName "CLS Policy – Broad – AllUsers" -AllUsers -WhatIf` → `-Commit`).
2. **Enforce the DLP baseline** only once its test-mode match reports are accepted by the data owner: `CLSFRAME-FrameworkConfig.ps1 -BuildDlp -DlpName "CLS DLP – Tier2-3 – Test" -EnforceFromTest -WhatIf`, review, then `-Commit` (flips `-Mode` from a Test value to `Enable`).
3. Widen the retention publish scope as agreed with records/legal (a deep retention schedule is a separate engagement).
4. **Gate:** all §5 tests pass; broad label publish confirmed; DLP enforced only after accepted test reports; a rollback path is documented for each policy.

---
### Order of operations
`Assess posture → Design tier model + crosswalk (standard) → Build tier labels (-WhatIf → commit) → Publish to pilot ring → Build DLP baseline in TEST → Build retention labels → Publish retention (pilot) → Validate crosswalk coherence → Measure coverage → Expand labels broadly + enforce DLP from test`
