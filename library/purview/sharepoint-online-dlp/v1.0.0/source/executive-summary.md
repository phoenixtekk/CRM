# Executive Summary — SharePoint Online DLP: Microsoft Purview

SharePoint and OneDrive are where the organization's documents live, and sharing is one click away. A site
owner shares a library "with anyone," a user forwards a OneDrive link outside the company, a spreadsheet
full of customer PII sits in a site open to the whole tenant — and by default nothing inspects the content
or the share. You cannot claim your documents are protected when a share link can turn an internal file
public with one click. This solution closes that gap with **Microsoft Purview Data Loss Prevention** for
SharePoint and OneDrive — policies that inspect documents for sensitive content and govern how they can be
shared — configured, piloted in test mode, validated, and defensible.

This is a complete, do-it-today package written for an administrator implementing SharePoint/OneDrive DLP
for the first time. It delivers the capability end-to-end — from reading existing policies and available
sensitive information types, through designing content and sharing conditions and creating the policy **in
test mode** on a limited pilot, to tuning false positives, validating, and only then moving to enforcement
as a deliberate, approved step — with every policy, rule, and pilot scope named once and reused everywhere.
Because DLP enforcement blocks real collaboration, the guide never enforces on day one: it starts in test
mode and gates enforcement behind an explicit, separate action. Because capability availability is
licensing-dependent and the portal is evolving, the guide cites the method and flags every capability
"verify your licensing/tenant."

## What you get
- A plain-language Solution Overview of SharePoint/OneDrive DLP — sensitive-content detection, sharing and
  external-access conditions, policy tips, notifications, and test vs enforce mode.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: DLP licensing (E3
  baseline; E5 for advanced), the least-privilege DLP role, the S&C PowerShell toolchain, the sensitive
  content and sharing to govern, the in-scope locations and pilot scope, test-mode discipline, and the
  notification/exception design.
- An Implementation Guide of precise, ordered steps: assess, design content + sharing + actions, create the
  policy in test mode on the pilot, pilot and tune, validate, **enforce deliberately**, then expand.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Configuration/Remediation tool
  (`-WhatIf` by default; creates in test mode; enforce behind its own action), Validation, and Reporting —
  built on Security & Compliance PowerShell, **read-only or `-WhatIf` by default with no credentials in
  code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
SharePoint and OneDrive sharing governed from Purview: documents inspected for sensitive content and
external sharing restricted where the content warrants it — proven in test mode on a limited pilot before
any enforcement.

## The deployment model
Assess → Design → Configure (**test mode**) → Pilot → Validate → Expand (**enforce deliberately**) — with
a test-mode gate before enforcement and enforcement enabled only after validation and approval.

## Outcome
The SharePoint sharing blind spot closed — sensitive documents can't be shared externally, users see a
policy tip that teaches, and every match is logged — with the determination of which content is sensitive
and which sharing is acceptable left to the compliance, security, and privacy owners who make it.
