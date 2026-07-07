# 3. Implementation Guide

Follow the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — for each of the
three Teams controls. Every artifact is **named** with the convention `<Purpose> – <Scope> – <Stage>`
and that exact name is reused in testing, troubleshooting, and the scripts. All PowerShell in this
guide runs against **Security & Compliance PowerShell** unless noted; connect once per session:

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser   # if missing
Connect-IPPSSession                                            # Government cloud: add the cloud-specific -ConnectionUri (verify in your tenant)
```

> **Determinations come from compliance/legal, not from here.** The example segment attributes,
> retention durations, and DLP content types below are **placeholders**. Substitute the written
> definitions your compliance, records, and legal owners provide (Requirements items 4, 7, 8).

---

## Stage 0 — Assess (read-only)
1. Run the assessment script to capture today's posture:
   `powershell -ExecutionPolicy Bypass -File .\TEAMSCOMP-Assessment.ps1`.
   It reports existing IB segments/policies and application status, retention policies that already
   touch the Teams locations, Teams-location DLP policies (with mode), and whether scoped directory
   search is enabled.
2. Confirm the Requirements Guide items — especially compliance licensing (item 1), roles (item 2),
   the segment attribute (item 4), scoped directory search (item 5), no conflicting ABPs (item 6), and
   the written determinations (item 8).
3. **Assess gate (pass/fail):** entitlement present, roles held, `Connect-IPPSSession` works, no
   conflicting ABP for the target populations, and written determinations in hand. **Fail → stop** and
   resolve before configuring.

## Stage 1 — Design (on paper)
1. From compliance's determinations, write down: the **segments** (name + defining attribute), the
   **block/allow** relationships between them, the Teams **retention** duration and end-of-life action,
   and the Teams **DLP** intent (which sensitive-information types/labels, audit vs block).
2. Fix the names now and reuse them everywhere:
   - `IB Segment – GroupA – Prod`, `IB Segment – GroupB – Prod`
   - `IB Policy – GroupA-blocks-GroupB – Pilot`
   - `Retention Policy – Teams Chat+Channel – Pilot` / rule `Retention Rule – Teams 7yr – Pilot`
   - `DLP Policy – Teams Sensitive – Pilot` / rule `DLP Rule – Teams PII – Pilot`
3. Define the **pilot scope**: for retention and DLP, a small pilot user/group set. For IB, arrange
   that **only pilot users carry the segment-defining attribute** initially (IB application is
   tenant-wide — see Stage 3A).

---

## Stage 2 — Configure Information Barriers

> Do the segment/policy creation with `-WhatIf` first (the config helper defaults to this). Creating
> segments and policies does **not** enforce anything — enforcement happens only at the **application**
> step in Stage 3A.

1. **Enable the IB prerequisites** (once): confirm **scoped directory search** is enabled in Teams
   (Requirements item 5) and that no conflicting ABP exists (item 6).
2. **Create the segments** from the compliance-defined attribute:
   ```powershell
   New-OrganizationSegment -Name "IB Segment – GroupA – Prod" -UserGroupFilter "Department -eq 'GroupA'"
   New-OrganizationSegment -Name "IB Segment – GroupB – Prod" -UserGroupFilter "Department -eq 'GroupB'"
   ```
   (`-UserGroupFilter` supports attributes such as `Department`, `MemberOf`, `Company` — use the one
   compliance specified.)
3. **Create the IB policy** that blocks communication between the two segments:
   ```powershell
   New-InformationBarrierPolicy -Name "IB Policy – GroupA-blocks-GroupB – Pilot" `
     -AssignedSegment "IB Segment – GroupA – Prod" `
     -SegmentsBlocked "IB Segment – GroupB – Prod" -State Inactive
   ```
   Create it **Inactive** first; review, then set it Active:
   ```powershell
   Set-InformationBarrierPolicy -Identity "IB Policy – GroupA-blocks-GroupB – Pilot" -State Active
   ```
   (Use `-SegmentsAllowed` instead of `-SegmentsBlocked` if compliance defined an *allow*-list model.
   A segment can be governed by one policy; verify the block/allow direction in your definition.)
4. **Config gate:** `Get-InformationBarrierPolicy` shows the policy **Active**; `Get-OrganizationSegment`
   shows both segments. **No barriers are enforced yet** — that is Stage 3A.

## Stage 2 — Configure Teams Retention

> Teams locations must live in a retention policy of their **own** — a single policy cannot mix the
> Teams locations with Exchange/SharePoint locations.

1. **Create the Teams retention policy** scoped to Teams chat and channel messages:
   ```powershell
   New-RetentionCompliancePolicy -Name "Retention Policy – Teams Chat+Channel – Pilot" `
     -TeamsChatLocation "pilotgroup@contoso.com" -TeamsChannelLocation "Pilot Team" -WhatIf
   ```
   Use `-TeamsChatLocation All` / `-TeamsChannelLocation All` only when expanding tenant-wide. For
   private/shared channels add `-TeamsPrivateChannelLocation` / `-TeamsSharedChannelLocation` per your
   determination (**verify parameter availability in your tenant** — channel-type coverage is
   version-dependent).
