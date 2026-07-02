# Implementation Guide

This guide gives the exact, ordered steps to **derive** the required IP/Port/URL set, **build** the
allow-list / proxy exceptions, **validate** reachability on a pilot, **expand** to the fleet, and
**keep it current** as Microsoft's endpoints change. It follows the staged model
**Assess → Configure → Pilot → Validate → Expand**, with a pass/fail gate at each transition.

Object names used throughout are fixed — **create and reuse them verbatim** so the allow-list, the
change records, the reports, and the rollback all refer to the same things:

| Object | Name to use |
|---|---|
| Entra pilot security group | `SG-EGRESS-Pilot` |
| Derived required-set file | `egress-required-set.json` |
| Proxy/firewall allow group / policy | `AllowList-M365-Endpoints` |
| Address/URL object group (IPs + URLs) | `M365-Required-Endpoints` |
| Discovery output folder | `.\EGRESS-Output\` |
| Coverage/gap report file | `egress-coverage-report.html` |
| Proposed allow-list update file | `egress-allowlist-update.txt` |
| Keep-current baseline (last built version) | `egress-baseline-version.json` |

All scripts live in `.\scripts\`. Read-only scripts (Discovery, Validation, Report) make no changes.
Change-generating scripts (Remediation, Set-ScopeTargeting) **default to preview / `-WhatIf`** and
must be re-run with the commit switch to act.

---

## Phase 0 — Assess (prerequisites and baseline)

**Step 0.1 — Confirm prerequisites.** Work through `02-requirements.md` (R1–R5) and
`global-requirements-network.md`. Do not proceed until each is verified.

**Step 0.2 — Snapshot the current filter state (rollback baseline).** Export the current outbound
ruleset from your proxy/firewall (the vendor's export/backup function — defer the exact steps to the
vendor documentation) and store it with your change record. This is your rollback point (R3).

**Gate 0 (pass/fail):** All prerequisites verified **and** a current-ruleset export saved. Fail → stop
and remediate before continuing.

---

## Phase 1 — Derive the required set (Configure, part 1)

**Step 1.1 — Run Discovery to pull the current required endpoints.** From the management workstation
(R2/R5):

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESS-Discovery.ps1 -Instance Worldwide -OutputPath .\EGRESS-Output
```

This calls the Microsoft 365 IP/URL **web service** (`endpoints` + `version` operations) for your
instance, and writes:
- `egress-required-set.json` — the normalized required set (each entry: URLs, IPs, TCP/UDP ports,
  serviceArea, category, required flag).
- `egress-baseline-version.json` — the web-service version you built from (used later for drift).
- A current-filter-state summary if you supplied an exported ruleset via `-CurrentRulesetPath`.

Use the instance that matches your tenant (`Worldwide` for most; a sovereign instance otherwise).

**Step 1.2 — Add the Intune / Autopilot / Defender endpoints.** The web service covers Microsoft 365
(including the common/identity area Entra uses). The Discovery script also emits, in
`egress-required-set.json`, a section listing the **documented Intune, Autopilot-dependency, and
Defender** endpoint host names/ports that are not fully covered by the web service so they are part of
one required-set document. Review that section against Microsoft's current Intune/Defender endpoint
documentation and confirm nothing your tenant uses is missing.

**Step 1.3 — Scope the required set to what you need.** Keep every entry marked **required = true** and
every entry in category **Optimize** or **Allow**. Category **Default** entries can be permitted or
sent to your general internet path per your policy. Do not narrow below the required + Optimize + Allow
set — that is what causes silent failures.

**Gate 1 (pass/fail):** `egress-required-set.json` exists, contains the M365 required/Optimize/Allow
endpoints for the correct instance, and includes the Intune/Autopilot/Defender section. Fail → re-run
Discovery / correct the instance.

---

## Phase 2 — Build the allow-list / proxy exceptions (Configure, part 2)

**Step 2.1 — Generate the proposed allow-list entries (preview).**

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESS-Remediation.ps1 -RequiredSetPath .\EGRESS-Output\egress-required-set.json -Format generic
```

This runs in **preview / `-WhatIf` by default**: it writes `egress-allowlist-update.txt` — a
human-readable list of the URL and IP/CIDR + port entries that should exist in the allow-list — and
prints a summary. It changes nothing on the device. Use `-Format` to shape the output for your device
(a generic list you paste, a hosts/URL list, or a CIDR list); the exact import into the device is
vendor-specific (defer to the vendor docs).

**Step 2.2 — Create the named allow-list objects on the proxy/firewall.** In the device console,
create:
- An address/URL object group named **`M365-Required-Endpoints`** containing the URLs and IP/CIDR
  ranges from `egress-allowlist-update.txt`, with the required TCP/UDP ports (typically 443, and 80
  for specific content/CRL/OCSP endpoints as listed).
- An allow rule / policy named **`AllowList-M365-Endpoints`** that permits the managed-device network
  to reach `M365-Required-Endpoints` on those ports, ahead of the default-deny rule.

Match the object names verbatim. The vendor's exact object type and import mechanism are deferred to
its documentation; the **content and names** come from this solution.

**Step 2.3 — For SSL-inspecting proxies, add decryption bypass for the required set.** If the proxy
performs SSL/TLS inspection, several Microsoft endpoints (notably certificate-pinned services) must be
**bypassed from decryption**, not just allowed. Add the same `M365-Required-Endpoints` set to the
proxy's decryption-bypass/exception list. (Which endpoints require bypass is noted in the required-set
`notes`; the proxy's bypass mechanism is vendor-specific.)

**Gate 2 (pass/fail):** `AllowList-M365-Endpoints` and `M365-Required-Endpoints` exist on the device
and contain the entries from `egress-allowlist-update.txt`; SSL-bypass added where required. Fail →
correct the objects before piloting.

---

## Phase 3 — Pilot (apply to a limited scope)

**Step 3.1 — Build the pilot group (preview, then commit).**

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESS-Set-ScopeTargeting.ps1 -PilotGroupName SG-EGRESS-Pilot -MemberObjectId pilot-device-object-id-one,pilot-device-object-id-two
```

