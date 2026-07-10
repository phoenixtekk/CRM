# Microsoft 365 Copilot Adoption & Change-Management Program

> **Version 1.0.0** · Category: Copilot · Solution code: CPLTADOPT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft 365 Copilot Adoption & Change-Management Program

White-label · Copilot

Copilot licenses do not create value; habits do. Organizations buy Microsoft 365 Copilot, assign the
seats, announce it once — and then watch usage flatline after week one. The licenses become shelfware,
the investment shows no return, and leadership starts asking why. The gap is never the technology; it
is the absence of a structured adoption program: no champions, no role-specific reasons to use it, no
training cadence, no communications rhythm, and no measurement to prove it is working.

This is a complete, deploy-it-today change-management program for driving Microsoft 365 Copilot
adoption, written for an IT or enablement lead with no formal change-management background. It is a
*program*, not a technical deployment — it turns assigned licenses into daily, role-relevant usage
through executive sponsorship, a peer-led champions network, a role-based use-case catalog, a training
curriculum, a communications cadence, and adoption analytics that prove the return, executed on a
30-60-90 day plan.

## What you get
- A plain-language Solution Overview of how adoption actually happens — sponsorship, champions,
  role-based value, training, comms, and measurement — mapped to a repeatable model.
- A Requirements Guide with verify / implement-if-missing for every prerequisite (Copilot licensing,
  a champions cohort, an executive sponsor, and the usage-reporting access that measurement needs —
  *usage-report availability varies; verify current availability in your tenant*).
- An Implementation Guide of exact, ordered steps — stand up sponsorship and champions, build the
  role-based use-case catalog, launch training and comms, run a pilot, measure, and expand on a
  30-60-90 plan. Every object you create is named and reused.
- Five PowerShell scripts (Microsoft Graph) for licensed-vs-active discovery, adoption-metrics
  reporting, program-readiness validation, a champions-roster/role-coverage builder, and a
  license-optimization (reclaim unused seats) report.
- Templates and cadences you can hand to a change lead: use-case catalog, comms calendar, training
  curriculum, and a 30-60-90 milestone plan.

## What this delivers
Copilot licenses converted into measurable daily usage — a live champions network, role-specific use
cases people actually adopt, a training and communications rhythm that sustains momentum past the
launch, and adoption analytics that prove productivity and justify the spend.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Adoption that survives past week one — Copilot moved from novelty to daily productivity, driven by
champions and sponsorship, measured against baseline, and expanded across roles on a disciplined
30-60-90 plan.


---


# 1. Solution Overview — Microsoft 365 Copilot Adoption & Change-Management Program

## Why adoption is a program, not a switch
Assigning a Copilot license enables the feature; it does not change behavior. Value comes only when
people build Copilot into how they already work — drafting in Word, summarizing threads in Outlook,
catching up on Teams meetings, analyzing in Excel, building decks in PowerPoint. That behavior change
is a *change-management* problem, and change management has a well-understood recipe: sponsorship,
champions, relevance, training, communication, and measurement. This solution packages that recipe for
Copilot. It is deliberately non-technical — the technical prerequisite (licenses, healthy M365) is
covered in the category-level global requirements; the work here is human.

## The six levers of adoption
- **Executive sponsorship.** A visible, named senior sponsor who uses Copilot, talks about it, and
  signals it is a priority. Adoption without sponsorship stalls because employees read the absence of
  leadership attention as permission to ignore it.
- **A champions network.** A cross-functional group of enthusiastic early users — at least one per
  major department — who model use cases, answer peer questions, and feed the program real friction and
  wins. Peer-led adoption outperforms top-down mandates.
- **Role-based use cases.** Generic "here's what Copilot can do" fails; "here are the five things that
  save *you*, in *your* role, an hour a week" works. The program ships a use-case catalog broken out by
  role — sales, finance, IT, HR, and executives — each use case tied to a task the person already does.
