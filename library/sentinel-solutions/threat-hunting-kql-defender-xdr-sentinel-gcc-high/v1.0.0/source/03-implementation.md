# Implementation — Threat Hunting with KQL: Microsoft Defender XDR & Sentinel

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Configure → Pilot → Validate → Expand**) and is **read-only and pilot-first**: you assess
the hunting surface, stand up the library and RBAC, run a pilot batch of hypothesis-driven hunts,
document findings, validate that a successful hunt promotes into a detection, then expand across the
ATT&CK matrix on a cadence. **Every hunt is read-only** — you never isolate, disable, or remediate from
here. Every object is named verbatim so the scripts, testing, and troubleshooting line up. Replace
`contoso.com` / `contoso.onmicrosoft.com` and the sample names with your own.

> **Portal note (GCC High).** Advanced hunting is reached from the **Defender portal**
> (`security.microsoft.us` — GCC High) → **Hunting → Advanced hunting**; custom detection rules under
> **Hunting → Custom detection rules**. Sentinel runs in **Azure Government** — reach it from
> `portal.azure.us` → **Microsoft Sentinel** (or the unified Defender portal once onboarded); its
> hunting experience is under **Threat management → Hunting**, saved queries under **Hunting → Queries**,
> evidence under **Bookmarks**, and detections under **Analytics**. Sign-in is `login.microsoftonline.us`.
> Portal paths, the advanced-hunting **schema**, retention, query limits, **and which Defender
> pillars/tables and custom-detection features are available in GCC High/DoD** evolve and can lag
> commercial — **verify against current Microsoft Government documentation and your tenant.**

> **Read-only boundary (do not cross it here).** This solution *finds*. When a hunt confirms a true
> positive, **document it and hand it off** to the reactive process (the companion *M365 & Azure
> Incident Response & Escalation Runbook*) — see **Phase 3**. Do **not** take response actions (device
> isolation, account disablement, mailbox purge) from a hunt; those require the IR runbook's authority
> and change control.

> **Connect to the US Gov cloud first.** Before running any delivered script, sign in to the national
> cloud: **`Connect-MgGraph -Environment USGov -Scopes ThreatHunting.Read.All`** (DoD:
> `-Environment USGovDoD`) for Defender advanced hunting, and **`Connect-AzAccount -Environment
> AzureUSGovernment`** for Sentinel. The scripts default to `AzureUSGovernment` / USGov — *verify the
> correct endpoints for your cloud (GCC High vs DoD) against current Microsoft Government documentation.*

## Object naming (used verbatim throughout)

| Object | Name | MITRE (example) |
| --- | --- | --- |
| Read-only hunter RBAC group | `Threat Hunters - Tenant - Group` | — |
| Reusable KQL hunt library | `Hunt Library - Tenant - Main` (`THREATHUNTG-HuntLibrary.kql`) | — |
| Hunt register (findings home) | `Hunt Register - Tenant - Main` | — |
| Recurring hunt cadence | `Hunt Cadence - Tenant - Monthly` | — |
| Hunt — LOLBin / script-interpreter abuse | `Hunt-LOLBins-Devices-Pilot` | T1059 (Execution) |
| Hunt — anomalous parent→child process | `Hunt-RareParentChild-Devices-Pilot` | T1055 / T1036 (Defense Evasion) |
| Hunt — suspicious inbox / forwarding rules | `Hunt-InboxRules-M365-Pilot` | T1114 / T1564 (Collection) |
| Hunt — rare service-account sign-in | `Hunt-RareServiceSignin-Entra-Pilot` | T1078 (Valid Accounts) |
| Hunt — beaconing / rare egress | `Hunt-BeaconEgress-Network-Pilot` | T1071 (Command & Control) |
| Finding bookmark | `Bookmark-<Hunt>-Finding` | inherits hunt's technique |
| Promoted scheduled analytics rule (Sentinel) | `Rule-<Hunt>-Prod` | inherits hunt's technique |
| Promoted custom detection (Defender XDR) | `CD-<Hunt>-Prod` | inherits hunt's technique |

*(The five named hunts are worked examples that ship in the KQL library — one per ATT&CK tactic band.
Apply the same hypothesis→scope→run→document→promote pattern to the rest of your prioritized backlog.)*

---

## Phase 0 — Assess (is the hunting surface usable?)

1. **Confirm the baseline (G1–G7) and R1–R2** — Defender XDR onboarded and the advanced-hunting tables
   have data; the Sentinel workspace is connected and its hunting tables have data.
2. **Inventory the hunting surface.** Run **`THREATHUNTG-Discovery.ps1`** (read-only): it reports which
   advanced-hunting tables and which Sentinel tables have recent data, and lists existing Sentinel
   **hunt queries**, **bookmarks**, and **custom detection rules** — so you start from reality, not a
   blank page.
