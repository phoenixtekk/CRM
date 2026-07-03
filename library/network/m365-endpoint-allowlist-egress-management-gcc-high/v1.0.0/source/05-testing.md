# Testing & Validation — Egress Filtering for M365/Intune Endpoints (Government / GCC High)

Testing mirrors the deployment model. Each phase has an explicit **pass/fail gate**; do not advance
until the gate is green. All tests here are **read-only** — they observe, they do not change the
egress device. Every test derives its expectations from the **`USGovGCCHigh`** instance.

> **Instance sanity check (run this first, always).** Confirm every derived expectation comes from the
> Gov cloud. Query
> `https://endpoints.office.com/version/USGOVGCCHigh?clientrequestid=your-guid` and confirm the
> returned `instance` is **`USGOVGCCHigh`**. If it is `Worldwide`, every downstream test is invalid.

---

## Gate 1 — Assess

| Test | How | Pass |
| --- | --- | --- |
| Correct cloud | Sign in at `portal.office365.us` / `intune.microsoft.us` | Portals load under `.us`; sign-in via `login.microsoftonline.us` |
| Web service reachable | `EGRESSG-Discovery.ps1` from the script host | Exits 0; writes `EGRESSG-Endpoints-USGovGCCHigh.json` |
| Right instance | Read the Discovery summary | `instance = USGovGCCHigh`; FQDNs are `*.us` sovereign names |
| Non-empty set | Count endpoint sets in the export | Greater than zero required endpoint sets |

**Fail action:** if the summary shows `.com` M365 endpoints, you queried `Worldwide` — fix the
instance and re-run.

---

## Gate 2 — Configure

| Test | How | Pass |
| --- | --- | --- |
| Coverage | Compare device objects to the export | Every required endpoint set is in `EGRESSG-M365-GCCHigh-Allow` or `EGRESSG-M365-GCCHigh-URLs` |
| No hardcoding | Review how ranges were added | Ranges were **pasted from the export**, not retyped |
| No-inspect applied | Review inspection policy | `*.manage.microsoft.us`, `has.spserv.microsoft.com`, `*.dm.microsoft.us` are on `EGRESSG-NoInspect-GCCHigh` and excluded from inspection |
| Ports | Compare allowed ports to export | TCP 443/80, Exchange mail ports, Teams UDP 3478–3481 as the export dictates |
| Report mode | `EGRESSG-Validation.ps1` from the script host | Reachable endpoints report PASS |

---

## Gate 3 — Pilot

| Test | How | Pass |
| --- | --- | --- |
| Scope | Check the egress policy target | Policy applies to `EGRESSG-Pilot` source only, not the fleet |
| Group membership | `EGRESSG-Set-ScopeTargeting.ps1 -WhatIf` | Pilot group exists and lists the expected members |
| Rollback ready | Review change record | Written, approved rollback exists (Global Requirement G7) |

---

## Gate 4 — Validate (from a pilot endpoint, behind the filtered egress)

Run `EGRESSG-Validation.ps1` on a pilot device. Every row must be **PASS**.

| Service area | Endpoint tested | Pass |
| --- | --- | --- |
| Identity | `login.microsoftonline.us` | Reachable on 443 |
| Intune service | `*.manage.microsoft.us` host | Reachable; **not** SSL-inspected |
| Enrollment | `enterpriseregistration.microsoftonline.us` | Reachable on 443 |
| Defender / EPM | `*.dm.microsoft.us` host | Reachable; **not** SSL-inspected |
| Exchange | `outlook.office365.us` | Reachable on 443 |
| SharePoint | `*.sharepoint.us` host | Reachable on 443 |
| Teams signaling | `*.gov.teams.microsoft.us` host | Reachable on 443 |
| Teams media | UDP 3478–3481 (where testable) | Reachable |
| Graph | `graph.microsoft.us` | Reachable on 443 |

**Real-behavior confirmation (must also pass):**

- Sign-in completes via `login.microsoftonline.us`.
- Intune Company Portal (`portal.manage.microsoft.us`) checks in successfully.
- Device appears healthy in Defender (`security.microsoft.us`).
- A Teams call connects with two-way audio/video.

**Fail action:** if an SSL-inspected endpoint fails, confirm it is on `EGRESSG-NoInspect-GCCHigh`. If
identity fails, confirm `login.microsoftonline.us` (not `.com`) is allowed. See `06-troubleshooting.md`.

---

## Gate 5 — Expand & keep current

| Test | How | Pass |
| --- | --- | --- |
| Per-wave validation | `EGRESSG-Validation.ps1` on a device in each wave | All PASS |
| Scheduled job runs | Check the scheduled Discovery task | Runs on schedule; writes report |
| Change detection | Compare stored vs live version | Reports "up to date" **or** a diff to review |
| 30-day lead | Review any diff's effective dates | Additions applied within the 30-day advance window |
| Audit report | `EGRESSG-Report.ps1` | Produces a dated point-in-time report |

---

## Regression test (run after any egress-device change)

1. Instance sanity check (`USGOVGCCHigh`).
2. `EGRESSG-Discovery.ps1` — confirm "up to date" or apply the diff.
3. `EGRESSG-Validation.ps1` from a real endpoint — all PASS.
4. Spot-check one SSL-inspected-sensitive flow (Intune check-in) still works.

If all four pass, the change is safe. If any fail, roll back per G7 and diagnose.