- **A training curriculum.** Short, role-relevant, repeated enablement — launch sessions, prompt
  clinics, lunch-and-learns, and self-serve guides — not a single one-time webinar.
- **A communications cadence.** A steady rhythm of tips, wins, and nudges over the first 90 days that
  keeps Copilot top-of-mind while the habit forms.
- **Adoption analytics.** Measurement that shows who is active, in which apps, and whether usage is
  growing — so the program is steered by data and the return can be proven to leadership.

## The role-based use-case catalog
The catalog is the heart of the program. For each target role it names concrete, high-value use cases:
- **Sales** — draft prospect follow-ups from a thread, summarize an account's recent activity, prep for
  a call from meeting notes and emails.
- **Finance** — summarize long reports, draft variance commentary in Excel, turn a data table into a
  first-draft narrative.
- **IT** — summarize incident threads, draft knowledge-base articles, catch up on missed change-board
  meetings.
- **HR** — draft and tailor policy and role descriptions, summarize employee-survey themes, prepare
  onboarding materials.
- **Executives** — catch up on a day of meetings and mail in minutes, draft board and all-hands
  communications, get the gist of a long document before a decision.

Each use case is a "task you already do -> the Copilot prompt or action -> the time saved" triple, so
value is obvious and immediate.

## Measurement — how you prove it worked
Adoption is measured against a baseline captured before launch. The signals:
- **Enablement vs. activation** — of the assigned licenses, how many users have *actually used* Copilot
  in the reporting window (the gap is your adoption opportunity).
- **Active usage by app** — where usage is landing (Teams, Outlook, Word, Excel, PowerPoint) so the
  program can push the under-used surfaces.
- **Trend over time** — is active usage growing week over week across the 30-60-90 window.
- **Coverage by role/department** — which cohorts are adopting and which need more champion and training
  attention.

These come from the Microsoft 365 admin center usage reports, the Copilot Dashboard in Viva Insights,
and the Microsoft Graph usage-reports API. *Usage-report and Viva Insights Copilot Dashboard
availability, retention, and the exact metrics vary by tenant, licensing, and admin settings — verify
current availability in your tenant.*

## The standard deployment model
> Assess readiness and capture the license/usage baseline, name the sponsor and stakeholders ->
> configure the program (champions network, use-case catalog, training curriculum, comms cadence,
> metrics) -> pilot with a cohort -> validate adoption against baseline -> expand org-wide on a
> 30-60-90 plan with access reviews of unused licenses. Repeatable pattern:
> Assess -> Configure -> Pilot -> Validate -> Expand.

## Benefits
- Return on the Copilot spend — licenses turned into measurable daily usage instead of shelfware.
- Durable behavior change — adoption that survives past the launch because habits, champions, and
  cadence sustain it.
- Role relevance — value framed in each team's own tasks, so uptake is faster and stickier.
- Evidence for leadership — baseline-to-current adoption metrics that justify the investment and guide
  where to double down.

## Limitations (be honest with buyers)
- This is a change-management program; it drives *adoption* of Copilot, it does not configure Copilot's
  security/data-governance guardrails (see the Copilot data-readiness and Purview solutions) — do that
  first so broad usage is safe.
- Measurement depends on usage reporting that varies by tenant and licensing (*verify availability*);
  where a signal is unavailable, the program falls back to champion-reported and survey-based measures.
- Adoption cannot exceed data readiness — if oversharing or missing labels make Copilot results poor or
  risky, fix readiness first or usage will stall on its own.


---


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


---


# Global Requirements — Copilot (category-level)

These requirements apply to every solution in the Copilot category. They are published once at the
category level so individual listings stay small. Confirm these before deploying any Microsoft 365
Copilot solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Copilot inherits the tenant's existing identity, permission, and data-governance posture. It creates
> no new access — but it surfaces everything a user already has. Treat data readiness (oversharing,
> labeling) as a prerequisite, not an afterthought, and pilot before broad enablement.

