# Best Practices — Exchange Edge Transport Server Deployment & Hardening (Hybrid)

Durable practices for a secure, maintainable Edge Transport tier. **Verify version-specific defaults
against Microsoft's documentation for your Exchange Server version/CU.**

## Topology & host hygiene

- **Keep the Edge standalone in the perimeter.** Workgroup or a dedicated perimeter/DMZ domain — never
  the internal production AD forest. That isolation is the whole point of the role.
- **Minimize the host.** Only the Edge role, AD LDS, and required OS features; no extra roles or
  general-purpose software. Patch the OS and Exchange on a defined cadence.
- **One responsibility.** Don't co-locate other internet-facing services on the Edge host.

## EdgeSync

- **Let EdgeSync own the internet connectors.** After subscribing, the internet Send connector
  (`EdgeSync – <site> to Internet`) and the inbound Receive connector are **auto-managed** — don't
  hand-edit them on the Edge; make connector/accepted-domain changes on the **internal** org and let
  them replicate down.
- **Re-subscribe when config drifts.** If EdgeSync health degrades or you change the Edge's role
  fundamentals, the clean fix is often to remove and **re-create the subscription** rather than
  hand-patching.
- **Watch clock skew and certificates.** EdgeSync uses a self-signed cert and secure LDAP (50636);
  time skew and cert expiry are common silent failure causes — monitor both.

## Connectors, accepted domains, relay

- **Never grant anonymous relay to external recipients.** Scope Receive connectors so anonymous
  internet senders can deliver **only** to your accepted domains — that is the anti-open-relay
  guarantee. Any internal application relay should use an **authenticated** or **IP-scoped** connector,
  not anonymous-to-anywhere.
- **Manage accepted domains internally.** They sync to the Edge; don't try to author them on the Edge.
- **Prefer least privilege on connector permissions** (`PermissionGroups` / `AuthMechanism`) and
  review them after every CU.

## TLS & authentication

- **Enforce TLS.** Keep a valid public certificate (`Cert – Edge SMTP – Prod`) enabled for SMTP with a
  matching subject/SAN; advertise STARTTLS. Use **forced/mutual TLS** for partners and hybrid paths
  that require it.
- **Disable legacy TLS** (1.0/1.1) and weak ciphers where your Exchange version/CU and OS support it —
  **this is version/OS-dependent; verify** and stage it, because it can break older partners.
- **Track certificate expiry** with the reporting/health scripts; a lapsed cert breaks secure flow and
  EdgeSync trust.

## Hygiene split with the cloud (hybrid)

- **Don't double-filter.** In a hybrid where **EOP / Defender for Office 365** is the primary hygiene
  layer, keep the Edge focused on **perimeter connection control, TLS, and safe relay**; let cloud do
  content/anti-phish. Duplicated aggressive filtering causes false positives and hard-to-trace drops.
- **If a third-party secure email gateway is your internet-facing MX,** the Edge role may be redundant
  — decide deliberately whether you need Edge at all, or whether it becomes an internal-facing relay.
- **Tune IP Allow/Block and providers conservatively.** Over-broad blocks silently drop legitimate
  mail; document every entry in `Hygiene – Edge Baseline – Prod`.

## Change control, monitoring & lifecycle

- **Pilot-first, always.** Validate on a test mail path and pass Gates B–D before cutting production MX.
  Keep a recorded baseline and a ready **rollback** (revert MX, remove subscription).
- **Monitor continuously:** EdgeSync health (`Test-EdgeSynchronization`), queues (`Get-Queue`),
  certificate expiry, and anti-spam posture. Schedule `Get-EdgeReadiness.ps1` and
  `Get-AntiSpamReport.ps1`.
- **Re-validate after every CU.** Exchange CUs can change TLS/Extended Protection defaults and agent
  behavior — re-run the validation set after each update.
- **Automation is read-only or `-WhatIf` by default.** Never store credentials in scripts; use
  interactive modern-auth for any cloud/EXO steps.

## Commercial vs Government

- The on-prem Edge steps are cloud-independent, but **hybrid/cloud touch points differ on
  GCC/GCC High/DoD** (EOP endpoints, connector targets, admin portal URLs such as `*.office365.us`).
  Confirm the correct sovereign-cloud endpoints; do **not** assume Commercial paths.
