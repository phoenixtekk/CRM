# 1. Solution Overview — CMMC / CUI DLP Pack (Microsoft Purview)

## What this solution is
Organizations that hold **Controlled Unclassified Information (CUI)** under a federal contract — Covered
Defense Information / Controlled Technical Information under **DFARS 252.204-7012**, and the safeguarding
expectations of **NIST SP 800-171** and **CMMC** — must be able to show that CUI does not leave the
boundary uncontrolled. **Microsoft Purview Data Loss Prevention (DLP)** provides that control: it detects
CUI as it moves through **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** and
applies an action — audit, warn with a **policy tip**, allow with a **justification**, or **block** — when
CUI is about to leave the boundary or reach an unauthorized recipient.

This solution is a repeatable, evidence-driven way to stand up **CUI-tuned DLP** using only the **Microsoft
Purview portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no
third-party DLP tooling. Its two defining disciplines are **marking-awareness** — DLP keys off the **CUI
sensitivity label** and the **CUI banner/portion markings** your organization applies, not a guessed
pattern — and **simulation-first**: every policy is built and proven in **SIMULATION mode** (Microsoft's
built-in test mode that shows what *would* be blocked, with zero user impact), tuned for a low
false-positive rate, and only then enforced.

> **Scope boundary — CMMC/CUI determinations are deferred.** This solution delivers the **technical DLP
> method and the evidence**. *Which* data is CUI, *which* CUI categories apply, *how* CUI must be marked,
> and *what* the enforced action must be are **compliance, contracts, records, and legal determinations**.
> **CMMC control-satisfaction and assessment determinations — whether a given NIST SP 800-171 / CMMC
> practice is "met", the SPRS score, and the assessment outcome — are the responsibility of your compliance
> function and, for certification, a certified third-party assessor (C3PAO).** This pack configures and
> proves a supporting technical control and produces evidence for it; it does not make the assessment call.

## Why this matters
- **CUI is defined by marking, not by a magic detector.** There is no single built-in "CUI" sensitive
  information type. CUI is identified by the **CUI banner marking** (e.g. `CUI`, `CUI//SP-CTI`,
  `CUI//SP-EXPT`) your organization applies per the **NARA CUI Registry** and 32 CFR Part 2002, and by the
  **sensitivity label** you attach to it. A DLP program that ignores marking will both miss real CUI and
  fire on everything.
- **DLP switched straight to enforce is the classic failure** — it blocks legitimate contract work, floods
  the help desk, and gets disabled within a week. Simulation-first is the difference between a control that
  survives an assessment and one that was turned off before it.
- **CUI environments are frequently GCC / GCC High.** Feature availability, portal paths, and some SIT/label
  capabilities differ between Commercial, GCC, and **GCC High** tenants. This solution **flags "verify your
  licensing/tenant"** rather than asserting availability — GCC High in particular must be verified.
- The same label + SIT layer that drives CUI DLP also drives **encryption, auto-labeling, and insider
  risk** — getting CUI marking right here pays off across the whole safeguarding program.

## How it works
1. **The CUI sensitivity label is the primary signal.** A published **`CUI`** sensitivity label (optionally
   with sub-labels per CUI category, e.g. `CUI//SP-CTI`) applies **content markings** (header/footer banner
   `CUI`) and, where required, **encryption**. DLP conditions then match **"content contains sensitivity
   label = CUI"** — the most reliable detector because it follows the marking decision a human or
   auto-labeling policy already made.
2. **Marking/keyword detection backs up the label.** A **custom SIT / keyword dictionary**
   (`CUI Banner Marking – Custom SIT – Classification`) detects the literal **CUI banner and portion
   markings** in body/attachment text, so CUI that is marked-but-not-yet-labeled (or arriving from a
   partner) is still caught. Category-specific keyword lists (e.g. export-control, CTI terms) refine it. *No
   marking string is invented — you supply the exact markings your CUI policy uses.*
3. **DLP policies** bind the label + marking conditions to **locations** (Exchange, SharePoint, OneDrive,
   Teams, **Devices/Endpoint**) with **conditions** (label present, marking present, recipient is external),
   **actions** (audit / notify / restrict / block; on endpoint restrict USB/print/cloud-upload/clipboard),
   and **user experience** (policy tips, allow-with-justification).