## G1. Microsoft 365 tenant with supported workloads
Description: A Microsoft 365 tenant with Exchange Online, SharePoint Online, OneDrive, and Teams in use.
Why: Copilot reasons over Microsoft Graph content across these workloads; they must be provisioned and healthy.
Verify: Microsoft 365 admin center shows the services active; users have mailboxes and OneDrive provisioned.
Implement: Provision/enable the M365 workloads and confirm users are licensed for them before adding Copilot.

## G2. Microsoft 365 Copilot licensing
Description: Microsoft 365 Copilot licenses for the target users (a prerequisite base M365 plan applies).
Why: Copilot is a per-user add-on; a user cannot use Copilot without an assigned license on a qualifying base plan.
Verify: Admin center -> `Billing -> Licenses`; confirm Copilot licenses and free seats. *Verify current base-plan prerequisites in your tenant.*
Implement: Purchase/assign Microsoft 365 Copilot licenses to the pilot cohort; assign via group where possible.

## G3. Microsoft Entra ID identity and MFA
Description: Cloud identities in Entra ID with MFA and healthy sign-in.
Why: Copilot honors identity and Conditional Access; a weak or broken identity plane undermines both access and security.
Verify: Users sign in at `https://entra.microsoft.com` resources; MFA is enforced for the cohort.
Implement: Ensure licensed, MFA-protected Entra accounts (see the Entra category solutions for identity hardening).

## G4. Data readiness — permissions & oversharing controls
Description: A known state of SharePoint/OneDrive permissions and sharing (no unmanaged broad access).
Why: Copilot can surface any content the user has access to; oversharing becomes AI data exposure.
Verify: Review sharing reports / SharePoint Advanced Management signals; run the solution's discovery script. *SAM/Restricted Content Discovery availability varies — verify in your tenant.*
Implement: Remediate broad-access sites and links before broad Copilot enablement (see the oversharing-remediation solution).

## G5. Information protection baseline (sensitivity labels)
Description: A published sensitivity-label taxonomy (even minimal) in Microsoft Purview.
Why: Labels are how you keep sensitive content out of AI processing where required and audit what Copilot uses.
Verify: Purview compliance portal -> Information Protection shows published labels.
Implement: Publish a baseline label set (see the Purview information-protection solutions) before enforcing AI guardrails.

## G6. Administrative roles
Description: Global Administrator (or scoped admin roles: SharePoint Admin, Security/Compliance Admin) for the operator.
Why: Enabling Copilot, remediating SharePoint, and configuring Purview DLP/labels require these roles.
Verify: Entra -> `Roles and administrators`; confirm the required roles.
Implement: Assign least-privilege roles for the task; reserve Global Administrator for tenant-wide changes.

## G7. Network and client readiness
Description: Supported Microsoft 365 Apps clients and network access to Microsoft 365/Copilot endpoints.
Why: Copilot experiences in Word/Excel/Outlook/Teams require current clients and connectivity.
Verify: Clients on a supported channel/build; Microsoft 365 endpoints reachable. *Verify current client requirements.*
Implement: Update the M365 Apps channel/build and allow the required endpoints.

## G8. Governance & responsible-use policy
Description: An organizational position on acceptable AI use, data handling, and auditability.
Why: Copilot generates and surfaces content; the organization must define what is acceptable and keep an audit trail.
Verify: A documented AI-use/acceptable-use policy exists; Copilot interactions are auditable (Purview audit).
Implement: Adopt an AI-use policy; enable audit/eDiscovery for Copilot. *Governance and acceptable-use determinations are the customer's compliance/legal decision — this guide covers the technical controls only.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Microsoft 365 Copilot Adoption & Change-Management Program

Follow these steps in order. This is a program, so most steps are organizational — recruiting people,
building the catalog, launching comms — with the admin-center and script steps used to assign, measure,
and validate. Portal work is in the Microsoft 365 admin center (`https://admin.microsoft.com`) and
Microsoft Entra admin center (`https://entra.microsoft.com`).

