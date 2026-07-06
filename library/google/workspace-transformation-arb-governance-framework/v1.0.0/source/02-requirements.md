# 2. Requirements Guide — Architecture & Design Review Board (ARB) Governance Framework

Verify every requirement before you charter the board or open a gate. Each entry follows:
Description · Why · Verify · Implement-if-missing. Category-wide prerequisites (Workspace/Cloud
Identity tenant, source M365/Entra, DNS control, identity source of truth, pilot scope and change
control, security/compliance stakeholders) are in `global-requirements-google.md` — confirm those
first; the items below are specific to standing up the ARB.

## 2.1 Executive sponsorship and a mandate
Description: A named executive sponsor (typically the enterprise architect owner, CIO/CTO delegate,
or transformation lead) who charters the board and backs its decision rights.
Why: An ARB governs by authority. Without a sponsor whose backing makes "Rejected" stick, the board
is advisory only and drift returns. Sponsorship is the single most important prerequisite.
Verify: You can name the sponsor and point to a written mandate (email, program charter, or steering
minutes) that grants the board decision authority over design.
Implement: Secure a sponsor and a one-paragraph mandate before the first board meeting; the mandate
is quoted verbatim in the `ARB Charter - Transformation - Ratified`.

## 2.2 A ratified target architecture (the approved standards baseline)
Description: A ratified target-architecture standard for the Google Workspace + Gemini estate — the
identity/sync model, security/DLP baseline, collaboration and data-residency decisions, Gemini
adoption posture, and migration patterns — that the board measures submissions against.
Why: A review gate with no standard behind it cannot make a defensible decision; conformance is
meaningless without a baseline. This is the reference every gate uses.
Verify: A target-architecture document (or blueprint solution) exists and its key standards can be
expressed as `Standard,ExpectedValue` rows for `GWARB-Validation.ps1`.
Implement: If none exists, the board's first ratified act is to adopt one (or the program's
target-architecture blueprint) as the baseline. Do not open conformance gates until it is ratified.

## 2.3 Board membership and decision rights defined
Description: A defined membership — voting members (quorum-bearing decision-makers: enterprise
architecture, security, identity, and a business/change representative) and advisory reviewers
(subject-matter experts who review but do not vote) — with the quorum and the approve/reject
authority written down.
Why: Decision rights are the substance of the board. Who votes, what quorum is, and who may
approve/reject must be unambiguous, or decisions are challengeable.
Verify: You can name the voting members, the quorum number, and the escalation path for a tie or a
blocked decision.
Implement: Define the roster in the charter and provision the two membership groups with
`GWARB-Set-ScopeTargeting.ps1` (`ARB - Voting Members - Board`, `ARB - Advisory Reviewers - Panel`).

## 2.4 The vendor/enterprise authority boundary
Description: A written boundary stating that the enterprise owns the architecture and approves
designs, while the delivery partner/vendor executes within approved designs and submits changes to
the board.
Why: The most common transformation drift is vendor-led architecture. The boundary is what gives the
board authority over a party it does not manage day to day.
Verify: The delivery contract or SOW (or a governance addendum) references the ARB's approval rights;
the vendor's leads know they submit designs to gates.
Implement: Add a governance clause to the SOW/engagement or a signed governance addendum before the
partner begins design work; restate the boundary in the charter.

## 2.5 A tracking tool for submissions and decisions
Description: A controlled place to track submissions, gate state, and decision records — a Microsoft
List / SharePoint list, a work-tracker, or a governed spreadsheet — that the scripts can read/export.
Why: The board runs on a queue and a register; without a single tracked source, submissions get lost
and decisions are not recorded.
Verify: A tracker exists with, at minimum, columns for DesignId, Gate, State, Workstream,
DecisionRecordId, Submitted, and Owner (the columns `GWARB-Discovery.ps1` reads).
Implement: Stand up the tracker (a Microsoft List is convenient because `GWARB-Discovery.ps1` and
`GWARB-Remediation.ps1` can read/write it via Microsoft Graph) and the `Decision Register -
Transformation ARB - Program-Wide`.

## 2.6 Microsoft Graph access for the board's tooling (read-only for reads)
Description: The ability to run Microsoft Graph PowerShell with `Sites.Read.All` (to read a
Microsoft List tracker) and `Group.ReadWrite.All` + `User.Read.All` (to provision the membership
groups). Write scopes (`Sites.ReadWrite.All`) are needed only when the remediation script creates
action items.
Why: The discovery, report, and remediation scripts read the tracker and manage the ARB groups; reads
are least-privilege and read-only.
Verify: `Connect-MgGraph -Scopes 'Sites.Read.All'` succeeds and you can read the tracker list; the
membership groups can be enumerated.
Implement: Install the Microsoft Graph PowerShell SDK (`Install-Module Microsoft.Graph -Scope
CurrentUser`) and consent the least-privilege scopes; grant write scopes only to the operator who
runs remediation.

## 2.7 A meeting cadence and secretariat
Description: A regular board cadence (for example, weekly gate reviews with an out-of-band fast-track
for urgent designs) and a named secretariat who runs the queue, publishes decisions, and maintains
the register.
Why: Governance that meets irregularly becomes the schedule bottleneck delivery teams route around.
A predictable cadence and an owner keep time-in-gate low.
Verify: A recurring meeting exists on the calendar with an agenda template, and a secretariat is
named.
Implement: Schedule the cadence, appoint the secretariat, and adopt the agenda/decision templates
from the Implementation Guide.

---
## Checklist
- [ ] Executive sponsor and written mandate secured (2.1)
- [ ] Target architecture ratified as the approved standards baseline (2.2)
- [ ] Voting members, advisory reviewers, quorum, and escalation defined (2.3)
- [ ] Vendor/enterprise authority boundary written into SOW/addendum (2.4)
- [ ] Submission/decision tracker and `Decision Register` stood up (2.5)
- [ ] Microsoft Graph access confirmed (least-privilege reads) (2.6)
- [ ] Board cadence scheduled and secretariat named (2.7)
- [ ] Pilot workstream chosen for the first governance cycle (global G5)
