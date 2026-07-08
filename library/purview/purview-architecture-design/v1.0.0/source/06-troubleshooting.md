# 6. Troubleshooting — Microsoft Purview Architecture & Design

The failure modes that make a Purview **architecture wrong, unenforceable, or drifted** — plus the
discovery, RBAC, scoping, and naming issues you'll hit standing up the foundation guardrails. Each:
**symptom → likely cause → fix.** Most "the design doesn't hold" reports are a licensing gap, an
evolving role-group/portal surface, or drift from the naming standard — this guide separates those from
real faults. Regulatory/records/legal **determinations** are out of scope here; escalate them.

## `PURVARCH-Discovery.ps1` shows a capability as unavailable / "CHECK"
- **Cause A — not licensed.** Advanced DLP, auto-labeling, insider risk, communication compliance, Audit
  Premium, DSPM, and adaptive scopes need **E5 / E5 Compliance** (some preview). The capability can't be
  designed *around* until it's licensed. **Fix:** confirm the SKU (Requirement 2.1) in the M365 admin
  center; record the capability as **deferred — not licensed** on the `PA Capability Map – Tenant – Design`
  rather than inventing a workaround.
- **Cause B — missing read role.** The discovery account can't read that object type. **Fix:** assign the
  least-privilege **read** role for that domain (Requirement 2.2) and re-run.
- **Cause C — portal-only in your tenant.** Some capability surfaces have no stable cmdlet. **Fix:** treat
  it as portal-read/attested in the design; don't assert a cmdlet you can't confirm (`Get-Command`).

## Role-group names in the design don't exist in the tenant
- **Cause:** Purview role-group names **evolve**, and many tenants now use **unified Purview RBAC** where
  the names/scoping differ from classic Security & Compliance role groups.
- **Fix:** `PURVARCH-Configuration.ps1` prints `[MISSING] role group not found` per unmatched name — do
  **not** guess. Confirm the current names in **Settings → Roles & scopes → Permissions** (verify path),
  update the `PA RBAC Model – Tenant – Design`, then re-run the dry-run before `-Commit`.

## `PURVARCH-Configuration.ps1 -Commit` grants a broad role I didn't intend
- **Cause:** the design CSV contained an `Add` to a broad role (Organization Management, Compliance
  Administrator/Data Administrator); the script **warns** but honors the row.
- **Fix:** the `[WARN] Add to BROAD role` line is your gate — review it in the dry-run. Broad roles must be
  rare and deliberate (least privilege). **Rollback:** re-run with the reverse `Action` (Add ↔ Remove) for
  that row, then re-validate separation of duties.

## Separation-of-duties conflicts appear in the RBAC validation
- **Cause:** a person administers **two** domains that must stay separate (e.g. insider risk **and**
  eDiscovery), or a reader also holds a broad admin role.
- **Fix:** `PURVARCH-Validation.ps1` emits the `PA RBAC SoD – Conflicts` register. Each conflict is
  **resolved** (remove one membership) or **accepted** with a recorded, named exception — do not leave it
  silent. Information protection ≠ insider risk ≠ eDiscovery ≠ records is the design intent.

## The pilot ring group / adaptive scope won't create
- **Cause A — Graph permission.** Creating/populating `SG-PA-Pilot` needs **Group.ReadWrite.All**; a
  dry-run only needs read. **Fix:** consent the write scope for the `-Commit` run (Requirement 2.2).
- **Cause B — adaptive scope unlicensed.** `New-AdaptiveScope` is licensing-/tenant-dependent. **Fix:**
  `PURVARCH-Set-Scope.ps1` prints `[CHECK] New-AdaptiveScope not available` when the cmdlet is absent —
  verify your plan; use a **static** scope in the design instead of inventing the capability.
- **Cause C — the example query doesn't match your directory.** The script's example scopes
  `Department = PurviewPilot`. **Fix:** adjust the `FilterConditions` to an attribute your tenant actually
  populates before `-Commit`; the example is a scaffold, not a determination.

## New capability objects don't conform to the naming standard
- **Cause:** an object was created in the portal without the `<Purpose> – <Scope> – <Stage>` convention
  (`Sim`/`Prod`), so drift is invisible until audit.
- **Fix:** `PURVARCH-Validation.ps1` lists non-conforming names against the `PA Naming Standard – Tenant –
  Design`. Renaming is per-object in the portal; route it through the roadmap remediation. The standard is
  what makes the simulation-first discipline enforceable across phases.

## A capability policy was built without piloting in simulation/test
- **Cause:** a phase solution created a DLP/label/retention/insider-risk policy directly in **enforce**,
  bypassing the architecture's pilot-first contract.
- **Fix:** this design solution builds **no** capability policy — each is owned by its own solution and
  **must** pilot in simulation/test first against this architecture. Move the policy back to
  simulation/test/unpublished, validate on the pilot ring, then expand. The naming standard (`Sim` vs
  `Prod`) makes this catchable.

## `Connect-IPPSSession` / `Connect-MgGraph` fails
- **Cause:** module not installed, or MFA/modern-auth not completed.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and `Install-Module Microsoft.Graph
  -Scope CurrentUser`; complete the interactive modern-auth sign-in (Requirement 2.3). The discovery script
  reports which endpoints connected.

## The design "drifts" between phases
- **Cause:** joiners/leavers change role membership, plans change what's licensed, or Microsoft ships
  **portal/RBAC changes** that move a surface.
- **Fix:** re-run `PURVARCH-Validation.ps1` / `PURVARCH-Report.ps1` at each phase boundary and on a
  cadence; treat the architecture as a **living document** — re-baseline periodically. Conformance of new
  objects to the RBAC model, scoping plan, and naming standard is the standing check.

## When to escalate beyond this solution
- **Regulatory applicability, retention schedules, records file plans, and the lawful basis for
  insider-risk/communication monitoring** → **compliance, records, privacy, and legal**. The architecture
  carries these decisions; it does not make them.
- **A capability's actual policy build** → its **own solution**, against this design, piloted in
  simulation/test first.
- **A role-group or portal surface that has genuinely changed** → verify against current Microsoft
  documentation; Purview RBAC and the portal evolve, and unified RBAC may be in effect in your tenant.