> Model: assess readiness and capture the baseline, stand up sponsorship and champions, build the
> role-based use-case catalog and training/comms, pilot with a cohort, measure adoption against the
> baseline, then expand org-wide on a 30-60-90 plan. Every object you create is named and reused.

## Step 1 — Assess readiness and capture the baseline
1. Confirm the global-requirements gate: data readiness (oversharing + labels) and governance policy
   are in place (`global-requirements-copilot.md`). Do not launch broad adoption before this.
2. Run `CPLTADOPT-Discovery.ps1` to list assigned Copilot licenses vs. users who have actually used
   Copilot — this is your **adoption baseline**. Save the output and the date.
3. Run `CPLTADOPT-LicenseOptimization.ps1` to spot assigned-but-unused seats you can reclaim and
   reassign to the pilot cohort.

## Step 2 — Name the executive sponsor and stakeholders
1. Confirm the sponsor (Requirement 2.2). Brief them on the 30-60-90 plan and their two commitments: a
   launch message and periodic visible use.
2. Identify a stakeholder per target role (sales, finance, IT, HR, exec) who will help source champions
   and tailor use cases.

## Step 3 — Build the champions network
1. Entra -> `Identity -> Groups -> All groups -> New group` -> Security ->
   `Copilot Champions Network - Tenant - Steady`. Add at least one champion per major department.
2. Run `CPLTADOPT-ChampionsRoster.ps1` to confirm role/department coverage and flag gaps.
3. Set the champions' cadence: a recurring champions sync, a shared channel for peer questions, and a
   simple way to submit wins and friction back to the program.

## Step 4 — Create the pilot cohort
1. Entra -> `Groups -> New group` -> `Copilot Adoption Pilot - Pilot - Pilot`; add licensed
   representatives of each target role.
2. Run `CPLTADOPT-Discovery.ps1` scoped to the pilot group to confirm every member is licensed (assign
   or reclaim seats as needed).

## Step 5 — Build the role-based use-case catalog
1. For each role, write 4–6 concrete use cases as "task you already do -> the Copilot prompt/action ->
   time saved" (see Solution Overview for the starter set: sales, finance, IT, HR, exec).
2. Validate each use case with that role's champion and stakeholder so it reflects real work.
3. Publish the catalog where the cohort will find it (a Teams tab or SharePoint page), and give
   champions the catalog as their coaching script.

## Step 6 — Stand up the training curriculum
1. Schedule the launch training for the pilot cohort (a short, role-relevant session, not a single
   generic webinar).
2. Add the recurring elements: a weekly prompt clinic, per-role lunch-and-learns run by champions, and
   self-serve quick guides drawn from the use-case catalog.
3. Record sessions and link them from the catalog page so new users can self-onboard.

## Step 7 — Launch the communications cadence
1. Sponsor sends the launch message (Day 0).
2. Run the 90-day comms calendar: weekly Copilot tips tied to a role use case, champion-sourced win
   stories, and gentle nudges to under-active users. Keep it steady — the habit forms in the first 90
   days.
3. Route questions to the champions channel so the network, not the help desk, carries adoption.

## Step 8 — Measure the pilot against the baseline
1. After ~2–4 weeks, run `CPLTADOPT-Report.ps1` to measure active usage, usage by app, and trend for
   the pilot cohort, and compare to the Step 1 baseline.
2. Run `CPLTADOPT-Validate.ps1` to confirm the program is fully stood up (sponsor named, champions
   group populated with coverage, pilot licensed, catalog/comms in place, measurement working).
3. Use the report to target the weak spots — an under-used app gets a focused clinic; a lagging
   department gets more champion attention. Complete the Testing Guide.

## Step 9 — Expand org-wide on a 30-60-90 plan
1. **Days 0–30 (Launch):** sponsor message; pilot cohort trained; champions active; baseline captured;
   weekly tips running. Milestone: pilot cohort activated and measured.
2. **Days 31–60 (Scale):** roll the program to the next wave of roles/departments using the same
   catalog, training, and comms; champions onboard their teams. Milestone: active usage growing
   week-over-week across waves (`CPLTADOPT-Report.ps1`).
