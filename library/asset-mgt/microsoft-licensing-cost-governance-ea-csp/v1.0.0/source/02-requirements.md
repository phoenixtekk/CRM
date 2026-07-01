# 2. Requirements Guide — Microsoft Licensing Cost Governance (EA, CSP & True-Up Readiness)

Verify every requirement before you configure anything. Each entry follows: Description · Why ·
Verify · Implement-if-missing. Category-wide prerequisites (tenant, admin access, system of record,
discovery data, reporting toolchain, stakeholders, pilot) are in
`global-requirements-asset-mgt.md` — confirm those first; the items below are specific to licensing
cost governance across EA and CSP.

## 2.1 Billing/admin visibility into the license sources
Description: An account that can read licensing and billing in the Microsoft 365 admin center
(`https://admin.microsoft.com`) — at minimum the License Administrator and Billing Administrator
roles (or Global Reader for read-only governance).
Why: The deployed/assigned position and the subscribed quantities are read here; cost governance
cannot proceed without it.
Verify: Sign in to `https://admin.microsoft.com` and open Billing then Your products, and Billing
then Billing accounts — both load and show subscriptions/quantities.
Implement: Assign least-privilege roles (License Administrator plus Billing Administrator, or Global
Reader) in `https://entra.microsoft.com` then Roles and admins; reserve Global Administrator for
tenant-wide changes only.

## 2.2 Microsoft Graph access for license reads
Description: The ability to run Microsoft Graph PowerShell with the `Organization.Read.All` and
`User.Read.All` scopes (read-only) to enumerate `subscribedSkus` and per-user license assignments.
Why: The Discovery, Validation, and Report scripts read the deployed position directly from the
tenant via Graph; this is the authoritative assignment count.
Verify: Run `Connect-MgGraph -Scopes 'Organization.Read.All','User.Read.All'` and then
`Get-MgSubscribedSku` returns rows.
Implement: Install the Microsoft Graph PowerShell SDK
(`Install-Module Microsoft.Graph -Scope CurrentUser`) and consent the read scopes when prompted; a
Global Reader or License Administrator can consent for themselves.

## 2.3 Agreement details (EA and/or CSP) — from the agreement, not assumed
Description: The signed EA enrolment details (committed baseline quantities, products in scope,
anniversary/true-up window, term dates) and/or the CSP subscription details (products, seat counts,
term, adjustment points) as recorded in the agreement and the procurement/licensing portal.
Why: The entitlement (owned) side of every position comes from the agreement; without it you can
read deployment but cannot compute position or true-up exposure.
Verify: You can state, for one representative product, the committed/owned quantity and the renewal
or anniversary date from the agreement or portal.
Implement: Obtain the current EA enrolment summary and CSP subscription export from the licensing
partner or the procurement/EA portal; record them in the system of record (G3). Do not estimate
contract terms — defer specifics to the agreement and procurement.

## 2.4 The License Position Register
Description: A controlled register — `License Position Register – EA+CSP – Steady-State` — listing,
per product/SKU, the owned quantity (from the agreement), the channel (EA or CSP), the assigned
quantity (from the tenant), the resulting position, and the renewal/anniversary date.
Why: This is the single artifact that reconciles entitlement to deployment; every KPI and decision
references it.
Verify: The register exists and has at least the pilot scope's products populated with owned and
assigned columns.
Implement: Create the register (spreadsheet or SAM tool) using the columns above; seed owned counts
from 2.3 and assigned counts from `MSLICGOV-Report.ps1`.

## 2.5 Deployment/usage data for utilization
Description: Sign-in/usage telemetry sufficient to distinguish assigned-but-unused licenses from
active ones (covered category-wide in G4) for the products in scope.
Why: Reharvesting and right-sizing depend on knowing which assigned seats are actually used.
Verify: You can export or read a last-activity/sign-in signal for a sample of licensed users.
Implement: Enable usage/sign-in reporting (Microsoft 365 usage reports or Entra sign-in logs);
where richer data is needed, onboard the discovery tool from G4.

## 2.6 Procurement and finance alignment
Description: Named owners in procurement and finance, plus the renewal/true-up calendar, so position
data turns into purchasing decisions on time.
Why: True-ups and renewals have fixed windows; a known position is only valuable if a decision-maker
acts on it before the deadline.
Verify: You can name the procurement liaison and the next renewal/true-up date for the pilot scope.
Implement: Confirm roles (SAM analyst, approver, procurement liaison) per G6 and record the renewal
and anniversary/true-up dates in the register.

---
## Checklist
- [ ] Billing/admin visibility in `https://admin.microsoft.com` (License + Billing roles)
- [ ] Microsoft Graph read access — `Get-MgSubscribedSku` returns rows
- [ ] Agreement details captured (EA baseline / CSP subscriptions) from the agreement/portal
- [ ] `License Position Register – EA+CSP – Steady-State` created and seeded
- [ ] Deployment/usage signal available for utilization
- [ ] Procurement/finance owners and renewal/true-up dates known
- [ ] Pilot scope chosen (one product family or department) per G7