2. **Create the retention rule** with the compliance-defined duration and action:
   ```powershell
   New-RetentionComplianceRule -Name "Retention Rule – Teams 7yr – Pilot" `
     -Policy "Retention Policy – Teams Chat+Channel – Pilot" `
     -RetentionDuration 2555 -RetentionComplianceAction KeepAndDelete
   ```
   (`-RetentionComplianceAction` = `Keep` (retain-only), `KeepAndDelete` (retain then delete), or
   `Delete` (delete-only). Duration is in days or `Unlimited`. **The duration and action are
   compliance's determination.**)
3. **Config gate:** `Get-RetentionCompliancePolicy -Identity "Retention Policy – Teams Chat+Channel – Pilot"`
   shows **Enabled**; the rule shows the expected duration/action. Remove `-WhatIf` (or run the config
   helper with `-Commit`) to apply.

## Stage 2 — Configure Teams DLP (in test mode)

1. **Create the Teams DLP policy in test mode** (audit, no user impact):
   ```powershell
   New-DlpCompliancePolicy -Name "DLP Policy – Teams Sensitive – Pilot" `
     -TeamsLocation "pilotgroup@contoso.com" -Mode TestWithoutNotifications -WhatIf
   ```
   (`-Mode` values: `TestWithoutNotifications` and `TestWithNotifications` for the audit gate,
   `Enable` to enforce, `Disable` to turn off. Scope `-TeamsLocation All` only when expanding.)
2. **Create the DLP rule** referencing the org's approved sensitive-information types (reuse existing
   Purview SITs/labels — Requirements item 7):
   ```powershell
   New-DlpComplianceRule -Name "DLP Rule – Teams PII – Pilot" `
     -Policy "DLP Policy – Teams Sensitive – Pilot" `
     -ContentContainsSensitiveInformation @(@{Name="U.S. Social Security Number (SSN)"}, @{Name="Credit Card Number"}) `
     -NotifyUser Owner -BlockAccess $false
   ```
   Keep `-BlockAccess $false` in test/audit; you enable blocking only after the audit gate passes.
3. **Config gate:** the policy exists in a **Test** mode; the rule references the approved SITs. No
   messages are blocked yet.

---

## Stage 3 — Pilot & Validate (per control, with gates + rollback)

### 3A. Information barriers — apply and validate
1. **Apply** the IB policies (tenant-wide evaluation — this is the enforcing step):
   ```powershell
   Start-InformationBarrierPoliciesApplication
   ```
2. **Watch application status** until complete:
   ```powershell
   Get-InformationBarrierPoliciesApplicationStatus
   ```
3. **Validate on the pilot users** (only pilot users carry the segment attribute at this point):
   ```powershell
   Get-InformationBarrierRecipientStatus -Identity groupa-user@contoso.com
   ```
   In the Teams client, confirm a GroupA pilot user **cannot** start a chat with, search for, or add a
   GroupB pilot user to a team.
4. **IB pass/fail gate:** application status = `Completed`; pilot recipients show the expected policy;
   Teams blocks the disallowed communication. **Fail → rollback:** set the policy `Inactive`
   (`Set-InformationBarrierPolicy -State Inactive`) and re-run `Start-InformationBarrierPoliciesApplication`
   to lift the barrier, then fix segments/attribute and retry.

### 3B. Teams retention — validate on the pilot scope
1. With the policy scoped to the pilot group, confirm it is **Enabled** and the rule duration/action
   are correct (`Get-RetentionComplianceRule`).
2. Validate behavior over the pilot period: a message older than the schedule follows the end-of-life
   action; content under an eDiscovery/Litigation hold is preserved regardless (coordinate with the
   eDiscovery owner).
3. **Retention pass/fail gate:** policy Enabled, rule correct, pilot content behaves per the schedule.
   **Fail → rollback:** disable the policy (`Set-RetentionCompliancePolicy -Enabled $false`) — note
   that disabling stops future action but does not undo deletions already taken, which is why the pilot
   scope is small and the schedule is validated first.

### 3C. Teams DLP — audit gate, then enforce
1. Leave the policy in **test** mode and review matches in the Purview **Activity explorer / DLP alerts**
   for the pilot scope (**the DLP audit gate**). Tune the rule to remove false positives.
2. When matches are clean, **switch to enforce**:
   ```powershell
   Set-DlpCompliancePolicy -Identity "DLP Policy – Teams Sensitive – Pilot" -Mode Enable
   # to also block, update the rule:
   Set-DlpComplianceRule -Identity "DLP Rule – Teams PII – Pilot" -BlockAccess $true -NotifyUser Owner
   ```
3. **DLP pass/fail gate:** in enforce mode a pilot user sending the matched content sees the policy tip
   / block; false-positive rate is acceptable. **Fail → rollback:** return the policy to
   `-Mode TestWithoutNotifications` (or `Disable`) — impact stops immediately.

---

## Stage 4 — Expand
1. **IB:** extend the segment-defining attribute to the full populations (or broaden the
   `-UserGroupFilter`) and re-run `Start-InformationBarrierPoliciesApplication`; re-validate recipient
   status across a broader sample.
2. **Retention:** widen the policy locations to `All` (or the full adaptive scope) and confirm
   Enabled.
3. **DLP:** widen `-TeamsLocation` to `All`, keep it in enforce, and monitor alert volume.
4. Re-run `TEAMSCOMP-Validation.ps1` after each expansion and record the result. Keep the pilot
   artifacts' names or promote them to `– Prod` per your change control.

## Rollback summary (per control)
- **IB:** set the policy `Inactive` and re-run application → barrier lifts.
- **Retention:** `Set-RetentionCompliancePolicy -Enabled $false` → future action stops (past deletions
  are not reversible — validate on a small pilot first).
- **DLP:** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` or `Disable` → enforcement stops
  immediately.
