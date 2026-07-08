# 3. Implementation Guide — Microsoft Purview Center of Excellence

Follow these steps **in order**. The model is **Assess → Design → Configure → Pilot (simulation) →
Validate → Expand**. Governance role and tag changes are previewed with **`-WhatIf` before any
`-Commit`**; no governed policy is taken to *enforce* without passing simulation/test and board
approval. Each step names its artifacts, its pass/fail gate, and its rollback. Portal paths and cmdlets
are cited as of authoring — **verify them in your own tenant**; where a capability is unlicensed or
portal-only, govern it by attestation rather than inventing a cmdlet.

> **Determination boundary (restated).** This guide configures the *operating model* — board,
> standards, intake, lifecycle. It does not author policy contents or make retention/records/legal or
> insider-risk determinations; those are deferred to compliance, records, privacy, and legal.

---

## Phase 0 — Assess (read-only)

### Step 0.1 — Connect and confirm scope
Open Security & Compliance PowerShell and (for audit/role-membership cmdlets) Exchange Online:
```powershell
Connect-IPPSSession
Connect-ExchangeOnline          # for Get-AdminAuditLogConfig / Add-RoleGroupMember
Connect-MgGraph -Scopes "Organization.Read.All","Directory.Read.All","User.Read.All","RoleManagement.Read.Directory" -NoWelcome
```
Run the scope/health helper:
```powershell
.\OPSCOE-ScopeCheck.ps1 -UseGraph
```
It confirms sign-in, reports the compliance SKUs present, lists which governed capabilities are visible
(labels, DLP, retention, auto-labeling, communication compliance, audit), and flags unlicensed or
portal-only capabilities. Output: `Purview CoE Scope – Assess` (CSV).
**Gate:** sign-in OK and the in-remit capability list agreed. **FAIL** on any capability you intend to
govern that the script cannot see → resolve licensing/roles before proceeding.

### Step 0.2 — Inventory the estate the CoE will govern
```powershell
.\OPSCOE-Discovery.ps1 -OutPath ".\Purview-CoE-Register-Governed.csv"
```
This enumerates every readable governed artifact — sensitivity labels, label policies, DLP policies +
rules, retention policies/labels + rules, auto-labeling policies, and (where readable)
communication-compliance and audit-retention policies — and for each records its **name**, **type**,
**current state** (e.g. enabled/disabled/test/simulation where the object exposes it), and whether it
**conforms to the naming standard**. Output: `Purview CoE Register – Governed` (the raw inventory that
becomes the register).
**Gate:** the inventory runs clean and every in-remit capability is represented (licensed+readable
enumerated; portal-only flagged for attestation). Record the count and the non-conforming names — this
is the baseline the CoE will bring into standard.
**Rollback:** none — read-only.

---

## Phase 1 — Design (author the operating model)