3. **Days 61–90 (Embed):** make it business-as-usual — recurring champion syncs, monthly adoption
   report to the sponsor, and a quarterly review of unused licenses (`CPLTADOPT-LicenseOptimization.ps1`)
   to reclaim and reallocate. Milestone: adoption sustained past launch, return reported to leadership.

---
### Order of operations
`Assess + baseline -> sponsor + stakeholders -> champions network -> pilot cohort -> use-case catalog
-> training curriculum -> comms cadence -> measure vs. baseline -> expand on 30-60-90`

### Rollback / adjust
- This is a program, not a tenant configuration — there is nothing destructive to roll back. If
  adoption lags, adjust the levers: re-energize sponsorship, add champions to weak departments, sharpen
  the role use cases, or increase training/comms frequency, then re-measure with `CPLTADOPT-Report.ps1`.
- Reclaiming an unused license (`CPLTADOPT-LicenseOptimization.ps1`) is a report only — reassignment is
  done deliberately in the admin center, never automatically.


---


# 5. Testing Guide — Microsoft 365 Copilot Adoption & Change-Management Program

Run after the pilot launches (Implementation Step 8) and on the recurring monthly cadence. Because this
is a change program, the "tests" confirm the program is stood up *and* that adoption is actually moving
against the baseline.

## Test 1 — Baseline captured
Do: Run `CPLTADOPT-Discovery.ps1`.
Expected: Assigned Copilot licenses and the count/list of users who have actually used Copilot in the
window are reported — a dated baseline you can compare against later.

## Test 2 — Champions coverage is complete
Do: Run `CPLTADOPT-ChampionsRoster.ps1`.
Expected: `Copilot Champions Network - Tenant - Steady` has at least one champion per major department;
any uncovered department is flagged.

## Test 3 — Pilot cohort is licensed
Do: Run `CPLTADOPT-Discovery.ps1` scoped to `Copilot Adoption Pilot - Pilot - Pilot`.
Expected: Every pilot member holds an assigned Copilot license; unlicensed members are flagged for
assignment.

## Test 4 — Program readiness validated
Do: Run `CPLTADOPT-Validate.ps1`.
Expected: PASS for the program elements — sponsor named, champions group populated with coverage, pilot
group licensed, use-case catalog and comms cadence recorded, and measurement working.

## Test 5 — Adoption is measurable and moving
Do: Run `CPLTADOPT-Report.ps1` and compare active usage to the Test 1 baseline.
Expected: Active usage among the pilot cohort is above baseline and shows week-over-week growth; usage
by app identifies which surfaces to push next.

## Test 6 — Under-used surfaces and cohorts are identified
Do: Review the `CPLTADOPT-Report.ps1` breakdown by app and by role/department.
Expected: The report names the under-adopted apps and the lagging departments so training and champion
attention can be targeted.

## Test 7 — License optimization surfaces reclaimable seats
Do: Run `CPLTADOPT-LicenseOptimization.ps1`.
Expected: Assigned-but-unused Copilot seats are listed as reclaim/reallocation candidates with
days-since-last-use.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass; pilot active usage is above baseline and growing |
| Expand pass | Tests 2–6 pass across waves; adoption sustained month-over-month; unused-license review (Test 7) on a schedule |

> Note: where a usage signal is unavailable in your tenant (*verify availability*), substitute
> champion-reported and survey-based measures for that test and record the substitution.


---


# 6. Troubleshooting Guide — Microsoft 365 Copilot Adoption & Change-Management Program

Use `CPLTADOPT-Discovery.ps1` for the license/usage baseline, `CPLTADOPT-Report.ps1` for adoption
metrics, `CPLTADOPT-Validate.ps1` for program readiness, `CPLTADOPT-ChampionsRoster.ps1` for champion
coverage, and `CPLTADOPT-LicenseOptimization.ps1` for idle seats.

