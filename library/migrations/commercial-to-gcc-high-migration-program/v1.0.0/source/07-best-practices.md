# 7. Best Practices — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Program-grade practices for a cross-cloud GCC High migration. These reduce risk, protect regulated data, and produce the evidence a CMMC/ITAR program requires.

## Program & wave planning

- **Lead with eligibility, not technology.** Confirm Microsoft validation (R1), AOS-G reseller (R2), tenant + licensing (R3), and Azure Gov subscription (R4) before any build. These gate everything and have long lead times.
- **Keep cohorts intact.** Group users, the teams/sites they collaborate on, and their dependent servers into the **same wave**. Splitting collaborators across clouds maximizes the period of painful, limited cross-cloud coexistence.
- **Pilot every workstream.** `Wave 00 – Pilot – Program` runs all seven workstreams end-to-end before any production wave; refine the schedule from real pilot timings.
- **Sequence identity first.** Nothing authenticates until the GCC High Entra directory and licensing are in place.
- **Right-size waves to your bandwidth window.** Cap each wave's GB to what the network (R9) can move and re-sync within the cutover window.

## Communications

- **Set the coexistence expectation up front.** Tell users cross-cloud free/busy, GAL, and Teams interop are **limited** until their wave cuts over — this is inherent to two separate clouds, not a defect.
- **Per-wave comms cadence:** announce → pre-cutover reminder (with the new sign-in URL `https://login.microsoftonline.us`, Outlook/Teams re-config steps, MFA re-registration) → cutover-complete confirmation.
- **Publish the new endpoints.** Users must know the `.us` URLs for Outlook, SharePoint, and Teams.

## Compliance / ITAR handling

- **Keep regulated data in an authorized boundary in transit (R13).** Confirm the migration tool's data path/region is US-sovereign; restrict migration-team access to authorized (US) persons where required; keep any staging storage inside the boundary.
- **Never export secrets in clear.** Key Vault secrets, app-registration secrets, and certificates are **re-created** in the target, not exported.
- **Treat the program register as evidence.** Named objects, change records, acceptance-gate results, and the data-flow document are directly reusable as CMMC/ITAR assessment evidence — keep them complete and dated.

## Identity discipline

- **Re-establish, don't assume sync.** There is no commercial→GCC High Entra Connect; plan cloud-only or a **new** sync agent targeting GCC High.
- **Re-create conditional access and MFA deliberately** — they do not migrate; baseline `CA – Require MFA – Target` and `CA – Block Legacy Auth – Target` before users land.
- **Use named service accounts** (`Migration SvcAcct – M365 – Source/Target`) for all tooling, not personal admin accounts — better throttling isolation and audit trail.

## Content migration (Exchange / SharePoint / Teams)

- **Pre-stage, then delta.** Run full pass-1 syncs well ahead of cutover; only a short final delta runs in the window.
- **Verify the tool's GCC High edition/endpoints** before licensing (R6/R7) — generic commercial-only tools will not target `.us`.
- **Preserve and re-map permissions**; validate sampled ACLs against the correct **target** Entra principals (T3.3).
- **Document Teams chat scope** honestly — what carries depends on tool/edition; communicate any fresh-start chat.

## Throttling

- **Expect Microsoft 365 throttling** on large content/mailbox moves. Stagger concurrency, schedule heavy passes off-hours, and let the tool back off — do not fight throttling with more threads. Size waves so deltas finish inside the window despite throttling.

## Azure servers & ASR

- **Always run a test failover before planned failover (T5.2).** An isolated test failover that boots and validates the app is non-negotiable — it is the only proof the VM will come up in Gov.
- **Replicate to 100% and keep deltas flowing** before the window; commit only after a clean planned failover.
- **Fix internal DNS/IP at cutover**, attach the correct NSGs, and validate connectivity (T5.4) before declaring done.

## PaaS

- **Redeploy via IaC**, parameterized for **AzureUSGovernment**; migrate data (DB/storage) separately and verify counts (T6.2). Re-point all config/endpoints to `.us`.

## AVD / FSLogix

- **Rebuild host pools natively** in Azure Gov; do not attempt to lift session hosts.
- **Migrate FSLogix containers, then re-point `VHDLocations`** to `FSLogix Share – Profiles – Target`. Validate a real login loads the migrated profile (T7.3) — a temp profile means the re-point failed.

## Rollback

- **Define a rollback per workstream and per cutover (R15).** For mail/DNS, keep the source tenant warm and lowered TTLs so MX can be reverted within the window. For servers, do not commit the failover until validated. Keep migrated source data **read-only, not deleted** through the grace period.
- **Grace period before decommission.** Hold the commercial estate read-only for a defined window (e.g. 30–60 days) after a wave passes before tearing it down.

## Decommission discipline

- **Validate before you delete.** No commercial resource is decommissioned until its Gov counterpart passes its acceptance gate and the grace period elapses.
- **Export retention/legal-hold data first**; decommission the commercial tenant/licenses **last** and reclaim SKUs through the original channel.

## Documentation for CMMC

- **Keep `FEATURES`/program-register, named-object list, data-flow, and acceptance results current** as you go — not at the end. A complete, dated record of who moved what, how data stayed in boundary, and how each cutover was validated is the deliverable an assessor expects.