### Step 1.1 — Author the CoE charter and board RACI
Write `Purview CoE Charter – Board`: the CoE's purpose, the **board membership** (chair + one
representative per capability), the **RACI**, the **separation-of-duties** rules, the **determination
boundary** (what the board governs vs what compliance/records/privacy/legal decide), and the **named
approvers** per capability. Map each seat to a **built-in Purview role group** (Overview §"The CoE
governance board").
**Gate:** every seat has a named owner and a mapped role group; insider-risk, communication-compliance,
and eDiscovery seats are **separate** from the chair/compliance-administration seat.

### Step 1.2 — Capture the standards baseline
Write `Purview CoE Standards – Baseline`: the **naming convention** (`<Purpose> – <Capability> –
<State>`), the **ownership + review-cadence** rule (default quarterly), the **simulation/test-first**
rule, the **change-control/versioning** rule, and the **separation-of-duties** rule. This file is the
machine-checkable contract `OPSCOE-Validate.ps1` evaluates against (it reads the naming pattern and
cadence from a small standards config).
**Gate:** the baseline exists and states the naming pattern, cadence, and each gate unambiguously.

### Step 1.3 — Define the intake workflow and the role-group matrix
Document the **intake workflow** (Request → Triage → Design → Pilot in simulation → Validate → Board
approval → Enforce → Register), the `Purview CoE Intake – Request` template, and build the **role-group
matrix CSV** (`Seat,RoleGroup,Member` rows) that `OPSCOE-ApplyStandards.ps1` consumes.
**Gate:** the workflow has an owner per stage and the matrix names every board member and their role
group.

---

## Phase 2 — Configure (pilot-first, `-WhatIf` before `-Commit`)

### Step 2.1 — Preview the board role-group membership
```powershell
.\OPSCOE-ApplyStandards.ps1 -RoleMatrixCsv ".\coe-board-matrix.csv" -WhatIf
```
The script reads the matrix and shows exactly which members it would add to which built-in role groups
(and which custom scoped groups it would create), printing the **reverse command** for each change. No
change is made.
**Gate:** the preview matches the charter exactly — least-privilege, separated, named. If it would add
anyone to an investigative role group (insider risk / communication compliance / eDiscovery) who is not
named in the charter, **STOP** and correct the matrix.

### Step 2.2 — Apply the board role-group membership
```powershell
.\OPSCOE-ApplyStandards.ps1 -RoleMatrixCsv ".\coe-board-matrix.csv" -Commit
```
Adds the named members to the built-in role groups (`Add-RoleGroupMember`) and creates any custom
scoped groups (`New-RoleGroup`) defined in the matrix. Each applied change is logged with its reverse
command.
**Gate:** `Get-RoleGroupMember` for each seat resolves to exactly the named members.
**Rollback:** run the printed reverse commands (`Remove-RoleGroupMember` / `Remove-RoleGroup`) to undo
any membership or group creation.

### Step 2.3 — (Optional) Stamp ownership/standard tags on governed artifacts
Where a governed object exposes a writable `Comment`/notes field (DLP, retention, auto-labeling
policies via `Set-DlpCompliancePolicy` / `Set-RetentionCompliancePolicy` / `Set-AutoSensitivityLabelPolicy
-Comment`), stamp a standardized ownership/standard tag so the owner and review date travel with the
object:
```powershell
.\OPSCOE-ApplyStandards.ps1 -StampOwnership -OwnerMapCsv ".\coe-owner-map.csv" -WhatIf   # preview
.\OPSCOE-ApplyStandards.ps1 -StampOwnership -OwnerMapCsv ".\coe-owner-map.csv" -Commit   # apply
```
The script only writes the `Comment` field (a non-disruptive metadata stamp of the form
`CoE-Owner=<name>; Review=<date>`); it **never** changes a policy's rules, scope, or enforcement state.
It guards `Get-Command` for each `Set-*` cmdlet and skips capabilities that are unlicensed or lack a
writable comment surface.
**Gate:** each stamped artifact's `Comment` shows the owner/review tag; no rule/scope/enforcement value
changed (re-run `OPSCOE-Discovery.ps1` to confirm states are unchanged).
**Rollback:** the script records each prior `Comment` value; re-run with `-Restore` to revert the
stamps.

> **The CoE never flips a policy to enforce.** Enforcement remains a board-gated, intake-driven action
> performed in the portal after simulation passes — not something these scripts do.

---

## Phase 3 — Pilot the intake gate (simulation/test)

### Step 3.1 — Take one artifact through intake in simulation
Pick a low-risk **pilot artifact** (`Purview CoE Pilot – Stage1`) — e.g. one DLP or auto-labeling
policy — and run it through the full intake workflow **in simulation/test mode**:
- **DLP:** create/configure the policy with **Test mode (with/without notifications)** — Purview portal
  → `Data loss prevention → Policies → New policy` → *"Test it out first"* (verify path/label in your
  tenant). Do **not** select *Turn it on right away*.
- **Auto-labeling:** create the policy in **Simulation** — `Information protection → Auto-labeling →
  New` → run in simulation before turning on.
- **Retention:** stage as **disabled**/adaptive-scope-limited before broad application.

Name it to the standard (`<Purpose> – <Capability> – Simulation`), record the owner, and capture the
simulation results as evidence.
**Gate:** the pilot artifact exists **in simulation/test**, is standard-named, has an owner, and has
recorded simulation evidence — and it is **not** enforced.
**Rollback:** delete the simulation policy (it changed nothing in enforce; simulation does not act on
content).

### Step 3.2 — Board approval on the pilot
Run the pilot through **Triage → board approval** using the intake template; record the approval on
`Purview CoE Intake – Request`.
**Gate:** the board approval is recorded before the pilot could ever be enforced.

---

## Phase 4 — Validate (see the Testing Guide for full procedures)

### Step 4.1 — Validate every governance gate
```powershell
.\OPSCOE-Validate.ps1 -StandardsConfig ".\coe-standards.json" -Register ".\Purview-CoE-Register-Governed.csv" -OutPath ".\Purview-CoE-Lifecycle-Review.csv"
```
Checks: **naming conformance** of every artifact; **every artifact has an owner** (register or stamped
`Comment`) and a **review date**; **no high-impact policy is enforced without recorded simulation
evidence**; **separation of duties** intact (no board member in a conflicting investigative role);
and the **register reconciles** to the live tenant (no orphaned or unregistered artifacts). Output:
`Purview CoE Lifecycle – Review` with a per-artifact PASS/FAIL/WARN.
**Gate:** all gates PASS (WARN allowed only with a recorded, board-accepted exception). Any FAIL is
remediated via intake before the estate is declared governed.
**Rollback:** none — read-only.

### Step 4.2 — Produce the governance scorecard
```powershell
.\OPSCOE-Register.ps1 -Register ".\Purview-CoE-Register-Governed.csv" -Validation ".\Purview-CoE-Lifecycle-Review.csv" -OutPath ".\Purview-CoE-Scorecard-Report.csv"
```
Produces `Purview CoE Scorecard – Report`: counts by capability, % naming-conformant, % owned, %
with review date, count enforced-without-evidence (target: 0), and the next-review-due list.
**Gate:** the scorecard is the board's standing artifact and the audit answer.

---

## Phase 5 — Expand (run the CoE as a standing rhythm)

### Step 5.1 — Bring the full estate under the register and cadence
Assign an owner and a review date to **every** in-remit artifact (remediating non-conforming names via
intake), register portal-only capabilities (insider risk) by attestation, and set the review cadence
(default quarterly).
**Gate:** 100% of in-remit artifacts owned and review-dated in the register.

### Step 5.2 — Operate intake, lifecycle review, and drift detection
- **Intake:** every new label/DLP/retention/auto-label/insider-risk request enters via the workflow;
  nothing reaches enforce without simulation evidence and board approval.
- **Lifecycle review:** on the cadence, re-run `OPSCOE-Discovery.ps1` + `OPSCOE-Validate.ps1` and review
  the `Purview CoE Lifecycle – Review` output at the board; decommission orphaned/unowned artifacts
  under change control (identify → confirm owner → disable → remove).
- **Drift detection:** compare each cadence's discovery against the registered baseline; new, changed,
  or orphaned artifacts are flagged and routed to intake.
**Gate:** each review cycle closes with an updated register, an updated scorecard, and zero
enforced-without-evidence artifacts.

---

## Rollback summary
| Change | Reverse |
|---|---|
| Role-group membership added (2.2) | `OPSCOE-ApplyStandards.ps1` printed `Remove-RoleGroupMember` / `Remove-RoleGroup` reverse commands |
| Ownership/standard `Comment` stamp (2.3) | `OPSCOE-ApplyStandards.ps1 -Restore` (reverts to recorded prior `Comment`) |
| Pilot simulation policy (3.1) | Delete the simulation/test policy (no content was acted on) |
| Register/scorecard files (0.2, 4.x) | Delete the CSVs — read-only artifacts |

No step in this guide enforces a Purview policy, changes a policy's rules or scope, or makes a
regulatory/records/legal determination. Enforcement is always a separate, board-gated, intake-driven
portal action taken after simulation passes.
