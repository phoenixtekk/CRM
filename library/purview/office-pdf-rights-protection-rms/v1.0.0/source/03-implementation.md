# 3. Implementation Guide — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

Follow these steps in order. This guide assesses RMS activation and the current label-encryption
posture, designs the protection labels and usage rights, configures each label's encryption on a
**pilot label policy scoped to a pilot ring** (encryption stays unpublished until validated), validates
that the right people can open Office and PDF files and the wrong people cannot, then expands. Artifact
names are fixed — create them with the exact names in §1 and reuse them everywhere. **Encryption has no
service-side simulation, so the pilot ring is the safety gate.** Every write via the config helper
defaults to `-WhatIf`; add `-Commit` to apply.

> Model: prove RMS activation, the grants, offline/expiry, and Office+PDF behaviour on a pilot ring,
> then expand. **Assess → Design → Configure → Pilot → Validate → Expand.** Verify current portal paths,
> licensing, cmdlet/advanced-setting keys, and PDF-reader support for your tenant as you go — the portal
> and PDF handling evolve; nothing here is invented.

## Step 1 — Assess current state (read-only)
1. Run `IPRMS-Discovery.ps1`. It reports the **RMS/Rights Management service state** (activated?), which
   labels already have **encryption enabled** and their **protection type** (template vs user-defined),
   the **usage rights** each defines, offline-access and content-expiry values, whether a **super-user
   group** is configured, and the Exchange **IRM** state. No changes are made.
2. In the Purview portal (**Information Protection → Sensitivity labels**) confirm the taxonomy exists
   and note which labels are candidates for protection.
3. Record gaps against the Requirements checklist. Do **not** proceed past: RMS not activated, missing
   Information Protection role, missing labels, or no pilot ring/super-user decision — remediate first.

## Step 2 — Confirm RMS activation and the recovery (super-user) path
1. Confirm the Rights Management service is **Activated** (`Get-AipServiceConfiguration`; Req 2.5). If it
   is not, activate it (`Enable-AipService`) under change control before continuing.
2. Confirm the **super-user group** decision (Req 2.8). Enable super-user and set the group so records/
   legal can always recover protected content: `Enable-AipServiceSuperUserFeature`, then
   `Set-AipServiceSuperUserGroup -GroupEmailAddress "grp-rms-superusers@contoso.com"`. **Pass/fail:**
   `Get-AipServiceSuperUserGroup` returns the group. **Do this before broad publish** — encrypted content
   is unrecoverable without it.

## Step 3 — Design the protection labels and usage rights
1. Confirm, with the accountable owner, the per-label grants from §1: `Confidential \ All Employees`
   (template — all org users, Co-Author), `Confidential \ Recipients Only` (user-defined — DNF/
   Encrypt-Only), `Highly Confidential \ Named Recipients` (template — the named group, Viewer only).
2. Decide **offline-access days** and **content-expiry** per label (e.g. offline 7 days for the
   restricted label, Never-expire for the internal one) — these are governance decisions (Req 2.8).
3. Confirm the **named-recipient group** (`grp-rms-named-recipients@contoso.com`) exists and is correct.

## Step 4 — Prepare the pilot label policy (encryption unpublished)
1. If a policy scoped to the pilot ring does not exist, create it: `IPRMS-LabelProtection.ps1
   -CreatePilotPolicy -PolicyName "RMSPolicy – Pilot – Ring1" -PilotGroup "grp-rms-pilot@contoso.com"
   -WhatIf`, review, then `-Commit`. Do **not** add the encryption labels to a broadly-published policy
   yet — configure encryption on the labels first (Steps 5–7), validate on the pilot, then publish.

## Step 5 — Configure the template (assigned-rights) label — `Confidential \ All Employees`
1. Run `IPRMS-LabelProtection.ps1 -SetTemplate -LabelName "Confidential\All Employees"
   -RightsIdentity "AuthenticatedUsers" -Rights "VIEW,EDIT,PRINT,EXTRACT,DOCEDIT,OBJMODEL"
   -OfflineDays 30 -Expiry Never -WhatIf`. It shows the `Set-Label -EncryptionEnabled $true
   -EncryptionProtectionType Template -EncryptionRightsDefinitions …` it would apply — **without making
   changes**. Review the rights, then re-run with `-Commit`.
2. **Pass/fail:** `Get-Label "Confidential\All Employees"` shows `EncryptionEnabled = True`,
   protection type **Template**, and the rights definition for the org audience. **Rollback:** re-run
   with `-RemoveProtection -Commit` (sets `EncryptionProtectionType RemoveProtection`).

