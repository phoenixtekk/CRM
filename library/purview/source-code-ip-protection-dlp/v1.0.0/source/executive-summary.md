# Executive Summary — Source-Code & IP Protection DLP: Microsoft Purview

Source code and intellectual property are among the organization's most valuable — and most portable —
assets. A developer emails a snippet to a personal account, copies a repository to a USB drive, uploads
proprietary designs to a personal cloud, or pastes a key algorithm into a chat, and by default nothing
detects that the content is source code or IP, and nothing stops it from leaving. You cannot claim the
crown jewels are protected when they can walk out through everyday actions. This solution closes that gap
with **Microsoft Purview Data Loss Prevention plus classifiers** that detect and protect source code and IP
across email, collaboration, and endpoints — configured, piloted in test mode, validated, and defensible.

This is a complete, do-it-today package written for an administrator implementing code/IP DLP for the first
time. It delivers the capability end-to-end — from reading existing policies, the Source Code classifier,
and Endpoint DLP onboarding, through designing detection and channels and creating the policy **in test
mode** on a developer pilot ring, to tuning false positives against real developer activity, validating,
and only then moving to enforcement as a deliberate, approved step — with every policy, rule, and pilot
ring named once and reused everywhere. Because DLP enforcement blocks real developer workflow, the guide
never enforces on day one: it starts in test mode and gates enforcement behind an explicit, separate
action. Because capability availability (Endpoint DLP, trainable classifiers) is licensing-dependent and
the portal is evolving, the guide cites the method and flags every capability "verify your
licensing/tenant."

## What you get
- A plain-language Solution Overview of code/IP DLP — the Source Code classifier and custom IP types, the
  channels (email, SharePoint/OneDrive, Teams, endpoint USB/upload), policy tips, and test vs enforce mode.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: DLP licensing (E3
  baseline; E5 for Endpoint DLP + classifiers), the least-privilege DLP role, the S&C PowerShell toolchain,
  Endpoint DLP device onboarding, the Source Code classifier and custom IP detection, the in-scope channels
  and pilot ring, test-mode discipline, and the notification/exception design.
- An Implementation Guide of precise, ordered steps: assess, design detection + channels + actions, create
  the policy in test mode on the pilot ring, pilot and tune, validate, **enforce deliberately**, then
  expand.
- Five PowerShell tools — Discovery, a prerequisite/health helper, a safe Configuration/Remediation tool
  (`-WhatIf` by default; creates in test mode; enforce behind its own action), Validation, and Reporting —
  built on Security & Compliance PowerShell, **read-only or `-WhatIf` by default with no credentials in
  code**.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
Source code and IP governed from Purview: detected by classifier and custom types and restricted from
leaving via email, cloud upload, and USB across the in-scope channels — proven in test mode on a developer
pilot ring before any enforcement.

## The deployment model
Assess → Design → Configure (**test mode**) → Pilot → Validate → Expand (**enforce deliberately**) — with a
test-mode gate before enforcement and enforcement enabled only after validation and approval.

## Outcome
The code/IP exfiltration blind spot closed — source code and marked IP can't be emailed externally, copied
to USB, or uploaded to personal cloud, developers see a policy tip that teaches, and every attempt is
logged — with the determination of what is protected IP and which egress is acceptable left to the
security, IP, and legal owners who make it.
