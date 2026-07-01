# 7. Best Practices — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

These practices reflect the standard migration model and reduce risk, downtime, and rework. Apply them throughout the eight phases.

## Pre-stage, then delta
- **Always pre-stage the bulk copy** days or weeks before cutover while users keep working in the source. The initial full copy is the slow part; do it early.
- **Run scheduled delta passes** (e.g. nightly) so the target stays current. A short final delta in the cutover window keeps true downtime minimal.
- Treat the size of the **final delta** as a health signal — a large final delta means delta passes weren't keeping up.

## Respect Microsoft throttling
- Microsoft 365 throttles per-mailbox and per-tenant migration throughput; you **cannot** force unlimited speed. Plan wall-clock time around realistic throughput, not raw bandwidth.
- Spread large mailboxes across waves; don't schedule every multi-GB mailbox in the same pass.
- Avoid running discovery, migration, and reporting all at peak simultaneously against the same tenant.

## Wave sizing and grouping
- Keep the **`EXO T2T – Pilot Wave`** small (5–15 mailboxes) but representative — include a shared mailbox and a room/equipment mailbox.
- Group production waves by **collaboration boundary** (department/team) so people who email and share calendars daily migrate together; this minimizes cross-tenant coexistence friction.
- Size waves to what your throughput and support team can validate in the available window.

## DNS discipline (lower TTL before cutover)
- **Lower the TTL** on the MX and Autodiscover records to 300 seconds (5 min) at least **24–48 hours before** the cutover window, so the cutover propagates quickly.
- Capture the **current DNS** (MX, Autodiscover, SPF, DKIM, DMARC) before changing anything (rollback baseline, G6).
- After cutover, restore normal TTLs once stable.

## Identity, passwords, and MFA
- Mailbox content copy does **not** move passwords/identity. Plan how users get target credentials (provisioning + secure communication) and budget time for **MFA re-registration** in the target tenant.
- Exclude **`svc-quest-migration`** from MFA/Conditional Access for the migration window **only**, scoped to those accounts — never disable policies tenant-wide — and **reverse it during Decommission**.

## Coexistence
- Stand up **`Coexistence – Source→Target Connector`** and **`Coexistence – Target→Source Connector`** before migrating production users so mail reaches migrated and not-yet-migrated users correctly.
- Enable **GAL sync + free/busy coexistence** for any project spanning more than a few days or where cross-tenant scheduling matters.
- Review **forwarding rules** before coexistence to avoid mail loops.

## Permissions and delegation
- Inter-mailbox permissions (FullAccess/SendAs/SendOnBehalf) and calendar delegation do **not** migrate automatically — capture them in discovery (`permissions.csv`) and re-apply with `EXOMIG-Remediation.ps1` after each wave.
- Re-test shared mailbox and delegate access after stamping addresses.

## Communications plan
- Publish a schedule to users: what changes, when their wave moves, what to expect at cutover (possible re-auth in Outlook, mobile re-add), and where to get help.
- Use **`EXO T2T – Pilot Members`** for the pilot comms and feedback loop; refine the message before bulk waves.
- Notify the service desk before each wave and especially before cutover.

## Validation and evidence
- Gate every phase on the tests in `05-testing.md`; never advance on a broken state.
- Keep the CSV outputs of discovery, validation, and reporting as the audit trail.
- Confirm **outbound authentication** (SPF/DKIM/DMARC) from the target after cutover — a common post-cutover deliverability gap.

## Rollback posture
- Before cutover, have a written rollback: if the domain move or DNS cutover fails, you can re-point DNS to the source and (because the domain hasn't yet been re-stamped on source objects irreversibly during the staging period) keep the source operational.
- The point of **least reversibility** is removing the domain from the source; do it only after a successful final delta and with the rollback decision explicitly made.

## Tooling choice
- Use **Quest On Demand Migration for Exchange** as the primary engine for its delta and coexistence handling. If using **native MRS**, ShareGate, or BitTitan instead, keep the same phases, naming, and gates — substitute only the engine-specific steps.
