# 3. Implementation Guide — Mandatory vs Recommended Labeling Policy Design

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and **Security & Compliance PowerShell** (`Connect-IPPSSession`).
Every write is run `-WhatIf` first, and every behaviour is **piloted on a policy scoped to the pilot
ring** before it touches the broad policy — label-policy settings have **no simulation mode**, so the
pilot ring is the safety mechanism. Artifact names follow the convention from the Overview and are
reused verbatim. Portal paths are current at authoring — **verify in your tenant**, as the portal is
evolving; where an advanced-setting key is version-sensitive it is flagged.

> **Model:** Assess the posture → design the mandatory-vs-recommended matrix → configure on the
> **pilot policy** (`-WhatIf` → commit) → validate friction + effective settings → **expand** to the
> broad policy → validate. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
>
> **Determination deferral:** which populations are mandated, the default classification, and the
> downgrade rule are **governance determinations** — confirm each before enforcing (see §2).

## Step 1 — Assess the current label-policy posture (Assess)
1. Run `IPMANREC-Discovery.ps1` (read-only). It inventories existing **label policies** (`Get-LabelPolicy`), each policy's **advanced settings** (`Mandatory`, `DisableMandatoryInOutlook`, `OutlookDefaultLabel`, default-label configuration), the policy **scope** (which groups/locations it targets), and each **label's auto-labeling for Office apps** mode (Automatic vs Recommend) via `Get-Label`.
2. Review the output: is any policy already mandating labels? Is a default label already set? Do any labels already recommend themselves? This is your baseline — **do not** create conflicting settings across overlapping policies.
3. **Gate:** you have a written baseline of every label policy, its advanced settings, its scope, and each label's recommend/automatic state, and you have confirmed no conflicting mandatory/default settings across policies that both target the same users.

## Step 2 — Design the mandatory-vs-recommended matrix (Design)
1. With your governance owners, finalise the decision matrix from the Overview: **which populations are mandated** (documents and/or Outlook), the **default label** (§2.6 — commonly `General`, non-encrypting), whether **downgrade justification** is required, and **which labels recommend** themselves (with the prompt message).
2. Confirm the pilot ring (the group backing `LabelPolicy – Pilot – Ring1`) and the per-app friction decision (§2.7 — documents mandatory, Outlook relaxed is the common starting point).
3. **Gate:** a signed-off matrix exists — populations, mandatory scope, default label, downgrade rule, recommended labels + prompt text — before any policy setting is changed.

