# 8. Deliverables Summary — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: an
  endpoint diagnostics toolkit for Netlogon 5719 / broken secure channel and IPv6 recommended
  configuration — not a config baseline and not a domain-controller health tool.
- **Solution Overview** — what Event ID 5719 means, the full **root-cause tree** (DNS/DC-locator,
  secure channel/trust, time skew, blocked DC ports, no DC path, the boot-time NIC/power race, and
  invalid IPv6), the **IPv6 recommended-configuration** guidance (keep enabled; correct invalid
  `DisabledComponents` only), and how to run locally vs via Intune Proactive Remediations.
- **Requirements Guide** — every device/tooling/network prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered steps across five phases: Assess (stage the scripts),
  Diagnose (Discovery), Repair (preview-first Remediation), Validate (Validation/Report/Collect), and
  deploy at scale via **Proactive Remediations** with full navigation paths — and Prevent.
- **Testing & Validation** — ten tests with explicit pass/fail gates (including the IPv6 correction and
  a negative test that join/enrollment is unchanged) and an acceptance gate.
- **Troubleshooting** — Discovery-first diagnosis for each 5719 cause: boot race, broken trust, DNS,
  time, blocked ports, invalid IPv6, and Proactive Remediations behavior.
- **Best Practices** — diagnose-before-touch, preview-first repair, the correct IPv6 posture,
  recurrence prevention (NIC power-off, wait-for-network, internal DNS, time hierarchy), and operating
  at scale.

## PowerShell scripts (endpoint) — `NETLOGONDX-Scripts.zip`
All scripts run **locally on the affected Windows device** (elevated) or as **SYSTEM via Intune
Proactive Remediations**, use **only in-box Windows commands** (no modules to install), and write to
**`C:\ProgramData\NETLOGONDX`**. Each has a header explaining **Purpose · How to run · Expected
results**. Discovery, Validation, Report, and Collect are **read-only**; Remediation **defaults to
`-WhatIf`** (preview first, then apply).

1. **`NETLOGONDX-Discovery.ps1`** — one-pass collector: recent Event ID 5719 + related secure-channel
   events, `Test-ComputerSecureChannel`, `nltest /sc_query` and `/dsgetdc`, DNS SRV resolution of the
   DC-locator records, `w32tm` time state, DC port reachability (88/135/389/445), and the IPv6
   `DisabledComponents` value. Writes a JSON + transcript. **Read-only.**
2. **`NETLOGONDX-Validation.ps1`** — pass/fail gate asserting secure channel healthy, time in sync, DNS
   resolves DCs, and IPv6 not invalidly disabled. Doubles as the Proactive Remediations **detection**
   script (exit `0` healthy / exit `1` issues). **Read-only.**
3. **`NETLOGONDX-Report.ps1`** — readable + one-row-CSV health summary across all signals for fleet
   roll-up. **Read-only.**
4. **`NETLOGONDX-Remediation.ps1`** — safe repair: `Test-ComputerSecureChannel -Repair` (falling back
   to `nltest /sc_reset`), start Windows Time + `w32tm /resync`, and **correct an invalid IPv6
   `DisabledComponents` back to `0x0`** (never disables IPv6). **`-WhatIf` by default**; applies only
   with `-WhatIf:$false` (or `-Force`). The Proactive Remediations **remediation** script.
5. **`NETLOGONDX-Collect.ps1`** — bundles the System-log events, `nltest`, `ipconfig`, `w32tm`, and
   IPv6 artifacts into one timestamped ZIP for escalation. **Read-only; contains no secrets.**

## Hero image
- **`NETLOGONDX-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited
devices**.
