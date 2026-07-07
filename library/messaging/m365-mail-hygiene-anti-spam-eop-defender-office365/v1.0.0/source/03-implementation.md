# Implementation

This is the exact, ordered implementation, following the house model **Assess → Design → Configure
→ Pilot → Validate → Expand**, pilot-first, with pass/fail gates and a documented rollback. Every
artifact is named `<Purpose> – <Scope> – <Stage>` and reused by that exact name in Testing,
Troubleshooting, and the scripts.

> **Portal note:** Steps use the **Microsoft Defender portal** at `security.microsoft.com`
> (Commercial). On **GCC High / DoD** use `security.microsoft.us`; on **GCC** confirm the correct
> URL for your tenant. Exchange admin center is `admin.exchange.microsoft.com`
> (`admin.exchange.microsoft.us` for GCC High/DoD). **Verify URLs and feature availability in your
> tenant.**
>
> **Connect first (PowerShell):** `Connect-ExchangeOnline` (add
> `-ExchangeEnvironmentName O365USGovGCCHigh` or `O365USGovDoD` for those clouds). Use a
> least-privilege admin (Security Administrator + Exchange Administrator covers hygiene). No stored
> credentials.

---

## Stage 1 — Assess (read-only)

**Goal:** capture the current state as the rollback baseline and identify risks.

1. Run the discovery script **`Get-MailHygieneAssessment.ps1`** (read-only). It exports, for the
   tenant: anti-spam (hosted content filter) policies + rules, anti-malware policies, anti-phish
   policies, Safe Links / Safe Attachments policies (if Defender for Office 365 is licensed),
   connection filter policy, quarantine policies, Tenant Allow/Block List entries, preset policy
   state, and — critically — **mail-flow rules (transport rules) that alter filtering** (SCL
   overrides, allow-list rules, `SetHeaderName`/`SetSCL` actions). Archive the output as the
   **rollback baseline**.
