# Implementation Guide — Egress Filtering for M365/Intune Endpoints (Government / GCC High)

This guide takes you from nothing to a validated, self-maintaining allow-list for a **GCC High**
tenant. It follows **Assess → Configure → Pilot → Validate → Expand**, with a **gate** at the end of
each phase. Every step derives Microsoft's required set from the **`USGovGCCHigh`** instance — **no
Microsoft IPs are ever typed by hand.**

> **Before you start:** confirm the requirement gate in `02-requirements.md` passed (R1 GCC High
> confirmed, R4 web service reachable, R7 no-inspect understood). Keep the object names from
> `01-solution-overview.md` — you will reference them repeatedly.

---

## Phase 1 — Assess (derive today's required GCC High set)

### Step 1.1 — Generate a stable ClientRequestId GUID

The web service requires a **ClientRequestId** GUID per calling machine. Generate one and reuse it
(the scripts store it in `EGRESSG-latestversion.txt`).

```powershell
[GUID]::NewGuid().Guid
```

> Do **not** reuse the GUIDs shown in Microsoft's examples — Microsoft warns they may be blocked. Use
> your own.

### Step 1.2 — Confirm you are querying the GCC High instance

In a browser or PowerShell on the script host, check the version of the **`USGOVGCCHigh`** instance
(replace `your-guid` with the GUID from Step 1.1):

```
https://endpoints.office.com/version/USGOVGCCHigh?clientrequestid=your-guid
```

You should get a JSON record whose `instance` is **`USGOVGCCHigh`**. If you see `Worldwide`, you
queried the wrong instance — fix the URL. **This is the single most important check in the whole
solution.**

### Step 1.3 — Run Discovery (read-only)

Run the discovery script. It queries the **`USGOVGCCHigh`** endpoints web method, splits the result
into IPv4/IPv6 ranges, URLs, and ports, flags the required and no-inspect endpoints, and writes
`EGRESSG-Endpoints-USGovGCCHigh.json` plus a human-readable summary.

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESSG-Discovery.ps1
```

Read the summary. Confirm it lists sovereign FQDNs (`outlook.office365.us`, `*.manage.microsoft.us`,
`*.sharepoint.us`, `login.microsoftonline.us`, etc.). If it shows `.com` M365 endpoints, you are on
the wrong instance — stop.

> **Gate 1 (Assess):** Discovery returns a **non-empty** set from the **`USGovGCCHigh`** instance and
> the summary shows `*.us` sovereign endpoints. Only then continue.

---

## Phase 2 — Configure (build the named allow-list)

You now translate the derived set into named objects on your egress device. **Do this on the device;
the scripts derive and document the data, they do not reach into your firewall.** Use the object names
from the overview so everything is auditable.

### Step 2.1 — Create the IP address group `EGRESSG-M365-GCCHigh-Allow`

From `EGRESSG-Endpoints-USGovGCCHigh.json`, take the **IPv4/IPv6 ranges** for the **`Optimize`** and
**`Allow`** category endpoints (these are the ones Microsoft marks required) and add them to a single
named address group on your firewall/SWG:

- Object name: **`EGRESSG-M365-GCCHigh-Allow`**
- Contents: the derived CIDR ranges (paste from the Discovery export — never retype)
- Because these ranges **change monthly**, treat this object as **machine-maintained** (see Phase 5).

> If you use ExpressRoute for Microsoft 365, note which endpoint sets are ER-supported (the export
> carries the `expressRoute` flag) and route those accordingly. **Verify for GCC High** which of your
> workloads are actually on ER in your environment.

### Step 2.2 — Create the URL category `EGRESSG-M365-GCCHigh-URLs`

Add the derived **URLs/FQDNs** (again from the export) to a proxy/SWG URL category or bypass list:

- Object name: **`EGRESSG-M365-GCCHigh-URLs`**
- Contents: the derived FQDNs, including the GCC High sovereign names and the **Unified domains**
  (`*.usgovcloud.microsoft`, `*.usgovcloud-static.microsoft`, `*.usgovcloud-usercontent.microsoft`).
- Cross-check against the fixed-fact FQDN list in `02-requirements.md` (R8). If the derived data is
  missing anything on that list, allow the named FQDN anyway and note it for review.

### Step 2.3 — Create the SSL-inspection bypass list `EGRESSG-NoInspect-GCCHigh`

Add the endpoints Microsoft says must **not** be inspected (R7) to an SSL-inspection **bypass** list:

- Object name: **`EGRESSG-NoInspect-GCCHigh`**
- Contents: `*.manage.microsoft.us`, `has.spserv.microsoft.com`, `*.dm.microsoft.us`
- Ensure your inspection policy **excludes** this list **before** you enable inspection near M365
  traffic. Inspecting these breaks Intune, Defender, and EPM.

### Step 2.4 — Confirm required ports

From the export, confirm the ports are allowed for the corresponding objects. Typical GCC High:
**TCP 443** (and **80** for many endpoints), **TCP 25/587/993/995/143** for Exchange mail protocols,
and **UDP 3478–3481** for Teams media. Use the **derived** `tcpPorts`/`udpPorts` values — do not
assume.

> **Gate 2 (Configure):** Every required endpoint set from the export is represented across
> `EGRESSG-M365-GCCHigh-Allow` and `EGRESSG-M365-GCCHigh-URLs`; the no-inspect list is applied; **no
> Microsoft IP was typed by hand.** Run `EGRESSG-Validation.ps1` in report mode from the script host
> as a sanity check (it does not require pilot devices yet).

---

## Phase 3 — Pilot (apply to a small group only)

### Step 3.1 — Build/confirm the pilot group

Create or confirm `EGRESSG-Pilot` and add a handful of representative devices/users.

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESSG-Set-ScopeTargeting.ps1 -GroupName "EGRESSG-Pilot" -WhatIf
```

