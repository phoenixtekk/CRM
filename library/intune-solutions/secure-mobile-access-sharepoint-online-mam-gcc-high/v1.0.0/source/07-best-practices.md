# 7. Best Practices — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

Field-proven recommendations for running this solution on the **US sovereign cloud**.

## Sovereign-cloud discipline
- **Bookmark the `*.us` portals** (`intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`,
  `portal.office365.us`) and remove Commercial bookmarks from admin machines to avoid cross-cloud
  mistakes.
- **Always connect PowerShell with `-Environment USGov`** so Graph targets `graph.microsoft.us`.
  Every script in this package does this and prints the endpoint it reached — verify it before
  trusting output.
- **Never assume Commercial parity.** GCC High receives features later and some are absent. If a
  capability isn't on a Microsoft US Gov page, treat it as **"verify for GCC High"** and pilot in
  Report-only.

## Policy design
- **Use "Require app protection policy," not "Require approved client app."** The approved-client-app
  control is retiring (early March 2026); build new policies on app protection policy.
  ([Migrate approved client app](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app))
- **Target users, not devices, for MAM.** App Protection Policies apply to users and work on BYO /
  unenrolled devices — that is the whole point of the mobile scenario.
- **Standardize on the Enterprise (Level 2) data-protection baseline** and only deviate with a
  documented reason. ([Data protection framework](https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework))
- **Route mobile browser access through managed Edge** so protection still applies where a browser is
  genuinely needed; otherwise keep users in the SharePoint/OneDrive/Office apps.
- **Keep the app list consistent across iOS and Android** so the user experience and the security
  posture match on both platforms.

## Safety and rollout
- **Report-only first, always.** Never publish an enforcing CA policy without observing it in
  Report-only against the pilot.
- **Two break-glass accounts, excluded from every CA policy**, checked on every change. The
  validation script verifies this — run it after each edit.
- **Assess → Configure → Pilot → Validate → Expand**, with the gate at each step. Widen scope in
  waves using `SPMAMG-Set-ScopeTargeting.ps1` (defaults to `-WhatIf` — review before applying).
- **Change on `-WhatIf` by default.** Remediation and scope-targeting scripts preview their actions;
  apply only after you've read the plan.

## GCC High specifics to plan around
- **Graph-dependent SharePoint mobile features are disabled in GCC High.** Do not design user
  workflows around notifications, activity rollups, stock images, or Internet-service web parts on
  mobile. ([SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint))
- **Only the government account can be added** to the mobile apps; some in-app cloud features are
  FedRAMP-restricted by default. Communicate this to users so they don't try to add personal
  accounts. ([Outlook for iOS/Android in the government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud))
- **Allow the GCC High endpoint ranges** through your MDM/proxy/firewall — the `*.us` SharePoint,
  Entra, and Intune URLs, which differ from Commercial. ([GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints))

## Operations
- **Re-run `SPMAMG-Report.ps1` after every expansion wave** and keep the output as change evidence.
- **Review App Protection Policy status** monthly (`intune.microsoft.us` → **Apps → Monitor → App
  protection status**) to catch users who never received policy.
- **Practice selective wipe** on a test account so the help desk can execute it confidently when a
  device is lost or a user offboards.