2. Note **licensing** (from Requirements #1): EOP-only vs Defender for Office 365 Plan 1/2. This
   determines which of Stages 3d–3f you perform.
3. Review the assessment against the **Standard preset** recommendations (the script flags gaps and
   risky legacy rules, e.g. any rule setting `SCL -1`).

**Gate 1 (pass/fail):** You have a complete before-state export **and** a documented list of any
legacy filter-bypassing transport rules. **Fail** → do not proceed until the baseline is captured.

## Stage 2 — Design

**Goal:** decide the target configuration before touching production.

1. **Choose the baseline:** default to the **Standard** preset for the pilot scope. Decide whether
   any group (execs, finance) will be escalated to **Strict** at Expand.
2. **Quarantine model:** choose the quarantine policy per verdict. Recommended default:
   `DefaultFullAccessWithNotificationPolicy` (recipients notified, can request release) for
   spam/bulk; **admin-only** (`AdminOnlyAccessPolicy`) for high-confidence phishing and malware.
3. **Allow/Block model:** all exceptions go through the **Tenant Allow/Block List** — decide the
   initial known-good senders/domains and any known-bad to block. **No new SCL-override transport
   rules.**
4. **Name the artifacts** (create these exact names in Stage 3):
   - Preset scope target: pilot group `Hygiene-Pilot`.
   - Custom (only if a preset gap requires it): `Anti-Spam – Inbound – Pilot`,
     `Anti-Malware – Inbound – Pilot`, `Anti-Phish – Standard – Pilot`,
     `Safe-Links – Standard – Pilot`, `Safe-Attach – Standard – Pilot`,
     `Quarantine – Notify – Prod`.
5. **Rollback plan:** for presets, rollback = remove the pilot scope from the preset (protection
   reverts to prior state). For custom policies, rollback = disable/delete the named policy. For
   transport-rule cleanup, rollback = re-import the archived rule from the baseline.

**Gate 2:** Design (baseline, quarantine model, allow/block list, artifact names, rollback)
documented and approved under change control.

## Stage 3 — Configure (against the pilot scope)

> Do everything here **scoped to `Hygiene-Pilot`**, not the whole tenant.

### 3a. Clean up filter-bypassing transport rules (if found in Stage 1)

Legacy rules that set `SCL -1` or broadly allow senders undermine hygiene. In EAC > **Mail flow >
Rules**, or PowerShell:

- Review each flagged rule (`Get-TransportRule | Where-Object {$_.SetSCL -eq '-1'}`).
- Replace broad allow-list rules with **Tenant Allow/Block List** entries (Stage 3g).
- Disable (don't delete yet) rules you intend to retire: `Disable-TransportRule -Identity "<name>"`.
  Keep the export so you can `Import`/re-enable to roll back.

### 3b. Connection filtering (EOP) — `Connection-Filter – Default`

The connection filter policy is the **default** policy (single, tenant-wide; not scoped). Configure
only deliberate IP allow/block; **avoid `EnableSafeList` unless required**:

- Defender portal > **Email & collaboration > Policies & rules > Threat policies > Anti-spam** >
  **Connection filter policy (Default)**. Add only trusted infrastructure IPs to **Allow**, known-bad
  to **Block**.
- PowerShell: `Set-HostedConnectionFilterPolicy -Identity Default -IPAllowList @('x.x.x.x') -IPBlockList @('y.y.y.y')`.
- **If a third-party gateway sits in front of EOP:** do **not** add its IPs here; instead configure
  **Enhanced Filtering for Connectors** (skip listing) on the inbound connector so EOP sees the true
  source IP. Defer the third-party console to its vendor docs.

### 3c. Apply the Standard preset (EOP + Defender for Office 365) — pilot scope

Preferred baseline. In the Defender portal > **Threat policies > Preset security policies**:

1. Edit **Standard protection** > turn it **On**.
2. Under **EOP protections apply to**, add the **`Hygiene-Pilot`** group. Under **Defender for
   Office 365 protections apply to** (only if licensed), add the same group.
3. Leave the impersonation-protection exceptions empty for now (add trusted senders/domains only if
   a false positive appears in validation).
4. Save. The preset now governs anti-spam, anti-malware, anti-spoof and (if licensed) anti-phish,
   Safe Links, Safe Attachments for the pilot — with Microsoft-maintained settings.

> If the Standard preset fully meets the design, **skip 3d–3f** (custom policies) and go to 3g.
> Build custom policies **only** for a specific gap the preset cannot express.

### 3d. Custom anti-spam / anti-malware (EOP) — only if a preset gap requires it

Create named custom policies **above** the default in priority, scoped to `Hygiene-Pilot`:

- Anti-spam (hosted content filter): `New-HostedContentFilterPolicy -Name "Anti-Spam – Inbound – Pilot" ...`
  then `New-HostedContentFilterRule -Name "Anti-Spam – Inbound – Pilot" -HostedContentFilterPolicy "Anti-Spam – Inbound – Pilot" -SentToMemberOf "Hygiene-Pilot"`.
  Set verdict actions (e.g. high-confidence phishing → **Quarantine**), the **bulk threshold** (BCL,
  default 7 — tune up/down only from data), and the **quarantine policy** per action.
- Anti-malware: `New-MalwareFilterPolicy -Name "Anti-Malware – Inbound – Pilot" -EnableFileFilter $true ...`
  with the common-attachments filter enabled, then `New-MalwareFilterRule ... -SentToMemberOf "Hygiene-Pilot"`.
- **Use `-WhatIf` first** (the provided config-helper script does exactly this).

### 3e. Anti-phishing (Defender for Office 365) — `Anti-Phish – Standard – Pilot`

> **Requires Defender for Office 365 (Plan 1 or 2). Skip if EOP-only.**

Only if not covered by the preset: create `Anti-Phish – Standard – Pilot`
(`New-AntiPhishPolicy` + `New-AntiPhishRule ... -SentToMemberOf "Hygiene-Pilot"`). Enable
impersonation protection for a small list of high-value users/domains, mailbox intelligence, and set
the action for detected impersonation to **Quarantine** with the chosen quarantine policy. Keep the
protected-user list small to avoid false positives.

### 3f. Safe Attachments & Safe Links (Defender for Office 365)

> **Requires Defender for Office 365 (Plan 1 or 2). Skip if EOP-only.**

Only if not covered by the preset:

- **Safe Attachments** `Safe-Attach – Standard – Pilot`: `New-SafeAttachmentPolicy` (Action =
  **Dynamic Delivery** recommended) + `New-SafeAttachmentRule ... -SentToMemberOf "Hygiene-Pilot"`.
  Also enable the **global** setting to protect SharePoint/OneDrive/Teams
  (`Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $true`) and Safe Documents if E5 (`-EnableSafeDocs $true`).
- **Safe Links** `Safe-Links – Standard – Pilot`: `New-SafeLinksPolicy` (enable URL rewrite, scan on
  click, do not let users click through to the original URL) + `New-SafeLinksRule ... -SentToMemberOf "Hygiene-Pilot"`.

### 3g. Quarantine policy & notifications — `Quarantine – Notify – Prod`

- Confirm/assign the quarantine policy each verdict uses (from Design). For end-user-visible
  quarantine use `DefaultFullAccessWithNotificationPolicy`; for phishing/malware use
  `AdminOnlyAccessPolicy`.
- Enable **quarantine notifications** so recipients learn of held mail and can request release
  (governed by Requirement #5's decision).
- If a custom quarantine policy is needed: `New-QuarantinePolicy -Name "Quarantine – Notify – Prod" ...`.

### 3h. Tenant Allow/Block List (TABL)

- Add deliberate allows/blocks in the Defender portal > **Threat policies > Tenant Allow/Block
  Lists**, or PowerShell `New-TenantAllowBlockListItems -ListType Sender -Allow -Entries "good@partner.com"`
  / `-Block` for known-bad senders, domains, URLs (`-ListType Url`), or file hashes
  (`-ListType FileHash`). Set expirations on allows (`-NoExpiration` only when justified).
- **This is the only sanctioned exception mechanism** — it replaces the transport-rule allow-lists
  retired in 3a.

## Stage 4 — Pilot

**Goal:** run real mail through the pilot config and watch for false positives/negatives.

1. Leave the pilot config running for an agreed window (e.g. 5–10 business days).
2. Have pilot users report any misfiled mail; monitor quarantine daily (the reporting script
   produces the quarantine/allow-block review report).
3. Tune from **data only**: adjust the bulk (BCL) threshold, add a specific TABL allow, or add an
   impersonation exception — never widen a filter globally.

**Gate 4:** Over the pilot window, threats are caught (Testing section) **and** the false-positive
rate is acceptably low (target: no legitimate business mail lost; any FP resolvable via a specific
TABL allow, not a filter downgrade). **Fail** → tune and re-pilot; do not expand.

## Stage 5 — Validate

Run the full **Testing** procedures (next section) against the pilot: spam (GTUBE), malware
(EICAR), spoof, bulk, and — if Defender for Office 365 — Safe Links and Safe Attachments. Every test
must hit its expected pass result. Confirm quarantine notifications deliver and release works.

**Gate 5:** All Testing pass/fail checks pass. **Fail** → troubleshoot (Troubleshooting section),
fix, re-validate.

## Stage 6 — Expand

**Goal:** roll the validated baseline to the rest of the organization.

1. **Preset path:** in the Standard preset, change the scope from `Hygiene-Pilot` to the full
   organization (or the appropriate groups/domains). Escalate exec/finance groups to the **Strict**
   preset if that was the design.
2. **Custom path:** widen each named policy's rule (`Set-*FilterRule`/`Set-AntiPhishRule` etc.) from
   `-SentToMemberOf "Hygiene-Pilot"` to the production scope.
3. Keep the quarantine review cadence and the reporting script on a schedule.
4. Retire the disabled legacy transport rules (from 3a) once you are confident, having kept the
   export for rollback.

**Gate 6:** Post-expand, monitor the first days closely; the reporting script's false-positive /
spoof-intelligence analysis should show no spike in legitimate mail being quarantined.

## Rollback (any stage)

- **Preset:** remove the pilot/production scope from the Standard/Strict preset — protection reverts
  to the prior state.
- **Custom policy:** `Disable-*Rule` or delete the named policy; higher-priority default resumes.
- **Transport rules:** re-enable / re-import the archived rule from the Stage 1 baseline.
- **TABL:** remove the specific allow/block entry.

Because every change is scoped and named, rollback is targeted and does not disturb unrelated mail
flow.
