# 2. Requirements Guide — Technical Blocker Mitigation: Defender for Office 365

Verify **every** requirement before diagnosing. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running the MDO blocker diagnostics**. Objects you create are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Read-only access to Exchange Online and the Defender portal
**Description:** A read-only footprint: **Global Reader** or **Security Reader** in the Defender portal, plus a **View-Only** Exchange role (View-Only Configuration / View-Only Recipients) and consent to the read-only Microsoft Graph advanced-hunting scope (`ThreatHunting.Read.All`).
**Why:** The diagnostics read policy inventory, precedence, mail routing, message trace, and `EmailEvents` — all read-only; no write role is needed to diagnose.
**Verify:** Connect with `Connect-ExchangeOnline` and run `Get-SafeLinksPolicy` (read) without error; confirm `security.microsoft.com` → **Email & collaboration** loads. `TBMMDO-Discovery.ps1` reports the roles it resolved.
**Implement-if-missing:** Assign Global/Security Reader and a View-Only Exchange role; grant admin consent to `ThreatHunting.Read.All`.

## 2.2 Exchange Online Management module available
**Description:** The **ExchangeOnlineManagement** PowerShell module (v3+) on the workstation running the diagnostics.
**Why:** Accepted domains, connectors, preset/custom threat policies, precedence, and message trace are exposed through Exchange Online cmdlets, not Graph.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement` returns v3 or later; `Connect-ExchangeOnline` succeeds. `TBMMDO-Discovery.ps1` installs it if missing.
**Implement-if-missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`.

## 2.3 The affected recipient subset defined
**Description:** A named subset of the mailboxes/recipients exhibiting the blocker — the ones you will re-test the fix against before resuming. Name it `MDO Blocker Triage – Affected Recipients – Diagnose`.
**Why:** Fixes are validated on the affected recipients first (per `global-requirements-defender.md` G6) so you prove the policy applies before touching the tenant.
**Verify:** A mail-enabled group / list of the affected recipients exists; `TBMMDO-Validate.ps1` checks the policy that applies to them.
**Implement-if-missing:** Create the group `MDO Blocker Triage – Affected Recipients – Diagnose` and add the affected mailboxes.

## 2.4 Knowledge of the mail-routing topology
**Description:** Know how inbound mail reaches the tenant — direct **MX → EOP**, or via a **third-party gateway / inbound connector / hybrid** in front of EOP.
**Why:** Routing conflicts are a top blocker; if a gateway strips or pre-scans mail, MDO features never engage. You must know the real path to diagnose it.
**Verify:** `Get-AcceptedDomain`, `Get-InboundConnector`, and the public MX record for the domain; `TBMMDO-MailFlow.ps1` reports accepted domains, connectors, and routing hints.
**Implement-if-missing:** Confirm the routing design with whoever owns mail flow; document any gateway in front of EOP.

## 2.5 A safe test message method
**Description:** A benign way to exercise Safe Links / Safe Attachments — a test URL and the standard Microsoft test procedure (e.g. an EICAR-style attachment through the documented Microsoft test), sent to a recipient in the affected subset.
**Why:** Verification needs a controlled message that *should* trigger the feature so you can confirm rewriting/detonation and see it in message trace and hunting.
**Verify:** You can send a controlled test to `MDO Blocker Triage – Affected Recipients – Diagnose` and view the result in message trace.
**Implement-if-missing:** Prepare the benign test material per current Microsoft guidance. *Verify the current recommended test procedure.*

## 2.6 A place to store the diagnostic output and support bundle
**Description:** A secure location for the JSON snapshots the scripts write and for the support bundle `MDO Support Bundle – <case> – Escalate`.
**Why:** The before/after snapshots prove the policy now applies, and the bundle is what you attach to a Microsoft support case.
**Verify:** A working folder exists with least-privilege access; `TBMMDO-Report.ps1` writes there.
**Implement-if-missing:** Create a restricted working folder; do not store recipient identifiers in shared/unsecured locations.

---
## Checklist
- [ ] Read-only Defender + View-Only Exchange roles + `ThreatHunting.Read.All` — `TBMMDO-Discovery.ps1`
- [ ] ExchangeOnlineManagement module (v3+) installed
- [ ] Affected recipient subset `MDO Blocker Triage – Affected Recipients – Diagnose` created
- [ ] Mail-routing topology known (MX / connectors / gateway) — `TBMMDO-MailFlow.ps1`
- [ ] Safe test-message method prepared
- [ ] Secure working folder for snapshots and the support bundle
