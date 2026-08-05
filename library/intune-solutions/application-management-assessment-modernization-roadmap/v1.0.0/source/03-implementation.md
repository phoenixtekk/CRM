# 3. Implementation Guide — Application Management Current-State Assessment & Modernization Roadmap

Follow these steps **in order**. This is an **assessment**, not a configuration change: every step is
read-only or documentary. The tenant is never modified. The named artifacts below are reused verbatim
in the Testing Guide, the Troubleshooting Guide, and the scripts.

> **Model:** Charter → Access → Collect (artifacts, interviews, technical) → Score against evidence →
> Turn gaps into findings → Sequence into a roadmap → Readout. This owns the **Assess** stage of the
> house pattern and produces the **Design** input (the roadmap) for every downstream workstream.

| Object | Name |
|---|---|
| Charter | `APPASMT – Assessment Charter` |
| Maturity model (rubric) | `APPASMT – Maturity Model (9 Dimensions x 5 Levels)` |
| Artifact request | `APPASMT – Artifact Request List` |
| Interview guide | `APPASMT – Discovery Interview Guide` |
| Evidence folder | `APPASMT – Evidence Pack` |
| Scored output | `APPASMT – Scoring Sheet` |
| Findings | `APPASMT – Findings Register` |
| Roadmap | `APPASMT – Roadmap One-Pager` + `APPASMT – Wave Plan` |
| Readout | `APPASMT – Executive Readout` |

---

## Step 1 — Charter the assessment (scope & targets)

1. Complete `APPASMT – Assessment Charter` with the sponsor: which of the nine dimensions are in scope,
   the **target level (L1–L5) per dimension**, the platforms in scope (Windows / macOS / iOS / Android),
   the business units or device groups included, the explicit out-of-scope statement, the stakeholder
   list, and the readout date.
2. Confirm the **default targets** (Requirement 2.3) or adjust them with the customer. Record who signed.
3. **Pass/fail:** the charter is signed and every in-scope dimension has a named target level.

## Step 2 — Obtain and verify read-only access (Access)

1. Confirm the assessor account holds **Read Only Operator** (Intune) and **Global Reader** (Entra) per
   Requirement 2.1.
2. Install/confirm the Microsoft Graph PowerShell SDK and consent the **read-only** scopes per
   Requirement 2.2. **Government tenants:** add `-Environment USGov` (Requirement 2.7).
3. Run `APPASMT-Estate-Inventory.ps1 -WhatIfAccessCheck`. Confirm it signs in, reports the granted
   scopes as read-only, and lists which object types are readable.
4. **Pass/fail:** sign-in succeeds; `Get-MgContext` shows only `.Read.All` scopes; all in-scope object
   types are readable, or a documented reason (role/licensing) exists for any that are not.

## Step 3 — Request and collect documentary artifacts (Collect)

1. Send `APPASMT – Artifact Request List` (if not already sent at charter). It requests, at minimum:
   the written packaging standard, application intake and approval records, deployment ring definitions,
   the patch/version-currency cadence policy, the WDAC/AppLocker policy, application retirement records,
   support runbooks and the ticket-routing map, the software asset management / license position, and any
   SCCM or co-management inventory.
2. Save every artifact received into the `APPASMT – Evidence Pack` folder, named by dimension
   (e.g. `D2 - Packaging-Standard.docx`).
3. **Pass/fail:** each requested artifact is either collected or explicitly recorded as "not provided /
   does not exist" — the absence is a data point, not a blank.

## Step 4 — Run the structured interviews (Collect)

1. Using `APPASMT – Discovery Interview Guide`, interview each stakeholder role. Ask, per role:
   - **Application owners / sponsors:** How is a new app requested and approved? Who signs off? Who is
     accountable when it breaks? (evidences D1)
   - **Endpoint engineers:** Walk me through packaging one app end to end. Is there a written standard?
     How do you deploy — rings or straight to All Devices? How do you keep versions current? How do you
     retire an app? (evidences D2, D3, D4, D6)
   - **Security / endpoint security:** Is app execution controlled (WDAC/AppLocker)? Are apps security-
     reviewed and signature-checked before deployment? (evidences D5)
   - **Service desk / support lead:** When an app ticket arrives, where does it go? Is there a runbook?
     Who is the escalation owner or vendor contact? (evidences D8)
   - **Procurement / SAM:** How do you know what's licensed vs installed? Is there version/licence drift?
     (evidences D4, D9)
2. Capture answers as notes in the Evidence Pack, tagged by dimension.
3. **Pass/fail:** every in-scope dimension has interview evidence from at least the role that owns it.

## Step 5 — Collect the technical evidence (Collect)

Run the five **read-only** scripts. Each writes CSV/JSON into `APPASMT – Evidence Pack`. Run them in
this order:

1. `APPASMT-Estate-Inventory.ps1` — the app estate: counts by app type (Win32, MSI/LOB, store, web
   link, iOS/Android), publisher, and assignment intent. Builds the baseline "how many apps, of what
   kind" picture. (evidences D1, D9)
