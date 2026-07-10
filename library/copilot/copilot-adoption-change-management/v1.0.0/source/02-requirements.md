# 2. Requirements Guide — Microsoft 365 Copilot Adoption & Change-Management Program

Verify every requirement before launching. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites (M365 tenant, Copilot licensing, identity/MFA, data
readiness, information-protection baseline, governance policy) are in `global-requirements-copilot.md`
— do not repeat them here; confirm them first.

## 2.1 Copilot licenses assigned to the target cohort
Description: Microsoft 365 Copilot licenses actually assigned to the pilot cohort and the roles you
will onboard (not just purchased seats sitting unassigned).
Why: Adoption is measured as *usage of assigned licenses*; unassigned seats cannot adopt and distort
the baseline.
Verify: M365 admin center -> `Billing -> Licenses` (Copilot free vs. assigned) and
`Copilot` page; run `CPLTADOPT-Discovery.ps1` for assigned-vs-active. *Verify current base-plan
prerequisites in your tenant.*
Implement: Assign Copilot licenses to the pilot cohort (prefer group-based assignment); reclaim and
reassign unused seats with `CPLTADOPT-LicenseOptimization.ps1`.

## 2.2 Executive sponsor
Description: A named, senior executive sponsor for the program who will use Copilot visibly and
communicate its priority.
Why: Sponsorship is the single strongest predictor of adoption; without it the program reads as
optional and stalls.
Verify: A sponsor is named and has agreed to a launch message and periodic visible use.
Implement: Recruit a sponsor (ideally in an early use-case role such as an executive); brief them on
the 30-60-90 plan and their two commitments — a launch message and ongoing visible use.

## 2.3 Champions cohort
Description: A cross-functional group of early-adopter champions — at least one per major department
(sales, finance, IT, HR, plus others) — recorded as the group `Copilot Champions Network - Tenant - Steady`.
Why: Peer-led adoption outperforms top-down rollout; champions model use cases, unblock peers, and feed
back friction and wins.
Verify: Entra -> `Groups`; `Copilot Champions Network - Tenant - Steady` exists with per-department
members. Run `CPLTADOPT-ChampionsRoster.ps1` to check role/department coverage.
Implement: Recruit champions, add them to the group, and build the roster with
`CPLTADOPT-ChampionsRoster.ps1`.

## 2.4 Pilot cohort
Description: A representative pilot group `Copilot Adoption Pilot - Pilot - Pilot` — a manageable
cross-role set of licensed users to run the program on first.
Why: Every change is proven on a pilot before org-wide expansion, and the pilot produces the first
adoption evidence.
Verify: Entra -> `Groups`; the pilot group exists with licensed members spanning the target roles.
Implement: Create the group, add licensed representatives of each role, and confirm licenses with
`CPLTADOPT-Discovery.ps1`.

## 2.5 Usage-reporting access (measurement)
Description: Access to Copilot usage signals — M365 admin center usage reports, the Copilot Dashboard
in Viva Insights, and/or the Microsoft Graph usage-reports API.
Why: The program is steered by adoption data (enablement vs. active, usage by app, trend, coverage);
without measurement you cannot prove the return or target where to push.
Verify: M365 admin center -> `Reports -> Usage -> Microsoft 365 Copilot` shows data; a test call to the
Graph usage-reports endpoint returns rows; run `CPLTADOPT-Report.ps1`. *Usage-report and Viva Insights
Copilot Dashboard availability, retention, concealed-user-name settings, and exact metrics vary by
tenant and licensing — verify current availability in your tenant.*
Implement: Ensure a `Reports Reader` (or higher) role for the operator; if report names are concealed,
an admin can toggle `Reports -> Settings -> Display concealed user names` (governance decision); for
Viva Insights confirm the Copilot Dashboard is available and provisioned.

## 2.6 Data readiness confirmed (gate)
Description: Confirmation that Copilot data readiness — oversharing controls and a sensitivity-label
baseline — is in place (global requirements G4/G5) before broad enablement.
Why: Copilot surfaces whatever a user can already access; poor readiness makes results risky or
low-quality and adoption stalls on its own. Readiness is a gate, not part of this program's scope.
Verify: The oversharing and information-protection prerequisites in `global-requirements-copilot.md`
are met (see the Copilot data-readiness / Purview solutions).
Implement: Complete data readiness first (separate solutions); this program assumes it is done.
*Data-classification and acceptable-AI-use determinations are the customer's compliance/legal decision.*

## 2.7 Microsoft Graph PowerShell SDK (for the scripts)
Description: The Microsoft Graph PowerShell SDK on the operator workstation, consented to the read
scopes the reporting scripts use.
Why: Discovery, reporting, validation, and license optimization read license assignments and Copilot
usage reports through Microsoft Graph.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a test
`Connect-MgGraph` succeeds.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; the scripts request least privilege —
`Reports.Read.All`, `User.Read.All`, `Group.Read.All`, `Organization.Read.All` (read-only). *Verify the
current Copilot usage-report Graph endpoint/scope names in your tenant.*

---
## Checklist
- [ ] Copilot licenses assigned to the pilot cohort and target roles (*verify base-plan prerequisites*)
- [ ] Executive sponsor named and committed to launch message + visible use
- [ ] `Copilot Champions Network - Tenant - Steady` created with per-department coverage
- [ ] `Copilot Adoption Pilot - Pilot - Pilot` created with licensed, cross-role members
- [ ] Usage-reporting access confirmed (admin reports / Viva Copilot Dashboard / Graph) — *verify availability*
- [ ] Data readiness (oversharing + labels) confirmed as a gate (global reqs G4/G5)
- [ ] Microsoft Graph PowerShell SDK installed and consented