Runs in preview / `-WhatIf` by default (shows what it would create/add). Re-run with `-Commit` to
create `SG-EGRESS-Pilot` and add the pilot devices.

**Step 3.2 — Point the allow-list at the pilot first.** Scope `AllowList-M365-Endpoints` to the pilot
devices' network/subnet (or apply it to the pilot devices only) so the change is contained. Keep the
rest of the fleet on the pre-change state until validation passes.

**Gate 3 (pass/fail):** `SG-EGRESS-Pilot` populated and the allow-list applied only to the pilot
scope. Fail → fix scoping before validating.

---

## Phase 4 — Validate reachability and real workflows

**Step 4.1 — Per-endpoint reachability from a pilot device.** On a pilot device (behind the filter),
run:

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESS-Validation.ps1 -RequiredSetPath .\EGRESS-Output\egress-required-set.json -OutputPath .\EGRESS-Output
```

This tests each required destination on its required port(s) (TCP connect / TLS handshake / HTTP
reachability as appropriate) and writes a per-endpoint pass/fail result. **Every required endpoint
must be reachable.**

**Step 4.2 — Coverage / gap report.**

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESS-Report.ps1 -RequiredSetPath .\EGRESS-Output\egress-required-set.json -ValidationResultsPath .\EGRESS-Output -OutputPath .\EGRESS-Output
```

Produces `egress-coverage-report.html`: which required endpoints are covered/reachable and which are
gaps. Zero gaps in the required + Optimize + Allow set is the target.

**Step 4.3 — Prove the real workflows.** On the pilot, confirm end-to-end (see the Testing Guide for
the exact gates): a device **enrolls / completes Autopilot**, Intune **policy/compliance syncs**, and
an **update / app install succeeds**. Reachability alone is necessary but not sufficient — the
workflows are the real proof.

**Gate 4 (pass/fail):** all required endpoints reachable (Step 4.1), zero required-set gaps in the
report (Step 4.2), and enrollment + sync + update succeed on the pilot (Step 4.3). Any fail → use the
Troubleshooting Guide to identify the missing endpoint, add it (back to Phase 2), and re-validate.

---

## Phase 5 — Expand to the fleet

**Step 5.1 — Broaden the allow-list scope.** Through change control (R3), extend
`AllowList-M365-Endpoints` from the pilot scope to the full managed-device network. Do not create new
entries here — expansion is a scope change, not a content change (the content was validated on the
pilot).

**Step 5.2 — Spot-validate on the wider fleet.** Re-run `EGRESS-Validation.ps1` from one or two
production devices in different sites to confirm the same reachability holds fleet-wide.

**Gate 5 (pass/fail):** allow-list applied fleet-wide and spot-validation passes. Fail → roll back to
pilot scope (delete/revert per the change record) and investigate.

---

## Phase 6 — Keep current (operate the loop)

Microsoft changes the published endpoints regularly. Operate a scheduled drift check so you update the
allow-list **before** a change breaks connectivity.

**Step 6.1 — Schedule a drift check.** On a schedule (Microsoft typically publishes changes with lead
time; a weekly check is a reasonable default), re-run Discovery and compare to your baseline:

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESS-Discovery.ps1 -Instance Worldwide -OutputPath .\EGRESS-Output -BaselineVersionPath .\EGRESS-Output\egress-baseline-version.json
```

If the web-service **version** is unchanged, there is nothing to do. If it changed, Discovery writes a
refreshed `egress-required-set.json` and flags that a delta exists.

**Step 6.2 — Generate the delta and update.**

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESS-Remediation.ps1 -RequiredSetPath .\EGRESS-Output\egress-required-set.json -BaselineRequiredSetPath .\EGRESS-Output\egress-required-set-previous.json -Format generic
```

In preview by default, this reports the **added** and **removed** endpoints since your baseline and
writes them to `egress-allowlist-update.txt`. Apply the additions to `M365-Required-Endpoints` (and
remove retired entries) through change control, re-validate the changed entries (Phase 4), then update
`egress-baseline-version.json` to the new version so the next check compares against it.

**Step 6.3 — Record and repeat.** Log each drift check and any changes made. A stable required-set
with only occasional, expected deltas means the allow-list is healthy.

**Gate 6 (ongoing):** the live allow-list never silently diverges from the current Microsoft published
set; deltas are applied under change control and re-validated. This is the steady state.