4. **Simulation mode** runs each policy against live traffic and records what *would* have matched — with no
   enforcement — so the true hit volume and false positives are known **before** anything is blocked.
5. **Tuning** reduces false positives (label-based conditions, confidence, instance counts, exceptions),
   measured against the simulation results.
6. **Enforcement + evidence** turns the tuned policy on for a pilot ring then expands, while **DLP alerts**
   and **Activity Explorer** produce the **evidence trail** an assessor or contracting officer expects.

## The five DLP locations (and what each controls for CUI)
- **Exchange (email):** outbound mail carrying CUI to external/unauthorized recipients — block or encrypt.
- **SharePoint & OneDrive:** CUI documents at rest and when shared — block external sharing on match.
- **Teams chat & channel messages:** CUI pasted or shared in messages.
- **Endpoint (Devices):** activities on **onboarded** Windows/macOS devices — copy CUI to USB, copy to
  network share, print, upload to unallowed cloud apps/browser, copy to clipboard. **Requires onboarding and
  the right licensing.**
- **On-premises / cloud apps (Defender for Cloud Apps):** additional locations that may be available
  depending on licensing/tenant — **verify availability (especially GCC High).**

## The simulate→enforce journey (the core discipline)
> Confirm the **CUI label + markings** (compliance decision) → build each DLP policy keyed on
> **label = CUI** and **CUI markings** in **SIMULATION** (no user impact) → measure hit volume and false
> positives in **Activity Explorer / DLP alerts** → **tune** → re-simulate until false positives are
> acceptable → enable with **policy tips + allow-override** in a **pilot ring** → validate → expand to
> **enforce (block/encrypt)** across the CUI-handling population → operate (triage alerts, retain evidence,
> re-tune).

## What you can control
- Which **CUI sensitivity label(s)** and which **CUI markings/keywords** each policy detects.
- Which **locations** each policy covers and which users/sites/groups are **included or excluded** (the
  CUI-handling enclave vs the rest of the tenant).
- The **action** per condition (audit → tip → justify → block/encrypt) — set per the CUI safeguarding
  determination.
- Whether users get **policy tips**, can **override** with justification, and the notice wording.
- The **pilot ring** enforced first and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **CUI marking is a prerequisite, not an output.** DLP is only as good as the marking/labeling program
  feeding it — if CUI is not marked or labeled, a marking-keyed policy cannot see it. This pack assumes (and
  its Requirements name) a CUI labeling decision.
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint DLP
  and several advanced classifiers are gated behind **E5 / E5 Compliance**). A Devices-location policy is
  inert until onboarding is complete.
- **GCC High and preview features must be verified** — availability and portal paths differ; this solution
  flags rather than asserts.
- DLP inspects **content it can classify**; strongly-encrypted or unrecognized formats, or content below the
  match threshold, will not match. DLP is one NIST SP 800-171 / CMMC supporting control among many, not a
  guarantee of compliance.
- **The enforced action, the CUI categories in scope, and CMMC assessment outcomes are compliance / legal /
  C3PAO decisions**, not technical defaults — this solution configures and proves the control; the
  determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| CUI sensitivity label (parent) | `CUI` |
| CUI sub-label (per category, example) | `CUI//SP-CTI`, `CUI//SP-EXPT` |
| CUI marking keyword SIT | `CUI Banner Marking – Custom SIT – Classification` |
| Email DLP policy (simulation) | `DLP – CUI Email – Simulation` |
| Cloud DLP policy (simulation) | `DLP – CUI SPO+OneDrive+Teams – Simulation` |
| Endpoint DLP policy (simulation) | `DLP – CUI Endpoint – Simulation` |
| Enforced pilot policy | `DLP – CUI All Locations – Enforce Pilot` |
| Pilot user ring | `CUI DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `CUI Notice – Standard – AllPolicies` |
| Incident/alert workflow | `CUI DLP Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** current CUI exposure, marking/label state, and licensing/tenant (incl. GCC High) → **Design**
> the label + marking detection and the policies/user experience → **Configure** policies **in simulation**
> → **Pilot** (simulate → tune → enforce to a ring) → **Validate** against pass/fail gates (CUI leaks
> blocked, false-positive rate low, incidents handled + evidenced) → **Expand** to the full CUI-handling
> population and ongoing operations. Every high-impact change is piloted in simulation first, with a
> documented rollback. Regulatory/records/legal and **CMMC assessment determinations are deferred**.