2. `APPASMT-Assignment-Analysis.ps1` — assignment sprawl and conflicts: apps assigned to overlapping
   groups, apps assigned directly to All Devices/All Users, apps with both required and available intents
   colliding, and orphaned assignments (groups with no members). (evidences D1, D3)
3. `APPASMT-Install-Health.ps1` — install-failure and version-drift baseline: per-app install
   success/failure/pending counts from device app-status, and version spread per app title (how many
   distinct versions of the same product are live). (evidences D4, D7)
4. `APPASMT-Unmanaged-Detection.ps1` — unmanaged and sideloaded apps: from `detectedApps`, the software
   present on managed devices that is **not** deployed by Intune (manually installed / sideloaded), and
   apps with no assignment that are nonetheless detected. (evidences D5, D6, D9)
5. `APPASMT-Maturity-Evidence.ps1` — the aggregator: reads the four outputs above plus signals for
   app-control (WDAC/AppLocker configuration profiles), co-management/SCCM workload signals, and app
   configuration/protection policies, and emits a single scored data pack (`APPASMT-EvidencePack.json`)
   with a **suggested** level and the signal behind it for each of the nine dimensions. (evidences all)

For a Government tenant, pass `-Environment USGov` to each script (documented in each `.NOTES`).

**Pass/fail:** all five scripts complete and the Evidence Pack contains a signal for each dimension, or
an explicit "insufficient data" marker where a signal could not be read.

## Step 6 — Score each dimension against the evidence tables (Score)

Open `APPASMT – Scoring Sheet` and, for each dimension, award the level whose **evidence table** is
fully satisfied by the collected evidence (artifacts + interviews + `APPASMT-Maturity-Evidence.ps1`
suggestion). A level requires **all** of its evidence to be present; if only some is, the dimension
scores the level below. Where evidence is missing entirely, mark **"Insufficient Evidence"** — never
guess a low score.

The nine evidence tables (`APPASMT – Maturity Model (9 Dimensions x 5 Levels)`):

### D1 — Governance & Ownership
| Level | Observable evidence required |
|---|---|
| L1 | No app owner list; apps requested informally; no approval record anywhere |
| L2 | An owner is *usually* known but recorded in people's heads or scattered emails; no single intake |
| L3 | A written intake path and an owner register exist and are used for new apps; approvals are recorded |
| L4 | Ownership and approval are reviewed on a cadence; orphaned-app metrics exist and are actioned |
| L5 | Intake/approval is automated (workflow/ITSM), ownership is enforced, orphans are auto-flagged and closed |

### D2 — Packaging Standards
| Level | Observable evidence required |
|---|---|
| L1 | No written standard; each engineer packages their own way; naming is inconsistent (script confirms name entropy) |
| L2 | An unwritten "house way" is followed by most engineers; detection rules exist but vary |
| L3 | A **written packaging standard document exists** (produced as artifact) covering naming, detection, requirement rules, install behaviour, and is followed for new work |
| L4 | Packaging conformance is measured (e.g. QA checklist, sample audits) and non-conformance is corrected |
| L5 | Packaging is templated/automated (e.g. PSADT + pipeline), conformance is enforced pre-publish |

### D3 — Deployment & Rings
| Level | Observable evidence required |
|---|---|
| L1 | Apps deployed straight to All Devices/All Users; no rings (script confirms All-Devices assignments) |
| L2 | An informal "test on a few machines first" habit; no defined ring groups |
| L3 | **Defined ring groups** (e.g. pilot → early → broad) exist and new deployments follow them; gates are documented |
| L4 | Ring progression is gated on measured install success and reviewed before each promotion |
| L5 | Ring promotion is automated on success thresholds; rollback is automated |

### D4 — Patching & Version Currency
| Level | Observable evidence required |
|---|---|
| L1 | No cadence; apps updated only when broken; high version spread (script: multiple live versions per title) |
| L2 | Ad hoc updates when someone notices; some products current, many stale |
| L3 | A **written cadence** exists and priority apps are kept current; supersedence is used |
| L4 | Version currency is measured and reported; drift is tracked and closed to target |
| L5 | Updating is automated (e.g. WinGet/patch tooling + supersedence); drift is near-zero and self-correcting |

### D5 — Security & Application Control
| Level | Observable evidence required |
|---|---|
| L1 | No app-execution control (no WDAC/AppLocker profile — script confirms); no pre-deployment security review |
| L2 | App control discussed or piloted on a few devices; security review is informal |
| L3 | **WDAC or AppLocker is deployed** to a meaningful scope and apps are security-reviewed before deployment |
| L4 | App control is enforced fleet-wide in enforce mode, measured, and exceptions are tracked |
| L5 | App control is fully enforced, signed-catalog managed, integrated with security monitoring |

### D6 — Lifecycle & Retirement
| Level | Observable evidence required |
|---|---|
| L1 | Apps are never removed; retired products still assigned; no review (script: assigned apps with no installs) |
| L2 | Occasional cleanups when storage or licence pressure forces it; no process |
| L3 | A **written review/retirement process** exists and superseded apps are removed on a cadence |
| L4 | Retirement is measured (apps retired vs candidates) and reported |
| L5 | Lifecycle is automated end-to-end (auto-flag unused, supersede, uninstall, decommission) |