## Step 3 — Create (or select) the pilot label policy (Configure)
1. If a policy scoped to the pilot ring does not already exist, create it: `IPMANREC-PolicyConfig.ps1 -CreatePilotPolicy -PolicyName "LabelPolicy – Pilot – Ring1" -PilotGroup "grp-labeling-pilot@contoso.com" -WhatIf`, review the `New-LabelPolicy` it would run, then re-run with `-Commit`. (If the pilot ring is already covered by an existing policy, use that policy's name instead and skip creation.)
2. Confirm in Purview → **Information Protection → Label policies** that the policy publishes the intended labels to the pilot group only.
3. **Gate:** a label policy targeting **only** the pilot ring exists and publishes the intended labels; non-pilot users are unaffected. Rollback: `Remove-LabelPolicy "LabelPolicy – Pilot – Ring1"`.

## Step 4 — Set the default label on the pilot policy (Configure, -WhatIf first)
1. Run `IPMANREC-PolicyConfig.ps1 -SetDefault -PolicyName "LabelPolicy – Pilot – Ring1" -DefaultLabel "General" -WhatIf`. It shows how it would set the policy's **default label** for documents/email (and, via `OutlookDefaultLabel`, the Outlook default) — **without making changes**. Confirm `General` is **non-encrypting** (§2.6).
2. Re-run with `-Commit`. In the portal, the policy's **Policy settings** page now shows a default label; new documents/email for pilot users start at `General`.
3. **Gate:** `Get-LabelPolicy "LabelPolicy – Pilot – Ring1"` shows the default-label setting; a pilot user's new document defaults to `General` (allow client sync time).

## Step 5 — Enable mandatory labeling on the pilot policy (Configure, -WhatIf first)
1. Decide the per-app scope (§2.7). Run `IPMANREC-PolicyConfig.ps1 -SetMandatory -PolicyName "LabelPolicy – Pilot – Ring1" -RelaxOutlook -WhatIf`. It shows the advanced settings it would apply: `Mandatory = "true"` (require a label) and, with `-RelaxOutlook`, `DisableMandatoryInOutlook = "true"` (do not block email send). **No changes are made in `-WhatIf`.**
2. Re-run with `-Commit`. Pilot users are now prompted to apply a label before saving a document (and, unless relaxed, before sending email).
3. **Gate:** a pilot user is prompted for a label on save in Word/Excel/PowerPoint; if `-RelaxOutlook` was used, email send is **not** blocked. Rollback: re-run with `-DisableMandatory -Commit` to remove the requirement.

## Step 6 — Require downgrade justification on the pilot policy (Configure, -WhatIf first)
1. Run `IPMANREC-PolicyConfig.ps1 -SetDowngradeJustification -PolicyName "LabelPolicy – Pilot – Ring1" -WhatIf`, review, then `-Commit`. This turns on the policy setting requiring a **justification when a user removes a label or lowers its classification**. (In the portal this is the **Policy settings → "Users must provide justification…"** toggle — **verify the exact advanced-setting key in your tenant**; the script flags it.)
2. **Gate:** a pilot user who lowers a label (e.g. `Confidential` → `General`) or removes it is prompted for a justification, and the choice is recorded (visible later in audit).

## Step 7 — Configure recommended-label prompts on the label (Configure, -WhatIf first)
1. Recommended labeling is set on the **label**, not the policy. Run `IPMANREC-PolicyConfig.ps1 -SetRecommend -LabelName "Confidential \ All Employees" -PromptText "This content looks sensitive — apply Confidential to protect it." -WhatIf`. It shows how it would set the label's **auto-labeling for Office apps** to **Recommend** (not Automatic) with the policy-tip message, keyed to the label's conditions. Review, then `-Commit`.
2. In the portal (**Information Protection → Sensitivity labels → [label] → Auto-labeling for Office apps**) confirm the mode is **Recommend** and the user message is set. **Verify your licensing/tenant** — advanced condition types are E5-tier (§2.2).
3. **Gate:** a pilot user editing content that matches the label's conditions sees a **recommend** prompt with the message and can **accept or dismiss** it (it does not force-apply).

## Step 8 — Validate friction and effective settings on the pilot (Validate)
1. Run `IPMANREC-Validation.ps1 -PolicyName "LabelPolicy – Pilot – Ring1"` (read-only). It confirms the policy's **effective** advanced settings match the design: mandatory on, default = `General`, downgrade justification on, Outlook relaxed if intended, and the recommend label's mode.
2. Complete the **Testing Guide (§5)** on the pilot ring and gather pilot feedback (ticket volume, send-blocking complaints, mislabel rate).
3. **Gate:** effective settings match the matrix; pilot friction is acceptable to the governance owner. **Do not expand** until this gate passes — this is the equivalent of a simulation sign-off.

## Step 9 — Expand the settings to the broad policy (Expand)
1. Apply the **same, signed-off** settings to the broad policy: run each `IPMANREC-PolicyConfig.ps1` mode from Steps 4–6 again with `-PolicyName "LabelPolicy – Broad – AllUsers"` (`-WhatIf` first, then `-Commit`). Recommended-label settings (Step 7) are on the label and already apply everywhere the label is published — no repeat needed.
2. If pilot feedback showed Outlook mandatory was too disruptive, keep Outlook relaxed broadly (`-RelaxOutlook`); tighten later only if adoption data supports it.
3. **Gate:** the broad policy's effective settings match the pilot's accepted design (`IPMANREC-Validation.ps1 -PolicyName "LabelPolicy – Broad – AllUsers"`); a rollback command is documented per setting.

## Step 10 — Produce the posture evidence and operate (Validate → Operate)
1. Run `IPMANREC-Reporting.ps1 -CsvFolder <path>` to export the **mandatory-vs-recommended posture matrix** (which policies mandate, the default label per policy, downgrade state, which labels recommend) as evidence for the governance owner.
2. Run `IPMANREC-Health.ps1` on a cadence to catch **conflicting settings across overlapping policies**, inconsistent default labels, or a pilot policy left mandating after the ring dissolved.
3. **Gate:** the posture report matches the signed-off matrix; no policy conflicts flagged; the rollout is documented and reversible.

---
### Order of operations
`Assess posture → Design matrix → Create/select pilot policy → Set default label → Enable mandatory (per-app) → Require downgrade justification → Configure recommend prompts on labels → Validate friction on pilot → Expand to broad policy → Report + operate`
