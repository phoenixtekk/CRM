# 2. Requirements Guide — SaaS Application Discovery & License Right-Sizing

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-asset-mgt.md`.

## 2.1 Entra ID sign-in and usage telemetry
Description: Access to Entra ID sign-in logs and the Usage and insights (enterprise apps) reports.
Why: Sign-in activity is how you tell an actively-used SaaS seat from a dormant one.
Verify: Go to `entra.microsoft.com` then Identity then Applications then Enterprise applications then
Usage and insights — the report loads and shows app sign-in counts. Run `SAASLIC-Discovery.ps1`.
Implement: Ensure auditing is on (it is by default); for history beyond the default retention, see 2.4.

## 2.2 Read access to enterprise applications
Description: A role that can read enterprise applications and sign-in logs — at minimum Reports Reader
plus Application Reader, or a Global Reader.
Why: Discovery and reporting read the app list, assignments, and sign-in events.
Verify: At `entra.microsoft.com` then Identity then Applications then Enterprise applications, the list
loads and you can open an app's Sign-in logs and Users and groups.
Implement: Assign Reports Reader and Application Reader (or Global Reader) to the SAM analyst account.

## 2.3 Microsoft Graph PowerShell access
Description: The Microsoft Graph PowerShell SDK installed, with consent to read directory, apps, and
audit (sign-in) data.
Why: The scripts in this solution read the app inventory and sign-in telemetry through Graph.
Verify: `Connect-MgGraph -Scopes 'Application.Read.All','AuditLog.Read.All','Directory.Read.All'`
succeeds. Run `SAASLIC-Validation.ps1`.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; grant the read scopes above when prompted.

## 2.4 Sign-in log history sufficient for a usage window
Description: Sign-in data covering at least your chosen dormancy window (e.g. 30, 60, or 90 days).
Why: A seat is only a reliable reclaim candidate if it has been dormant across the full window.
Verify: In Sign-in logs, the date filter reaches back to your window; or query via
`SAASLIC-Discovery.ps1` and confirm the earliest event predates the window.
Implement: Entra ID retains sign-in logs for a limited period by default (longer with P1/P2). For a
longer window, export sign-in logs to a Log Analytics workspace and query there.

## 2.5 App owner contacts
Description: A named business owner for each in-scope SaaS app.
Why: Right-sizing decisions (reclaim, consolidate, downgrade) need an accountable owner to approve them.
Verify: For a sample app, you can name the owner; record it in `Owner Map – SaaS – Mapped`.
Implement: Identify owners from procurement records, the app's admin, or the team that requested it;
fill any gaps during the pilot.

## 2.6 SaaS admin access where available
Description: Admin (or read) access to each in-scope app's own admin console.
Why: Sign-in telemetry flags candidates; the actual seat reclaim/downgrade happens in the app's console,
and feature-level usage (for downgrades) is only visible there.
Verify: For a representative app, its admin console loads and shows the seat/license list.
Implement: Request least-privilege admin/read access per app from each app owner.

## 2.7 A spend baseline
Description: Current annual cost (and seat count purchased) per in-scope SaaS app.
Why: Spend is what ranks the review and quantifies the savings from right-sizing.
Verify: For a sample app, you can state its annual cost and entitled seats from contracts/invoices.
Implement: Pull costs from procurement/finance; record them in `Owner Map – SaaS – Mapped`.

---
## Checklist
- [ ] Entra ID sign-in + Usage and insights reports accessible
- [ ] Read access to enterprise applications and sign-in logs
- [ ] Microsoft Graph PowerShell installed with read scopes — `SAASLIC-Validation.ps1`
- [ ] Sign-in history covers the dormancy window
- [ ] App owners identified — `Owner Map – SaaS – Mapped`
- [ ] SaaS admin/read access where available
- [ ] Spend baseline recorded per app
- [ ] `Review Scope – SaaS – Pilot` group created