3. **Load the priority (R4).** Take leadership's ranked ATT&CK techniques and pick the **pilot batch** —
   the five shipped hunts map to five common priorities (Execution, Defense Evasion, Collection, Valid
   Accounts, C2); reorder to match your backlog.
   - **Gate 0:** advanced-hunting and Sentinel tables have data, the surface is inventoried, and a
     prioritized pilot batch is chosen → continue.

## Phase 1 — Configure (RBAC, library, register, cadence)

### Step 1 — Stand up read-only hunter access (R3)

1. Entra → **Groups → New group** → name it exactly **`Threat Hunters - Tenant - Group`**; add the
   hunters.
2. On the workspace / `RG-Security-Sentinel` → **Access control (IAM) → Add role assignment** → assign
   **Microsoft Sentinel Reader** to `Threat Hunters - Tenant - Group`.
3. In the Defender portal → **Permissions** (or Entra role) → grant the group **Security Reader** so
   they can run advanced hunting without any change rights.
4. Keep a **separate, smaller** admin set (Sentinel Contributor / Defender security-settings) for
   **promotion only** (Phase 4). Hunters hunt; a few admins promote.

### Step 2 — Import the reusable KQL hunt library

1. Open **`THREATHUNTG-HuntLibrary.kql`** (`Hunt Library - Tenant - Main`) — it contains the five named
   hunts, each with a header block (name, hypothesis, MITRE tactic/technique, target surface
   XDR-vs-Sentinel, and a promotion note).
2. **Save each hunt as a reusable query** so the team hunts from a shelf, not from memory:
   - **Sentinel-side hunts** → Sentinel → **Hunting → Queries → New query** → paste the KQL, set the
     **Tactics & techniques** tags to match the header, and name it exactly (e.g.
     `Hunt-RareServiceSignin-Entra-Pilot`).
   - **Defender-XDR-side hunts** → advanced hunting → paste the KQL → **Save as** → name it exactly
     (e.g. `Hunt-LOLBins-Devices-Pilot`).
3. Confirm the tags are set — the technique tag is what makes the library a **coverage map** later.

### Step 3 — Create the hunt register and set the cadence

1. Create **`Hunt Register - Tenant - Main`** (a doc/wiki/list). For every hunt, capture: **hypothesis,
   scope (time/assets/identities), the exact KQL, outcome (found / not found / follow-up), and the
   decision (promote / hand-off / close)**.
2. Establish the bookmark convention **`Bookmark-<Hunt>-Finding`** so evidence rows are named
   consistently.
3. Schedule **`Hunt Cadence - Tenant - Monthly`** — a recurring hunt cycle (monthly is a sensible
   default; high-risk techniques may warrant more often). Put it on the security calendar with an owner.
   - **Gate 1:** RBAC group in place (read-only), library saved and tagged on both surfaces, register
     created, cadence scheduled → continue.

## Phase 2 — Pilot (run hypothesis-driven hunts, read-only, and document)

Run the pilot batch. For **each** hunt, follow the same loop; the whole batch can be executed at once
with **`THREATHUNTG-RunHuntLibrary.ps1`** (read-only — it runs every `.kql` hunt across the right surface
and reports row counts), then triage the hits interactively.

1. **State the hypothesis** (from the hunt header) in the register — e.g. *"An attacker is using a
   built-in LOLBin (e.g. `mshta.exe`, `rundll32.exe`) to execute code; unusual command lines will
   surface it."* (`Hunt-LOLBins-Devices-Pilot`, **T1059**).
2. **Scope it.** Start narrow — a time window within retention, a subset of high-value devices or
   identities — then widen. Advanced hunting is ~30-day retention; Sentinel may hold longer (**R8**).
3. **Run the KQL.**
   - Interactively: paste the saved query in advanced hunting (Defender-side hunts) or Sentinel **Logs**
     (Sentinel-side hunts).
   - In bulk: `pwsh -File .\THREATHUNTG-RunHuntLibrary.ps1 -ResourceGroup RG-Security-Sentinel
     -WorkspaceName "Security Telemetry - Tenant - Workspace"` — it executes the library on both
     platforms and prints per-hunt result counts. **It never takes action; it only reads.**
4. **Triage the results** — benign / suspicious / confirmed. Most hunt hits are benign-but-interesting;
   that is normal and still valuable (it tunes the next run).
5. **Document the outcome and preserve evidence.**
   - Record the outcome + decision in `Hunt Register - Tenant - Main`.
   - For anything suspicious/confirmed, in Sentinel **Hunting/Logs → select the row(s) → Add bookmark**,
     naming it **`Bookmark-<Hunt>-Finding`** (e.g. `Bookmark-Hunt-InboxRules-M365-Pilot-Finding`), and
     map its **entities** (account, host, IP). For a Defender-side finding, capture the evidence and
     link it in the register.
