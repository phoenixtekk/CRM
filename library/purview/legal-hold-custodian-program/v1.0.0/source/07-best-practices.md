# 7. Best Practices — Legal-Hold & Custodian Management Program (Microsoft Purview)

Field-tested practices for running legal holds and custodians in Microsoft Purview eDiscovery so preservation
is consistent, tracked, and **defensible** — and so the one irreversible action (releasing a hold) is never
taken by accident. These complement the Implementation and Testing guides.

## Prove it on a pilot matter before a real one depends on it
- **Never** learn the mechanics on a live matter. Run the full flow — case, hold, custodians, notice,
  tracking — on `Legal Hold Case – Contoso-Matter-001 – Pilot` with **fabricated** custodians first (Req 2.6),
  and pass the Section 5 gates before the program is the live practice.
- Mint **production** artifacts for real matters (`… – <RealMatter> – Live`); **never** edit a validated pilot
  artifact in place and **never** reuse the pilot case for a real matter.
- Treat the pilot as a **repeatable template**, not a one-off — the value is a program you run the same way
  every time a matter starts.

## Preserve first, scope later — default to everything
- When in doubt, **preserve-everything** is the safe floor; a **query-based** hold that is too narrow silently
  fails to preserve responsive content. Only narrow to a `ContentMatchQuery`/date range when **legal has
  authorized it**, and validate the query with a **statistics/estimate** run before it becomes a hold.
- A missed custodian or an un-mapped associated site is **un-preserved content** — enumerate primary
  mailbox/OneDrive **and** associated Teams/Groups and additional mailboxes/sites, and hold **non-custodial**
  locations (shared mailboxes, departmental sites) explicitly.

## Validate distribution — a hold placed is not a hold effective
- Placing a hold runs on **service timers**; **distribution status** can take minutes to hours (longer for
  many locations) to reach **Success**. Do not judge a hold in its first minutes — **validate distribution**
  with `EDHOLD-Validate.ps1` before declaring a custodian preserved.
- Confirm the hold actually preserves by proving a **hard-deleted** test item is recoverable — the hold
  prevents **permanent purge**, it does not lock the item read-only the way a record label does.

## Notice, acknowledge, remind, escalate — the evidence is the point
- Defensibility is about **proof**, not just the hold: issue the notice, require **acknowledgment**, and
  **remind/escalate** non-responders on legal's cadence — that trail is what a court or regulator expects.
- Reuse a **standard set** of notice objects (`– Issuance` / `– Reminder` / `– Escalation` / `– Release`) with
  legal's text; the program **configures and tracks** them — legal **authors** them.
- Keep the **hold register** current as the single defensible record: who is on hold, since when, noticed,
  acknowledged, reminded, escalated, released. Export it on a cadence, not just at the end.

## Release is the one irreversible act — gate it, never script it
- **Releasing a hold deletes the preservation** and cannot be undone for content purged afterward. Release
  **only** on the named **release authority's** written sign-off (Req 2.5), **in the portal**, with the
  release recorded and the `– Release` notice sent.
- **No script in this pack releases a hold** — by design. If tooling ever *could* release, a mis-run is a
  spoliation event; keeping release out of automation is the control.
- Before releasing, confirm **no other matter** still requires the same location — overlapping holds mean one
  matter's release must not un-preserve content another still needs.

## Respect the legal-vs-technical boundary
- **Legal owns the determination; the program owns the execution and the evidence.** *Whether* a duty has
  attached, *who* is a custodian, the *scope*, the notice's sufficiency, and *when* to release are
  eDiscovery-counsel calls — don't encode a legal judgement into a hold configuration.
- This program stops at **defensible preservation** — collection, review, analytics, and export are the
  downstream eDiscovery phases; hand validated, preserved custodians to whatever review/production process
  legal runs.

## Licensing & portal reality
- **Custodian management and communications are Premium (E5-class)**; **case holds** work at **E3**. Verify
  what your tenant is licensed for **before** designing a custodian program — and design a case-hold-only
  program on Standard rather than promising features the tenant can't run.
- The eDiscovery portal is **consolidating** into a new unified experience; tab names/paths (e.g. *Custodians*
  → *Data sources*) differ between classic and unified. **Verify the exact path in your tenant** — don't
  assume a UI that may have moved.
- **Commercial vs Government** clouds differ (portal URLs, `Connect-IPPSSession -ConnectionUri`, Graph
  national-cloud endpoints, feature availability in GCC/GCC High/DoD) — verify the path and feature in your
  cloud.

## Operations & governance
- Give the program an **eDiscovery Administrator** owner and **least-privilege eDiscovery Managers** per
  matter; **separate** the person who places holds from the person who authorizes release.
- Keep a **change log** of every placement, scope change, and release with the sign-off attached — the change
  record and the register together are the defensible story.
- Re-run **Discovery/Validate/Report** on a cadence: confirm distribution stays Success, catch custodians
  whose data sources changed, and keep the register current as matters age.
- Enable and retain **unified audit logging** — the tracking report and the evidence trail read from it; if
  it's off, defensibility has no source.
