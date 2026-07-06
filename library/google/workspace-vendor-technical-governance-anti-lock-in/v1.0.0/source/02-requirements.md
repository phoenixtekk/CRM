# 2. Requirements Guide — Vendor Technical Governance & Anti-Lock-In Playbook

Verify every requirement before running the governance gate. Each entry: Description / Why /
Verify / Implement-if-missing. Category-wide prerequisites are in `global-requirements-google.md`.

## 2.1 Named enterprise architectural authority
Description: A named enterprise architect (or a small architecture-authority group) empowered to
disposition vendor designs — Approve, Approve-with-conditions, or Reject — and whose sign-off is a
required gate before a design proceeds to build.
Why: The whole method rests on architectural authority being held by the enterprise, not delegated
to a vendor. Without a named authority with real sign-off power, the gate is advisory and gets
overridden by schedule pressure.
Verify: Confirm the role exists, is named in the program governance, and its sign-off is a
documented precondition for build.
Implement: Name the authority in the program charter; make the design-authority gate a mandatory
step in the delivery process (see Implementation Step 2).

## 2.2 Target Architecture Baseline
Description: The enterprise's own written statement of the intended end state — identity model,
data-ownership position, sanctioned integration patterns, the standards designs must conform to,
and the required exit posture.
Why: Every vendor design is reviewed *against this baseline*. Without it, reviews default to the
vendor's assumptions and there is nothing to hold a design to.
Verify: A Target Architecture Baseline document exists and is version-controlled; it states the
identity, data-ownership, integration, standards, and exit positions.
Implement: Author the baseline (the Google Workspace / Gemini target architecture blueprint is the
natural source); if none exists, capture at least the four anti-lock-in positions (§3) before the
first review.

## 2.3 Anti-Lock-In Criteria adopted
Description: The fixed, four-part bar every design must pass — **portability**, **data ownership**,
**standards conformance**, and **exit criteria** — adopted as enterprise policy, not negotiated per
design.
Why: A consistent bar applied to every design is what stops lock-in accumulating; a bar that is
re-argued each time is no bar at all.
Verify: The criteria are documented and referenced by the review process; `GWVEND-Validation.ps1`
scores a design register against them.
Implement: Adopt the criteria in §3 as-is; tailor thresholds to the enterprise's risk posture and
publish them.

## 2.4 Governance RACI
Description: A one-page RACI that assigns Responsible / Accountable / Consulted / Informed for each
decision type, drawing the line between **vendor execution responsibility** and **enterprise
architectural authority**.
Why: The execution-vs-authority separation only holds if it is written down; ambiguity is where
authority quietly migrates to whoever is doing the work.
Verify: A RACI exists, is agreed with the partners, and names the enterprise as Accountable for
architectural disposition and the vendors as Responsible for execution.
Implement: Adopt the RACI in §3; review and sign it with each partner at engagement start.

## 2.5 Vendor design register (inventory source)
Description: A single register of the vendor deliverables and designs in flight — design documents,
proposed integration patterns, migration approaches — each with its owner (which partner), its
status, and its review disposition. Maintained as a structured file (CSV/JSON) the scripts can read.
Why: You cannot govern designs you have not inventoried; on a multi-partner program, designs arrive
faster than any one person tracks by memory.
Verify: Run `GWVEND-Discovery.ps1`; confirm it enumerates the register and any vendor-created
objects it can read in the source environment, with owner and status.
Implement: Stand up the register (see Implementation Step 1); seed it from the current in-flight
vendor deliverables.

## 2.6 Escalation path
Description: A defined path for handling a design the enterprise cannot approve — how a rejected or
conditioned design is escalated, who arbitrates a partner disagreement, and how a time-boxed
exception is granted and tracked.
Why: A gate with no escalation path becomes a bottleneck that gets bypassed. The path is what keeps
the gate authoritative *and* the program moving.
Verify: The escalation and exception process is documented and agreed with the partners.
Implement: Adopt the escalation ladder in §3 and record it in the program governance.

## 2.7 Microsoft Graph PowerShell SDK (for source-environment recon)
Description: The Microsoft Graph PowerShell SDK on the operator workstation, with consent to the
read scopes the scripts use, for the coexistence/migration solutions where vendors create objects
in the source Microsoft 365 / Entra environment.
Why: Discovery and validation read vendor-created enterprise apps, groups, and configuration in the
source tenant to cross-check the design register against what has actually been built.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; a test
`Connect-MgGraph` succeeds.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser`; the scripts request the least
privilege they need (`Application.Read.All`, `Directory.Read.All`, `Policy.Read.All`, and — only
for the scope helper's create mode — `Group.ReadWrite.All`).

## 2.8 A pilot design and change control
Description: A first, representative vendor design to run the review method on, and a change-control
process so the governance gate is inserted into production delivery under control.
Why: Every rollout follows Assess -> Configure -> Pilot -> Validate -> Expand; the pilot proves the
method on one design before it gates every workstream.
Verify: A named pilot design exists and a change/approval path is available.
Implement: Pick a representative in-flight design; agree the change-control insertion of the gate
with the program (see Implementation Step 3).

---
## Checklist
- [ ] Named enterprise architectural authority with real sign-off power
- [ ] Target Architecture Baseline authored and version-controlled
- [ ] Anti-Lock-In Criteria (portability, data ownership, standards, exit) adopted as policy
- [ ] Governance RACI agreed and signed with each partner
- [ ] Vendor design register stood up — `GWVEND-Discovery.ps1`
- [ ] Escalation and exception path documented and agreed
- [ ] Microsoft Graph PowerShell SDK installed and consented (for source-env recon)
- [ ] Pilot design selected and change-control insertion agreed
