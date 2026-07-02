# Best Practices

Operating an egress allow-list for Microsoft's cloud-managed endpoints well comes down to two
disciplines: **rigorous change control** and **routine drift review**. The list is a living object; it
succeeds or fails on how it is maintained, not on how it was first built.

## Change control

- **Never edit the live allow-list ad hoc.** Every add/remove goes through the change record that
  names the objects (`AllowList-M365-Endpoints`, `M365-Required-Endpoints`) and the rollback. Ad-hoc
  edits are how the list silently diverges from Microsoft's published set.
- **Snapshot before you change.** Export the current ruleset before any edit so rollback is a restore,
  not a reconstruction from memory.
- **Preview before you commit.** Always generate the proposed change (`EGRESS-Remediation.ps1` runs in
  preview / `-WhatIf` by default) and review `egress-allowlist-update.txt` before touching the device.
  Same for scope changes (`EGRESS-Set-ScopeTargeting.ps1` previews by default).
- **Pilot every content change.** New or changed endpoints get validated on `SG-EGRESS-Pilot` first
  (reachability **and** the enrollment/sync/update workflows) before fleet expansion. Scope expansion
  is a separate, later change from content change.
- **Use the fixed object names verbatim.** Consistent naming makes the allow-list, reports, change
  records, and rollback all refer to the same objects — essential for audit and handover.

## Derive, never hardcode

- **Always build from the Microsoft web service for your instance**, not from a static list you typed
  or copied. Confirm the instance (Worldwide vs a sovereign cloud) matches your tenant every time.
- **Keep the required + Optimize + Allow set intact.** Do not trim below it to "tighten" — that is the
  direct cause of silent enrollment/sync/update failures. Category **Default** endpoints are where you
  have discretion.
- **Record the baseline version** (`egress-baseline-version.json`) you built from, so every future
  change is a reviewable delta against a known point, not a fresh guess.

## Drift review

- **Schedule the drift check** (Implementation Phase 6). A weekly Discovery-with-baseline run is a
  reasonable default; Microsoft usually publishes changes with lead time, so a regular cadence catches
  them before they bite.
- **Act on the version, not the calendar.** If the web-service version is unchanged, do nothing. When
  it changes, generate the delta, apply additions and remove retired entries under change control,
  re-validate the changed entries, then advance the baseline.
- **Trend the deltas.** A healthy environment shows small, occasional, expected deltas. A surprise —
  large delta, or reachability failing without a published change — points at a local proxy/firewall
  change and should be investigated as drift on *your* side.

## SSL inspection and least privilege

- **Bypass decryption for endpoints that require it.** Certificate-pinned Microsoft services fail if
  inspected; keep them on the decryption-bypass list, not just the allow-list.
- **Scope the allow-list to the managed-device network**, not "any source." The Microsoft endpoints
  should be reachable by the devices that need them, on the required ports only (typically 443, with
  80 only for the specific content/CRL/OCSP endpoints listed).
- **Keep the management workstation's own egress in the required set.** The host that runs Discovery
  and the drift job needs the web-service and Graph endpoints allowed — treat it like a managed
  device.

## Documentation and handover

- **Keep the required-set file, reports, and change records together.** `egress-required-set.json`,
  `egress-coverage-report.html`, and the change history are the audit trail; store them with the
  rollback baseline.
- **Document the instance, the schedule, and the object names** so the next operator can run the loop
  without reverse-engineering it.
