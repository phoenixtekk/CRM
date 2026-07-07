# Executive Summary — File-Share & On-Prem SharePoint → SharePoint Online Migration

**Outcome.** Legacy file servers and on-premises SharePoint content are moved into SharePoint Online
**cleanly** — assessed and remediated, mapped to a governed target information architecture, migrated
with permissions intact, and validated with evidence — so content lands **organized and governed**,
not as a cloud copy of the old mess. The result is retired file servers and on-prem farms, lower
infrastructure cost and risk, and content that people can actually find and that the business can
actually govern.

**The problem it solves.** The tempting shortcut — drag everything up with a copy tool — recreates
every legacy problem in a platform where they cost more and are harder to fix: broken permissions,
folders nested past the platform's limits, filenames SharePoint rejects, oversized files that fail
mid-copy, and no owner for anything. Migrations that skip assessment discover these failures at scale,
on cutover night, and slip by weeks.

**The approach.** A repeatable, **pilot-first** method using only supported Microsoft tooling
(**Migration Manager** and the **SharePoint Migration Tool / SPMT**) and PowerShell:

1. **Assess** the source for the blockers that fail SPO migrations (path/URL length, invalid
   characters, blocked types, oversized files, permission surface).
2. **Design** a governed target IA and a permission map (source principals → SPO/M365/Entra groups),
   resolving every principal rather than guessing.
3. **Configure** the migration tool from the map (bulk tasks, migrate-permissions settings).
4. **Pilot** one representative scope end-to-end using **pre-stage + delta** — the bulk copy runs
   while users keep working, and only the changes move during a short read-only cutover window.
5. **Validate** with counts, a permission spot-check, and a delta-clean check — an explicit pass/fail
   gate — then **Expand** wave by wave, retiring each source only after its gate passes.

**Why it's low-risk.** The source stays **authoritative and read-only** — never destroyed — until each
wave's validation gate passes, so rollback is simply lifting the freeze and redirecting users back.
Assessment, permission-mapping, and validation are **read-only**; the only data-moving step is gated
behind an explicit `-Commit`. Pre-stage + delta shrinks the downtime window from days to hours.
Compliance and legal determinations (retention, legal hold, records schedules) remain with the
organization's compliance function — this solution provides the technical method and the evidence, not
the determination.

**What's included.** Solution overview, requirements guide, step-by-step implementation, testing/
validation procedures, troubleshooting, best practices, and **five PowerShell tools** — source
assessment, permission mapping, task builder + runner (safe-by-default), post-migration validation,
and a scope/health helper — all read-only or dry-run by default, with no credentials in code.

**Bottom line.** Legacy content moved to SharePoint Online the right way — assessed and remediated,
mapped to a governed target IA, migrated with permissions and validated — organized, not a cloud
repeat of the mess.
