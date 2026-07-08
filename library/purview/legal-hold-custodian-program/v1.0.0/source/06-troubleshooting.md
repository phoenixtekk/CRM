# Troubleshooting — Legal-Hold & Custodian Management Program

Work the symptom to the most specific cause below. All checks are read-only; never release or delete a
hold to "test" — use `EDHOLD-Validate.ps1` and the portal to confirm state. Legal-hold *scope and release*
decisions are the legal team's; this guide covers the technical configuration only.

## The hold saves but content isn't preserved
- **Symptom:** a `Legal Hold Case – <Matter> – Pilot` case hold shows created, but a custodian's edited/deleted
  items are still gone.
- **Most likely:** the hold policy is **created but not started/enabled**, or the location wasn't added to the
  hold rule. Run `EDHOLD-Validate.ps1` — it reports each `*-CaseHoldPolicy`/`*-CaseHoldRule`'s
  **Enabled/Distribution** state and the bound locations.
- **Fix:** ensure the case-hold **policy is enabled** and the rule includes the custodian's mailbox/site;
  re-run distribution. Hold takes effect only after distribution reaches **Success**.

## "Distribution pending / partial" never completes
- **Cause:** large custodian counts, a location that no longer exists (deleted mailbox/site), or a transient
  service delay. Distribution is asynchronous and can take time.
- **Fix:** wait and re-check `Get-CaseHoldPolicy -Identity <name> -DistributionDetail` (surfaced by
  `EDHOLD-Report.ps1`). Remove/replace invalid locations, then redistribute. Escalate to Microsoft only after
  a location is confirmed valid and distribution stays failed.

## Can't add custodians / custodian communications missing
- **Cause:** custodian management + hold notifications are **eDiscovery (Premium)** features; on
  **Standard** they aren't available, or the account lacks the **eDiscovery Manager** role.
- **Fix:** confirm licensing (`EDHOLD-Discovery.ps1` flags Standard vs Premium — *verify in your tenant*) and
  role-group membership. Custodian/communications operations route through the Graph eDiscovery (beta)
  surface or the portal; the scripts never invent a cmdlet for them.

## "Access denied" creating or viewing a case/hold
- **Cause:** the operator isn't in **eDiscovery Manager** (create/manage own cases) or **eDiscovery
  Administrator** (see all cases), or the case membership doesn't include them.
- **Fix:** add the operator to the correct role group and to the case's members. Verify with
  `EDHOLD-Discovery.ps1`.

## Overlapping holds — worried about releasing preserved data
- **Behaviour:** a location under **multiple** holds stays preserved until **all** holds on it are removed.
  Removing one case hold does **not** release content still held by another (or by a retention policy /
  Litigation Hold).
- **Fix:** before any release, run `EDHOLD-Validate.ps1` to enumerate every hold touching the location.
  Release is a **legal decision** — the scripts never auto-release (the teardown path is pilot-only, guarded,
  and preview-first).

## Litigation Hold vs case hold confusion
- **Litigation Hold** (`Set-Mailbox -LitigationHoldEnabled`) holds an entire mailbox; **case holds** are
  query/matter-scoped across mailboxes and sites. Use case holds for a specific matter; don't rely on one to
  do the other. `EDHOLD-Discovery.ps1` reports both.

## Pilot cleanup left a hold in place
- **Cause:** teardown skipped, or a hold was still distributing when cleanup ran.
- **Fix:** confirm the matter is closed with **legal sign-off**, then remove the pilot case holds
  (`Remove-CaseHoldPolicy`, guarded/preview-first) — never as an untracked ad-hoc action. Record the release
  authority in the **Custodian Hold Register**.

## Government / sovereign cloud
- Portal URLs and connection endpoints differ on **GCC / GCC High / DoD** (`-ConnectionUri` / Graph national
  cloud host). Confirm the correct endpoint for your cloud before running — *verify against current Microsoft
  guidance*; do not assume commercial paths.

*If holds are enabled, distributed to **Success**, custodians tracked (Premium), and validation passes but a
matter still can't produce expected content, the issue is scope/query design (a legal + eDiscovery question),
not a preservation fault — engage the eDiscovery/legal owners rather than changing the hold.*