## A. Usage reports are empty, missing, or show no names
| Symptom | Cause | Remediation |
|---|---|---|
| `Reports -> Usage -> Microsoft 365 Copilot` shows no data | Reporting not yet populated, or Copilot usage report unavailable in the tenant | Allow for report latency; confirm the Copilot usage report is available for your tenant/licensing (*usage-report availability varies — verify current availability in your tenant*) |
| User names appear as anonymized IDs | `Reports -> Settings -> Display concealed user names` is off (privacy default) | An admin can toggle it on if policy allows — this is a governance decision for the customer; otherwise report at the aggregate/cohort level |
| `CPLTADOPT-Report.ps1` / `-Discovery.ps1` returns no rows | Graph usage-report endpoint/scope unavailable or not consented | Confirm `Reports.Read.All` is consented; *verify the current Copilot usage-report Graph endpoint name in your tenant*; fall back to the admin-center report or Viva Copilot Dashboard |

## B. Licenses assigned but usage is flat
| Symptom | Cause | Remediation |
|---|---|---|
| High assigned count, low active count | Enablement without adoption — the core problem this program solves | Work the levers: confirm sponsor visibility, add champion attention to the cohort, sharpen the role use cases, and increase training/comms frequency; re-measure |
| Usage concentrated in one app (e.g. Teams) only | Users haven't discovered value in the other surfaces | Run a focused prompt clinic and publish the role use cases for the under-used apps (Word/Excel/Outlook/PowerPoint) |
| A whole department is not adopting | No champion or no relevant use cases for that team | `CPLTADOPT-ChampionsRoster.ps1` will flag the gap — recruit a champion there and tailor the use-case catalog to their work |

## C. Champions network is not working
- If champions are inactive, check they have time allocated and a clear ask (model use cases, answer
  peers, submit wins/friction). A champion with no cadence and no recognition disengages. Reinforce the
  recurring sync, the shared channel, and public recognition of their wins.

## D. Data readiness is blocking good results
- If Copilot results are poor or users worry about seeing content they shouldn't, adoption stalls
  regardless of the program. This is a data-readiness problem, not an adoption one — pause broad
  expansion and complete oversharing remediation and the sensitivity-label baseline (global
  requirements G4/G5; see the Copilot data-readiness / Purview solutions) first.

## E. Sponsor engagement fading
- If usage plateaus after launch, sponsorship has usually gone quiet. Bring the sponsor the monthly
  adoption narrative (baseline-to-current from `CPLTADOPT-Report.ps1`) and a champion win story, and ask
  for one visible message — renewed sponsorship restarts momentum.

## F. Script/connection issues
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Reports.Read.All`, `User.Read.All`, `Group.Read.All`, `Organization.Read.All` |
| Group-scoped scripts return nothing | Wrong group name/ID | Confirm `Copilot Adoption Pilot - Pilot - Pilot` / `Copilot Champions Network - Tenant - Steady` exist and pass the correct `-GroupId`/name |

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Reports.Read.All','User.Read.All','Group.Read.All','Organization.Read.All' -NoWelcome
# Copilot usage (user detail) — *verify current endpoint/period support in your tenant*
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')"
# assigned Copilot licenses (match the Copilot service plan/SKU in your tenant)
Get-MgUser -All -Property displayName,assignedLicenses,userPrincipalName
```

## H. When to pause the program
If broad data readiness is not actually in place (oversharing unaddressed, no label baseline), stop
expanding adoption and remediate readiness first — driving more usage over an ungoverned data estate
increases AI data-exposure risk. Adoption resumes once the gate is met.


---


# 7. Best Practices — Microsoft 365 Copilot Adoption & Change-Management Program

- Sponsorship first, and make it visible. A named senior sponsor who actually uses Copilot and talks
  about it is the strongest predictor of adoption; a quiet sponsor is no sponsor.
- Lead with role relevance, not features. "Here are five things that save *you* an hour a week" beats
  "here's everything Copilot can do." Frame every use case in the person's own recurring tasks.
