# Requirements

These are the **solution-specific** prerequisites for configuring and tuning Microsoft 365 mail
hygiene. They build on — and do not repeat — the shared **Global Requirements for Messaging
Solutions** (`global-requirements-messaging.md`): a Microsoft 365 tenant with Exchange Online,
least-privilege admin roles, the EXO V3 + Graph toolchain, DNS control, hybrid/AD access where
applicable, and a pilot scope with change control. Verify those first, then confirm the additions
below.

Each requirement below lists **Description / Why required / How to verify / How to implement if
missing**.

---

## 1. Confirmed EOP and (if applicable) Defender for Office 365 licensing

- **Description:** A definitive answer to **which hygiene plan the tenant has** — EOP only, or
  Defender for Office 365 **Plan 1** or **Plan 2** (standalone, or bundled in Microsoft 365 E5 /
  E5 Security / Business Premium, which includes Defender for Office 365 Plan 1).
- **Why required:** This is the single most consequential prerequisite. **Anti-phishing
  impersonation protection, Safe Links, and Safe Attachments are Defender for Office 365 features
  and do not exist on an EOP-only tenant.** Designing around a feature you are not licensed for
  wastes effort and produces a non-working plan. Plan 1 vs Plan 2 also differs (Plan 2 adds Threat
  Explorer, AIR, Attack Simulation).
- **How to verify:** Microsoft 365 admin center > **Billing > Licenses**; look for *Microsoft
  Defender for Office 365 (Plan 1/Plan 2)* or a bundle that includes it. In the Microsoft Defender
  portal (`security.microsoft.com`, or `security.microsoft.us` for Government), the presence of
  **Safe Links** and **Safe Attachments** policy pages under **Email & collaboration > Policies &
  rules > Threat policies** indicates Defender for Office 365 is licensed. **Verify capability in
  your own tenant — do not assume from the SKU name.**
- **How to implement if missing:** If only EOP is present, either proceed with EOP-only hygiene
  (still substantial) or license Defender for Office 365 for the users who need advanced protection
  before configuring those features. Defender for Office 365 can be licensed per-user.

## 2. Email authentication (SPF, DKIM, DMARC) on all sending domains

- **Description:** Valid **SPF** (TXT), **DKIM** (signing enabled in Exchange Online / CNAMEs
  published), and **DMARC** (TXT) records for every domain the organization sends mail from.
- **Why required:** Spoof intelligence, anti-phishing, and DMARC-based handling all depend on
  authenticated signals. Without DKIM and DMARC, legitimate mail is harder to distinguish from
  spoofing, increasing both false positives and missed threats.
- **How to verify:** Check DNS for SPF/DMARC TXT records; in the Defender portal check that spoof
  intelligence has data. Confirm DKIM in Exchange Online PowerShell: `Get-DkimSigningConfig` (each
  domain should show `Enabled = True`). The provided validation script summarizes authentication
  posture.
- **How to implement if missing:** Publish/repair SPF, enable and publish DKIM
  (`Set-DkimSigningConfig -Identity <domain> -Enabled $true` after the CNAMEs exist), and publish a
  DMARC record (start at `p=none` for monitoring, then tighten). This is a foundation, not part of
  hygiene tuning itself — but hygiene will underperform without it.

## 3. Defined pilot scope (group, users, or domain) for policy targeting

- **Description:** A named **pilot group** (a mail-enabled security group or a set of users/domain)
  to which the baseline is applied first — distinct from fleet-wide.
- **Why required:** Preset and custom policies are **scoped by users/groups/domains**. A pilot scope
  lets you validate the baseline and tuning against real mail before expanding, per the deployment
  model. It also enables clean rollback (remove the scope).
- **How to verify:** Confirm the pilot group exists and contains representative mailboxes (including
  a high-volume user and an exec/finance user if relevant). `Get-DistributionGroup` /
  `Get-UnifiedGroup` or the Microsoft 365 admin center.
- **How to implement if missing:** Create a mail-enabled security group (e.g. `Hygiene-Pilot`) and
  add representative members.

## 4. A test mailbox and a way to send controlled test messages

- **Description:** At least one **test mailbox** in the pilot scope and a method to send **safe test
  messages** — e.g. the **GTUBE** spam-test string, the **EICAR** anti-malware test file, and a
  known-benign bulk sender — plus a way to send from an external address you control.
- **Why required:** Validation (Testing section) requires provoking each verdict — spam, malware,
  spoof, safe-link/attachment — and confirming the expected action without using real malware.
- **How to verify:** Confirm you have an external mailbox (or a controlled external sender) and the
  standard test artifacts (GTUBE, EICAR) available.
- **How to implement if missing:** Prepare a controlled external sender and the standard test
  strings/files before validation. **Never use real malware; use EICAR/GTUBE only.**

## 5. Quarantine review owner and notification decision

- **Description:** A named **owner** for quarantine review and a decision on **quarantine
  notification** cadence and recipient permissions (view / request release / release / block).
- **Why required:** Quarantine is only effective if someone reviews it and end-users know how to
  request release of false positives. The quarantine policy encodes these permissions.
- **How to verify:** Confirm an owner (e.g. the messaging team) and the intended recipient
  permission level.
- **How to implement if missing:** Assign the owner and agree the notification/permission model
  before enabling quarantine-heavy actions.

## 6. Baseline of current hygiene configuration and mail-flow rules (transport rules)

- **Description:** A captured **before** state: existing anti-spam/anti-malware/anti-phish policies,
  the Tenant Allow/Block List, connection filter, quarantine policies, and any **mail-flow rules
  (transport rules)** that bypass or alter filtering (e.g. SCL-override rules, allow-list rules).
- **Why required:** Legacy mail-flow rules that set `SCL -1` (bypass spam filtering) or broadly
  allow senders are the most common cause of both missed threats **and** confusing behavior after
  tuning. You must know what exists before you change anything, and to roll back.
- **How to verify:** Run the provided discovery script (read-only). It exports current policies,
  TABL entries, connection filter, quarantine policies, and transport rules that affect filtering.
- **How to implement if missing:** Run the discovery script and archive its output as the rollback
  baseline before any change.

## 7. Government cloud confirmation (if applicable)

- **Description:** Confirmation of whether the tenant is **Commercial** or a **Government cloud**
  (GCC / GCC High / DoD).
- **Why required:** Portal URLs and some feature availability differ. The Defender portal is
  `security.microsoft.com` (Commercial) vs `security.microsoft.us` (GCC High/DoD); certain Defender
  for Office 365 capabilities roll out later or differently on sovereign clouds. Using the wrong URL
  or assuming a feature exists will block the work.
- **How to verify:** Confirm the tenant's cloud instance with the tenant owner / in the admin
  center. **Verify feature availability in your own tenant.**
- **How to implement if missing:** Record the cloud instance and substitute the correct portal URLs
  throughout; flag any feature that is not yet available on that cloud.