`Set-ScopeTargeting` connects to Graph with **`-Environment USGov`**. It defaults to **`-WhatIf`** —
review the planned changes, then re-run with **`-Execute`** to apply.

### Step 3.2 — Apply the egress policy to the pilot only

On your egress device, scope the new allow-list / inspection-bypass policy to the pilot devices'
source (subnet, tag, or group) — **not** the whole fleet. This is the reversible blast-radius control
required by Global Requirement **G7**.

> **Gate 3 (Pilot):** Policy is live for `EGRESSG-Pilot` devices only, and a rollback is written and
> approved.

---

## Phase 4 — Validate (prove it works from a real endpoint)

### Step 4.1 — Run Validation from a pilot endpoint

On a device inside the pilot (behind the filtered egress path), run:

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESSG-Validation.ps1
```

The validation script derives the current **`USGovGCCHigh`** set and tests reachability to
representative Gov endpoints across each service area:

- **Identity:** `login.microsoftonline.us`
- **Intune:** an `*.manage.microsoft.us` host and `enterpriseregistration.microsoftonline.us`
- **Defender/EPM:** an `*.dm.microsoft.us` host
- **Exchange:** `outlook.office365.us`
- **SharePoint:** a `*.sharepoint.us` host
- **Teams:** a `*.gov.teams.microsoft.us` host (and UDP media ports where testable)
- **Graph:** `graph.microsoft.us`

Each check reports **PASS/FAIL**. It is read-only.

### Step 4.2 — Confirm real service behavior

On the pilot device, confirm end-to-end: sign in via `login.microsoftonline.us`, the Intune Company
Portal (`portal.manage.microsoft.us`) checks in, the device shows in Defender
(`security.microsoft.us`), and a Teams call connects with working audio/video.

> **Gate 4 (Validate):** All Validation checks are **PASS** and real sign-in / Intune check-in /
> Defender onboarding / Teams media all work on the pilot. Investigate any FAIL with
> `06-troubleshooting.md` before expanding.

---

## Phase 5 — Expand (fleet rollout + keep current)

### Step 5.1 — Expand scope

Widen the egress policy from `EGRESSG-Pilot` to the full fleet in stages (e.g. by site). Re-run
`EGRESSG-Validation.ps1` from a device in each new wave.

### Step 5.2 — Schedule the monthly keep-current job

Microsoft updates the data monthly and publishes additions **30 days in advance**. Schedule Discovery
to run (e.g. weekly) so you always have 30 days of lead time:

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESSG-Discovery.ps1
```

Discovery compares the live `USGovGCCHigh` version against the stored version in
`EGRESSG-latestversion.txt`. If unchanged, it reports "up to date." If changed, it writes the new
export and a **diff** of what to add/remove, so you can update `EGRESSG-M365-GCCHigh-Allow` /
`EGRESSG-M365-GCCHigh-URLs` **before** the new endpoints go live.

### Step 5.3 — Produce the audit report

Generate the point-in-time report for change control and audit:

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESSG-Report.ps1
```

### Step 5.4 — Remediation (optional, safe by default)

If you maintain the device object exports as files, `EGRESSG-Remediation.ps1` can regenerate the
derived allow-list export and flag drift. It defaults to **`-WhatIf`** and makes **no** change unless
you pass **`-Execute`**. It never edits your firewall directly — it produces the corrected export for
you to import.

```
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESSG-Remediation.ps1            # preview (WhatIf)
powershell -ExecutionPolicy Bypass -File .\scripts\EGRESSG-Remediation.ps1 -Execute   # write corrected export
```

> **Gate 5 (Expand):** Fleet is covered, validation passes per wave, and the keep-current job runs on
> a schedule and reports either "up to date" or a reviewed change set.

---

## Keeping it current — the rule to remember

- **Never hardcode Microsoft IPs.** They change monthly; a hardcoded list is a future outage.
- **Always query `USGOVGCCHigh`.** The default/Worldwide instance is the wrong cloud.
- **Watch the 30-day window.** Additions are published 30 days early — apply them within that window.
- **Keep the no-inspect list current.** If Microsoft adds a Gov no-inspect endpoint, add it to
  `EGRESSG-NoInspect-GCCHigh` and **verify for GCC High** against current Gov docs.
