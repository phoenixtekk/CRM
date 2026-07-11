# 2. Requirements — Security Optimization Assessment: Defender for Office 365

The category-wide prerequisites (target tenant, least-privilege read-only access, Graph/management API access, licensing awareness, defined scope and point-in-time baseline, the best-practice reference, secure output handling, and remediation ownership) are in the separate **Global Requirements — Assessments** file — read it first and do not repeat those here. Below are only the prerequisites **specific to assessing Defender for Office 365**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Exchange Online Protection / Defender for Office 365 is in use
**Description:** The tenant uses Exchange Online with EOP, and (for the MDO-specific checks) has Defender for Office 365 licensing on at least some mailboxes.
**Why required:** The assessment reads existing email-protection policies; a tenant not using Exchange Online has nothing to assess, and MDO-only checks are N-A without the plan.
**How to verify:** Sign in to `security.microsoft.com` → **Email & collaboration → Policies & rules → Threat policies**; confirm the policy set loads. Confirm MDO licensing in the admin center. *Verify current plan/feature mapping.*
**How to implement if missing:** If MDO is not licensed, EOP-only checks still apply and MDO-only checks are scored **N-A** (a coverage finding). Building/hardening protection is the **DEFMDOP2** solution.

## R2. Exchange Online and Security & Compliance PowerShell available (read-only)
**Description:** The **ExchangeOnlineManagement** PowerShell module, and the ability to run `Connect-ExchangeOnline` and `Connect-IPPSSession` with a read-only role.
**Why required:** Every MDO/EOP policy read is a `Get-` cmdlet in these endpoints; there is no complete Graph equivalent today. *Verify current API coverage.*
**How to verify:** `Get-Module ExchangeOnlineManagement -ListAvailable` returns a version; `Connect-ExchangeOnline` succeeds; `Get-AntiPhishPolicy | Select -First 1` returns.
**How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`. Assign **Global Reader** / **Security Reader** / **View-Only Configuration** to the assessor.

## R3. Read-only role that can read all threat policies and transport rules
**Description:** A role sufficient to read anti-spam/malware/phish, Safe Links, Safe Attachments, preset policies, the connection filter, the **Tenant Allow/Block List**, and **transport (mail-flow) rules**.
**Why required:** The bypass-hygiene checks depend on reading transport rules and allow lists; a role missing these produces a falsely "clean" report.
**How to verify:** Run `SOAMDO-Validate.ps1` — it confirms it can read a policy of each type **and** transport rules and the Tenant Allow/Block List.
**How to implement if missing:** Ensure the read-only role includes mail-flow and organization configuration read. **Global Reader** generally covers these reads; *verify current role-to-cmdlet mapping.*

## R4. Graph read access for Secure Score and advanced hunting
**Description:** Microsoft Graph read scopes for **Secure Score** (`SecurityEvents.Read.All`) and **advanced hunting** (`AdvancedHunting.Read.All`) over `EmailEvents` / `EmailPostDeliveryEvents`.
**Why required:** Threat-coverage ranking uses how much mail bypassed filtering and post-delivery events; Secure Score provides the MDO recommendation signal.
**How to verify:** In `security.microsoft.com` → **Advanced hunting**, run `EmailEvents | take 1`. `Connect-MgGraph` with the read scopes succeeds.
**How to implement if missing:** Consent the read scopes (or the read-only app registration). *Verify current scope names and hunting retention.*

## R5. Defined recipient scope and the expected mailbox count
**Description:** A documented definition of which recipients are in scope and the **expected** mailbox count from an authoritative source, so "coverage" has a real denominator.
**Why required:** "A strict policy exists" is meaningless without knowing whether it covers the right recipients; coverage needs the full mailbox population.
**How to verify:** You have the mailbox count/scope (e.g. from `Get-Mailbox` count or the admin center) to compare policy recipient coverage against.
**How to implement if missing:** Capture the mailbox scope before the run; `SOAMDO-Coverage.ps1` uses it to find recipients covered by nothing or by weak policy.

## R6. A named best-practice baseline for scoring
**Description:** The reference the score is measured against — Microsoft's **preset Standard/Strict** security policy settings and **Secure Score** MDO recommendations, and/or the org standard.
**Why required:** A score is only meaningful against a stated reference; the report names it so results are defensible and comparable.
**How to verify:** The baseline is documented in scope and echoed in the report header. *Preset behavior evolves — verify against current Microsoft guidance at run time.*
**How to implement if missing:** Adopt **preset Strict** (or Standard) + Secure Score as the default reference; note deliberate deviations as accepted exceptions rather than findings.

## R7. Secure destination for the findings report
**Description:** A restricted location for the HTML/CSV output, which lists exactly which recipients are under-protected and which bypasses exist.
**Why required:** The report is a phishing roadmap for anyone who obtains it; it must be handled as sensitive.
**How to verify:** A need-to-know location exists and access is limited to the security owners.
**How to implement if missing:** Provision a restricted location before the run; treat output as confidential. *Risk-acceptance of any finding is the customer's decision.*