### D7 — Monitoring & Reporting
| Level | Observable evidence required |
|---|---|
| L1 | Nobody looks at install success/failure; no reporting (interview confirms) |
| L2 | Someone checks the Intune app dashboard reactively when a rollout is questioned |
| L3 | **A regular report** of install success/failure and estate composition is produced and read by an owner |
| L4 | Metrics feed a reviewed scorecard with thresholds; failures trigger action |
| L5 | Monitoring is automated with alerting and trend dashboards; SLAs on install success exist |

### D8 — Support Model
| Level | Observable evidence required |
|---|---|
| L1 | App tickets go wherever; no runbooks; one engineer "just knows" (interview confirms bus-factor risk) |
| L2 | Tickets usually reach the right person but by tribal knowledge, not a defined route |
| L3 | **A defined ticket-routing map and runbooks exist**, with a named escalation owner or vendor per app tier |
| L4 | Support performance is measured (time-to-resolve by app), reviewed, and runbooks are maintained |
| L5 | Support is proactive (known-issue automation, self-heal), integrated with monitoring |

### D9 — Tooling & Migration Debt
| Level | Observable evidence required |
|---|---|
| L1 | Heavy SCCM/co-management or manual-install dependence; Intune is partial (script: co-mgmt/detectedApps signals) |
| L2 | Migration to Intune-native is underway but stalled; significant remnants remain |
| L3 | The estate is **majority Intune-native**; remaining SCCM/manual items are inventoried with a plan |
| L4 | Migration is measured to completion; residual debt is tracked and closing |
| L5 | Fully Intune-native; no SCCM/manual app-delivery remnants; tooling is consolidated |

For each dimension record in the `APPASMT – Scoring Sheet`: **current level**, **target level** (from
the charter), **gap** (target − current), and the **evidence citation** (which artifact / interview /
script output justifies the score).

**Pass/fail:** every in-scope dimension has a current level (or "Insufficient Evidence"), a target, a
gap, and a cited evidence source.

## Step 7 — Turn gaps into findings (Findings)

1. For every dimension with a gap > 0, write one or more rows in the `APPASMT – Findings Register`. Each
   finding has: dimension, a plain-language description of what is wrong, the **evidence** (cited),
   the **business impact** (what this costs or risks — e.g. "3 live versions of the PDF reader means
   unpatched RCE exposure and support confusion"), a **risk rating** (Critical / High / Medium / Low
   using the `APPASMT – Risk Matrix`: likelihood × impact), the **remediation direction** (what kind of
   work closes it — described, not built), and a **sized effort** (S/M/L/XL band with a day range).
2. **Do not re-teach the remediation.** Where a finding points at deeper work — governance operating
   model, packaging standards, retirement program, uninstall remediation, or monitoring tooling — state
   the direction and the effort and reference that the detailed build is a separate workstream. Example:
   "Direction: establish a written packaging standard and QA gate (foundational packaging-standards
   workstream). Effort: L (10–15 days)." Nothing more.
3. **Pass/fail:** every gap is represented by at least one finding with all fields populated; no finding
   contains build-level step-by-step detail.

## Step 8 — Sequence the roadmap and run the readout (Roadmap → Readout)

1. Plot every finding on `APPASMT – Roadmap One-Pager` — an **effort (x) vs impact (y)** chart — and
   assign each to a wave in `APPASMT – Wave Plan`:
   - **Wave 1 — Quick Wins (0–30 days):** high impact, low effort. Things that build credibility and
     reduce risk fast (e.g. remove orphaned assignments, retire clearly-dead apps, turn on the app
     install report). These fund the trust for the bigger waves.
   - **Wave 2 — Foundational (30–90 days):** the enablers other work depends on (e.g. write the packaging
     standard, define deployment rings, establish the ownership register). Usually medium-to-high effort,
     high leverage.
   - **Wave 3 — Strategic (90 days–12 months):** the high-effort transformation (e.g. WDAC enforcement,
     full SCCM→Intune migration, automated lifecycle). Depends on the foundational wave being in place.
2. Draw the **dependencies** between waves explicitly — a strategic item that depends on a foundational
   one cannot start early. Map them on the one-pager as arrows.
3. Produce the **30/60/90-day plus 12-month view**: what completes by day 30, day 60, day 90, and by
   month 12, tied to the waves.
4. Build `APPASMT – Executive Readout`. Its executive summary **must** contain, in one page: the overall
   maturity band (average of the nine scores), the three findings with the highest risk rating, the
   single most important dependency, the Wave 1 quick wins the customer can start next week, and the
   headline effort for the full roadmap. Present current state → target state → sequenced plan; get
   sign-off on the roadmap.
5. **Pass/fail:** every finding sits in exactly one wave; dependencies are drawn; the 30/60/90 + 12-month
   view exists; the executive summary contains all five mandatory elements.

---

### Order of operations

`Charter (targets) → verify read-only access → collect artifacts → interviews → run 5 read-only scripts →
score against the 9 evidence tables → gaps become findings (impact + risk + effort) → sequence into
3 waves on effort-vs-impact with dependencies → executive readout`