6. Repeat for the other pilot hunts: `Hunt-RareParentChild-Devices-Pilot` (**T1055/T1036**),
   `Hunt-InboxRules-M365-Pilot` (**T1114**), `Hunt-RareServiceSignin-Entra-Pilot` (**T1078**),
   `Hunt-BeaconEgress-Network-Pilot` (**T1071**).
   - **Gate 2:** every pilot hunt has run, been triaged, and been documented (outcome + decision), with
     bookmarks for any finding → continue.

## Phase 3 — Hand off confirmed findings to incident response (the reactive boundary)

For any hunt that **confirms a true positive**, hand it off — do **not** respond from here.

1. In Sentinel, from the finding's bookmark, **create an incident** (Bookmarks → select →
   **Create incident**, or add the bookmark to an existing incident) so the finding enters the reactive
   queue with its evidence and entities attached.
2. Attach the register entry (hypothesis, query, scope) and the bookmark(s) so responders inherit the
   full context.
3. **Trigger the *M365 & Azure Incident Response & Escalation Runbook*** intake — that solution owns
   triage, containment (device isolation, account disablement, mailbox purge), eradication, and
   escalation. This solution's job ends at a clean, evidenced hand-off.
   - **Gate 3:** confirmed findings are incidents in the reactive queue with evidence attached; no
     response action was taken from within the hunt → continue.

## Phase 4 — Validate (coherent results + a clean promotion)

1. Run **`THREATHUNTG-Validate.ps1`** — pass/fail lines aligned to `05-testing.md`: the hunter RBAC group
   is read-only, the library is saved/tagged on both surfaces, the expected tables have data, the pilot
   hunts produced documented outcomes, and **at least one successful hunt has been promoted** to a
   scheduled analytics rule / custom detection.
2. **Promote a successful hunt into a permanent detection** (elevated admin, not a hunter):
   - **Defender XDR side:** advanced hunting → open the saved hunt (e.g. `Hunt-LOLBins-Devices-Pilot`) →
     **Create custom detection rule** → name it **`CD-LOLBins-Devices-Prod`**, set frequency, impacted
     entities, and the **ATT&CK technique** tag. *(Custom-detection availability/limits can differ by
     license and cloud — verify.)*
   - **Sentinel side:** Sentinel → **Hunting → Queries → the saved hunt → Create analytics rule** (or
     **Analytics → Create → Scheduled rule** with the hunt's KQL) → name it **`Rule-RareServiceSignin-
     Entra-Prod`**, set schedule, entity mappings, and MITRE tags. **Start it in a low-impact posture**
     (incident creation disabled) and **tune it** using the *Microsoft Sentinel Analytics Rules & MITRE
     ATT&CK Detection Coverage* solution before it creates incidents the SOC trusts.
   - **Gate 4 (go/no-go):** validation lines PASS and at least one hunt is promoted (as a `-Prod`
     detection) → the program is working; expand.

## Phase 5 — Expand (grow the library, run the cadence)

1. **Promote the hunts worth keeping.** Any hunt that repeatedly finds real, actionable activity becomes
   a `-Prod` detection (name per the table). Any hunt that only ever returns benign noise is either
   refined or retired — record which in the register.
2. **Grow the library across the ATT&CK matrix.** Add hunts for the next priority techniques (the
   library file has a template header to copy). Tag every new hunt so the coverage map keeps growing.
3. **Run `Hunt Cadence - Tenant - Monthly`.** Each cycle: pick the next backlog items, run
   `THREATHUNTG-RunHuntLibrary.ps1`, triage, document, promote/hand-off, and re-report with
   `THREATHUNTG-Report.ps1`. Hunting is a **program**, not a one-time task.
4. **Track the trend.** A growing set of tagged hunts, findings that turn into detections, and shrinking
   time-to-find are the signs the program is working — `THREATHUNTG-Report.ps1` surfaces these.

## Rollback (for any step)

- **A saved hunt query:** delete it (Hunting → Queries / advanced hunting → the saved query → Delete) —
  it stops appearing on the shelf; nothing else changes (queries are read-only).
- **A promoted detection:** disable it (Sentinel Analytics → the rule → **Disable**, or Defender →
  Custom detection rules → the rule → **Turn off**) — it stops evaluating immediately; the saved hunt
  remains.
- **The hunter RBAC group:** remove the role assignment to revoke hunting access cleanly (the group and
  its history remain for audit).
- **A bookmark / incident hand-off:** a bookmark can be deleted; an incident created from it should be
  **closed with a classification** (do not silently delete) so the reactive record stays intact.
