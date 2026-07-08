# 7. Best Practices — Microsoft Purview Center of Excellence

Field-proven recommendations for running a Purview CoE that stays useful instead of becoming shelfware.

## Govern the operating model, not the determinations
- The CoE's job is **board, standards, intake, lifecycle, evidence** — not retention schedules, records
  file plans, legal holds, or insider-risk case outcomes. Keep the **determination boundary** written
  into the charter and referenced whenever a request blurs it. The moment the CoE starts *deciding*
  regulatory questions instead of *governing how they are implemented*, it has overreached.
- Every governed artifact should trace to a **stakeholder-owned requirement** (a compliance obligation,
  a records schedule, a data-protection intent) — the CoE ensures it is named, owned, simulated, and
  reviewed; the stakeholder owns *why it exists*.

## Make simulation-first non-negotiable
- The single most valuable rule in the whole CoE is: **no DLP, auto-labeling, retention, or
  insider-risk policy is enforced without recorded simulation/test evidence and board approval.** Most
  catastrophic Purview incidents (blocked mail, mass encryption, unexpected deletion, employee flags)
  come from skipping simulation.
- Keep the **evidence** with the artifact, not in someone's inbox — a register entry linking to
  simulation results and the board approval is the audit answer. `enforced-without-evidence = 0` is the
  CoE's flagship metric.

## Least privilege and separation of duties, enforced on the CoE itself
- The CoE preaches least privilege — so **run it that way**. The chair holds Compliance Administrator,
  not Global Administrator; investigative seats (insider risk, communication compliance, eDiscovery)
  are **separate**, minimal, and named. A CoE administered from a blanket Global Admin has no
  credibility.
- Prefer **built-in role groups**; create custom scoped groups only where you genuinely need tighter
  scope. Fewer, well-understood groups beat a sprawl of bespoke ones.
- For insider risk and communication compliance, apply **privacy-by-design** (pseudonymization where
  the capability supports it) in that capability's own solution, and defer *who may hold the role* to
  HR, privacy, and legal.

## Standardize names so the estate reads itself
- Enforce `<Purpose> – <Capability> – <State>` on every artifact. A name like
  `Financial Data – DLP – Simulation` tells you what it protects and that it is not yet enforced —
  without opening it.
- Renaming a live policy is a **change**, not a cleanup — route it through intake, recreate under the
  standard, and retire the old one under change control. Never bulk-rename enforced policies out of
  band.

## Stamp ownership onto the object where you can
- Use the non-disruptive `Comment` stamp (`CoE-Owner=…; Review=…`) on DLP/retention/auto-labeling
  policies so the owner and review date travel with the object and survive a register mishap. Never let
  the stamp script touch rules, scope, or enforcement state — it writes metadata only.
- For portal-only capabilities (insider risk especially), govern by **attestation** in the register
  with a named owner — do not invent a cmdlet to enumerate what the platform does not expose.

## Run a real cadence, or the register rots
- A register that is never reconciled is worse than none — it lies. Run **discovery + validate on a
  fixed cadence** (default quarterly), review the output **at the board**, and act on drift.
- **Drift detection** is the early-warning system: any artifact in the tenant but not the register is
  an out-of-band change; any registered artifact gone from the tenant is an unrecorded decommission.
  Both route to intake.
- **Decommission deliberately**: identify orphaned/unowned → confirm no owner claims it → disable →
  observe → remove, all under change control. Deleting a retention or DLP policy can have compliance
  consequences — confirm with the stakeholder first.

## Keep the CoE lightweight enough to survive
- The intake workflow must be **fast for low-risk changes** or people will route around it. Triage
  should fast-track obviously low-risk requests and reserve full board review for high-impact ones — a
  gate everyone bypasses governs nothing.
- Automate the boring parts (discovery, validation, scorecard) so board time is spent on **decisions**,
  not data gathering. The scripts exist so the board reviews a scorecard, not a raw tenant.

## Assume the portal will change
- Microsoft is actively evolving the Purview portal and moving role management toward a unified Purview
  RBAC model. **Verify portal paths and cmdlet availability each cycle**; the scripts guard
  `Get-Command` and skip what is unavailable rather than failing. When a path moves, update the charter
  and standards references — do not assume last quarter's screenshot still holds.

## Protect the evidence and the credentials
- Never store credentials or secrets in scripts or the register — every script uses interactive
  modern-auth. The register and scorecard may list policy **names and owners**; they must **not**
  contain policy contents that are themselves sensitive, nor any employee case data.
- Treat the governance artifacts (charter, register, scorecard, evidence) as the **audit trail** —
  version them, retain them per your own records schedule, and keep them where the board (not the whole
  tenant) can read them.