## Step 6 — Configure the user-defined label — `Confidential \ Recipients Only`
1. Run `IPRMS-LabelProtection.ps1 -SetUserDefined -LabelName "Confidential\Recipients Only"
   -DoNotForward -EncryptOnly -WhatIf`. It shows how it would set the label to **user-defined**
   permissions (`EncryptionProtectionType UserDefined`) with **Do Not Forward** for mail and
   **Encrypt-Only** prompting for files — the user chooses recipients at protect time. Review, then
   `-Commit`.
2. **Pass/fail:** the label shows protection type **UserDefined** with DNF/encrypt-only behaviour.
   **Rollback:** `-RemoveProtection -Commit`.

## Step 7 — Configure the named-recipient label — `Highly Confidential \ Named Recipients`
1. Run `IPRMS-LabelProtection.ps1 -SetTemplate -LabelName "Highly Confidential\Named Recipients"
   -RightsIdentity "grp-rms-named-recipients@contoso.com" -Rights "VIEW,VIEWRIGHTSDATA" -OfflineDays 7
   -Expiry Never -WhatIf`, review, then `-Commit`. This grants **Viewer-only** rights (view, no print/
   copy/edit) to the named group and nobody else.
2. **Pass/fail:** the label shows Template protection with the restricted rights for the named group
   only. **Rollback:** `-RemoveProtection -Commit`.

## Step 8 — Publish the protection labels to the pilot ring only
1. Add the three configured labels to `RMSPolicy – Pilot – Ring1` (portal **Label policies → edit →
   Labels**, or `IPRMS-LabelProtection.ps1 -PublishToPolicy -PolicyName "RMSPolicy – Pilot – Ring1"
   -Labels "Confidential\All Employees","Confidential\Recipients Only","Highly Confidential\Named
   Recipients" -Commit`). Confirm the policy publishes **only** to `grp-rms-pilot@contoso.com`.
2. Confirm Exchange **IRM** is enabled (Req 2.6) so DNF/Encrypt-Only work in Outlook, and confirm PDF
   handling for the pilot.

## Step 9 — Validate on the pilot (Office and PDF, right vs wrong recipient)
1. Run `IPRMS-Validation.ps1 -LabelName "Confidential\All Employees"` (read-only) to confirm the label's
   **effective** encryption settings match the design; repeat for the other two labels.
2. Complete the Testing Guide: as a pilot user, apply each label to an Office document and a **PDF
   export**, confirm an in-scope user can open with the intended rights, and confirm an out-of-scope
   user is **denied**; confirm DNF prevents forwarding; confirm a super-user can recover.
3. **Gate:** every label opens for the right people with the right rights, denies the wrong people, PDF
   protection is honored in a supported reader, and super-user recovery works — before expanding.

## Step 10 — Expand to the broad policy (enforce)
1. Add the **same, signed-off** labels to `RMSPolicy – Broad – AllUsers` (portal or
   `IPRMS-LabelProtection.ps1 -PublishToPolicy -PolicyName "RMSPolicy – Broad – AllUsers" -Labels … -WhatIf`
   then `-Commit`). The label **encryption settings are already on the labels** — expansion only widens
   *who the labels are published to*; no per-label re-configuration is needed.
2. **Gate:** re-validate a sample against the broad policy (`IPRMS-Validation.ps1`), confirm super-user
   recovery, and confirm a documented rollback (remove protection / unpublish) per label.

## Step 11 — Operate: evidence, recovery, and revocation
1. Run `IPRMS-Report.ps1 -CsvFolder <path>` to export the **protection posture matrix** (per label:
   encryption on/off, protection type, rights, offline days, expiry) plus RMS activation and super-user
   state — the evidence for the governance owner.
2. Run `IPRMS-Readiness.ps1` on a cadence to catch **RMS deactivation, IRM disabled, a missing super-user
   group, or a protection label left in the pilot policy after expansion**.
3. Document the **recovery** path (super-user) and the **revocation** path (`Get-AipServiceDocumentLog` /
   revoke where applicable — **verify current revocation tooling for your tenant**). Legal-hold and
   eDiscovery handling of encrypted content is a **legal/records determination** — this solution provides
   the super-user recovery method, not the legal decision.

---
### Order of operations
`Assess (RMS activated? posture) → Confirm activation + super-user recovery → Design labels/rights →
Prepare pilot policy → Configure template label → Configure user-defined label → Configure named-recipient
label → Publish to pilot ring → Validate (Office + PDF, right vs wrong, recovery) → Expand to broad →
Operate (evidence, recovery, revocation)`
