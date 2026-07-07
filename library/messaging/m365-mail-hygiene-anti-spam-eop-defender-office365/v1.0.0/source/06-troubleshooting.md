# Troubleshooting

Common failure modes when configuring and tuning Microsoft 365 mail hygiene, with resolutions. Use
the provided scripts to diagnose: `Get-MailHygieneScopeHealth.ps1` (which policy applies),
`Test-MailHygienePolicy.ps1` (validation), and `Get-QuarantineAndAllowBlockReport.ps1` (quarantine /
allow-block review).

---

## T-A. Spam/malware/phish delivered to the Inbox despite the policy

- **Likely cause:** A **filter-bypassing mail-flow rule** (transport rule setting `SCL -1`), a broad
  allow-list rule, or a **Tenant Allow/Block List** allow entry is whitelisting the sender — or the
  policy is not scoped to the recipient.
- **Resolve:** Run `Get-MailHygieneAssessment.ps1` and look for the `SCL -1` RISK flags; disable
  those rules (retire them into TABL). Run `Get-MailHygieneScopeHealth.ps1 -User <recipient>` to
  confirm which policy actually applies. Check the TABL for an over-broad allow. Confirm the
  recipient is in the policy scope (pilot group or expanded scope).

## T-B. Legitimate mail is being quarantined (false positive)

- **Likely cause:** Bulk (BCL) threshold too aggressive, an impersonation-protection list too broad,
  spoof intelligence flagging a legitimate on-behalf sender, or the Strict preset applied to users
  who need Standard.
- **Resolve:** Identify the verdict from the message trace / `Get-QuarantineAndAllowBlockReport.ps1`.
  Fix with the **least broad** action: add a **specific TABL allow** for the sender/domain, raise the
  **BCL threshold** from data, add a targeted impersonation exception, or move the user from Strict to
  Standard. **Never** disable the filter or add an `SCL -1` rule.

## T-C. "Safe Links / Safe Attachments / impersonation protection is missing"

- **Likely cause:** The tenant is **EOP-only** (or the specific users are not licensed for Defender
  for Office 365). These are **Defender for Office 365** features — they do not exist on EOP.
- **Resolve:** Verify licensing (Requirement #1): Microsoft 365 admin center > Billing > Licenses.
  Confirm the Safe Links / Safe Attachments policy pages exist in the Defender portal. If EOP-only,
  either license Defender for Office 365 for those users or proceed with EOP-only hygiene. On
  **Government clouds**, also confirm the feature has rolled out for that cloud — **verify in your
  tenant**.

## T-D. Cannot reach the portal / cmdlet errors on a Government tenant

- **Likely cause:** Wrong portal URL or `Connect-ExchangeOnline` environment for GCC/GCC High/DoD.
- **Resolve:** Use `security.microsoft.us` (GCC High/DoD) and
  `admin.exchange.microsoft.us`; connect with
  `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` (or `O365USGovDoD`). For GCC,
  confirm the correct URL for your tenant. **Do not assume Commercial URLs.**

## T-E. Quarantine notifications not delivered / users can't request release

- **Likely cause:** The quarantine policy assigned to the verdict lacks end-user permissions/
  notifications, or an admin-only policy is applied where user access was intended.
- **Resolve:** Confirm the verdict's action uses `DefaultFullAccessWithNotificationPolicy` (or your
  `Quarantine – Notify – Prod` policy) and that quarantine notifications are enabled. High-confidence
  phishing/malware intentionally use `AdminOnlyAccessPolicy` (no self-release) — that is by design.

## T-F. A user gets a different verdict than expected

- **Likely cause:** **Policy precedence** — only the highest-priority matching policy of each type
  applies. A higher-priority custom policy or a preset is overriding what you expected.
- **Resolve:** Run `Get-MailHygieneScopeHealth.ps1 -User <user>` to see the effective policy per
  type and the priority order. Adjust priorities or scope so the intended policy wins.

## T-G. EOP not filtering correctly when a third-party gateway is in front

- **Likely cause:** EOP is evaluating the **gateway's IP** as the source rather than the true
  external sender, so connection filtering and spoof intelligence misbehave.
- **Resolve:** Configure **Enhanced Filtering for Connectors (skip listing)** on the inbound
  connector so EOP sees the real source IP (`Get-MailHygieneScopeHealth.ps1` reports current
  state). Do not add the gateway IPs to the connection-filter allow list. Defer the third-party
  console to the vendor's docs.

## T-H. Spoof of your own domain still delivered

- **Likely cause:** Weak or missing **SPF/DKIM/DMARC**, so composite authentication cannot fail the
  spoof; or a TABL allow / transport rule is permitting it.
- **Resolve:** Confirm DKIM is enabled per domain (`Get-DkimSigningConfig`), SPF/DMARC published
  (`Test-MailHygienePolicy.ps1` checks these), spoof intelligence is on, and no allow entry is
  whitelisting the spoofer. Tighten DMARC toward `p=quarantine`/`p=reject` as data supports.

## T-I. `Connect-ExchangeOnline` or a cmdlet fails

- **Likely cause:** EXO V3 module missing/outdated, Basic Auth (retired), or insufficient role.
- **Resolve:** `Install-Module ExchangeOnlineManagement` / `Update-Module`; use modern-auth /
  MFA sign-in; ensure the admin has the least-privilege roles (Security Administrator + Exchange
  Administrator for hygiene). Never use stored credentials.

## T-J. Changes seem to have no effect immediately

- **Likely cause:** Policy propagation delay; or the change was made in a **dry-run** (the config
  helper defaults to `-WhatIf` unless `-Commit` is passed).
- **Resolve:** Confirm the change actually committed (re-run `Set-MailHygieneBaseline.ps1` with
  `-Commit`, or verify with `Get-*Policy`/`Get-MailHygieneScopeHealth.ps1`). Allow time for
  propagation, then re-test with a fresh message.