- Let champions carry it. Peer-led adoption sticks where mandates bounce off — recruit at least one
  champion per department, give them the use-case catalog as a coaching script, and route peer questions
  to them, not the help desk.
- Train little and often. Replace the single launch webinar with a cadence — launch session, weekly
  prompt clinic, per-role lunch-and-learns, and self-serve guides — because habits form through
  repetition.
- Keep the comms rhythm for a full 90 days. The habit forms in the first quarter; a steady stream of
  tips, wins, and nudges keeps Copilot top-of-mind until it becomes automatic.
- Measure against a baseline and steer by the data. Capture enablement-vs-active before launch, then
  track active usage, usage by app, trend, and coverage — and push the weak surfaces and lagging
  cohorts specifically.
- Fix data readiness before you scale usage. Copilot surfaces whatever a user can already access; if
  oversharing or missing labels make results poor or risky, adoption stalls on its own — do readiness
  first (it is the gate, not this program's job).
- Reclaim and reallocate idle seats. Review assigned-but-unused licenses on a schedule and move them to
  people who will use them; idle seats are pure cost with zero adoption.
- Celebrate wins publicly. Champion-sourced "this saved me a morning" stories are the best marketing;
  surface them in the comms cadence and to the sponsor.
- Report the return to leadership. Turn the baseline-to-current adoption metrics into a simple monthly
  narrative for the sponsor — it justifies the spend and keeps sponsorship engaged.

## Where to go next
- **Copilot data readiness / oversharing remediation** — the gate before broad adoption; ensure Copilot
  only surfaces what it should (Copilot and Purview solutions).
- **Microsoft Purview Information Protection (sensitivity labels)** — keep sensitive content correctly
  handled as Copilot usage grows.
- **Copilot governance & auditability (Purview)** — audit and eDiscovery for Copilot interactions per
  your acceptable-use policy.
- **Viva Insights / Copilot Dashboard** — deepen measurement of adoption impact and productivity over
  time (*verify availability in your tenant*).


---


# 8. Deliverables Summary — Microsoft 365 Copilot Adoption & Change-Management Program

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The six levers of adoption, the role-based use-case catalog, and how adoption is measured |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (licenses, sponsor, champions, pilot, usage reporting) |
| Global Requirements (Copilot) | Category-wide prerequisites, published once (tenant, licensing, identity, data readiness, governance) |
| 3. Implementation Guide | Exact, ordered steps (assess + baseline, sponsor, champions, pilot, use-case catalog, training, comms, measure, expand on 30-60-90) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues (low usage, missing reports, stalled cohorts) and remediation |
| 7. Best Practices | Field-proven recommendations + where to go next |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CPLTADOPT-Discovery.ps1` | Baseline of assigned Copilot licenses vs. users who have actually used Copilot (enablement vs. activation) via Microsoft Graph usage reports (read-only; *usage-report availability varies — verify*) |
| `CPLTADOPT-Report.ps1` | Adoption-metrics report — active usage, usage by app, trend, and coverage by role/department against the baseline (read-only) |
| `CPLTADOPT-Validate.ps1` | Confirms the program is stood up — sponsor, champions coverage, pilot licensing, and that measurement works (read-only) |
| `CPLTADOPT-ChampionsRoster.ps1` | Builds and checks the champions network group and flags departments with no champion coverage (read-only) |
| `CPLTADOPT-LicenseOptimization.ps1` | Lists assigned-but-unused Copilot seats as reclaim/reallocation candidates with days-since-last-use (read-only report) |

## Program templates included
- Role-based use-case catalog starter (sales, finance, IT, HR, executive).
- 90-day communications calendar outline.
- Training-curriculum outline (launch session, prompt clinic, lunch-and-learns, self-serve guides).
- 30-60-90 day adoption plan with milestones.

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Copilot licenses converted into measurable daily usage — a champions network, role-specific use cases,
a training and communications rhythm, and adoption analytics that prove the return — adoption that
survives past week one, expanded across roles on a disciplined 30-60-90 plan.
