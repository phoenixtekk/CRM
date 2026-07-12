# Deliverables Summary — Microsoft Defender for Office 365

Everything included in this solution, and what each piece is for. This is the **operate/enable/prove**
layer over MDO — it cross-references the **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for
Office 365** solution (prevention config) and the **Defender for Office 365 (Plan 2) — Threat Explorer,
Attack Simulation & AIR** solution (post-delivery rollout) rather than repeating them.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "email-security bought and under-driven / value unproven" problem, the two-track solution (enable the team + prove value), the boundary (operate/enable/prove layer; read-only/preview-first; inspects but does not reconfigure; cross-references Mail Hygiene and Plan 2), and effort. |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how MDO works (prevention vs post-delivery, Threat Explorer, the protection stack, Attack Simulation Training, AIR, email hunting, benign PoC signal), the Assess→Configure→Pilot→Validate→Expand model across both tracks, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (Plan 1-vs-2 availability, the prevention stack to inspect and prove against, a consented pilot group, a simulation/communications note, split roles, a read-only/preview/-WhatIf posture, PoC evaluation criteria, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | The full playbook: assess readiness, create the cohort + pilot group, load the KQL pack, run Track A Labs 1–8 (console/model → Threat Explorer → inspect the stack → benign simulation → email hunting → AIR held for approval → alert-only detection → reporting), run Track B PoC (benign signal → demonstrate detections), then capstone + knowledge-check + PoC evidence, then expand and tear down — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Twelve pass/fail gates covering environment readiness, skills landed, PoC detections observed, AIR posture, alert-only detection, knowledge-check, evidence capture, and clean teardown — referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (Explorer missing, sim blade absent, empty email tables, schema drift, AIR auto-deleting, no pending actions, benign signal not delivered, Safe Links/Attachments not acting, detection noisy, beta API empty, connection errors, teardown residue) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Hunt-on-a-question, understand-the-stack-then-let-the-right-solution-change-it, prove-it-don't-pitch-it, simulate-to-measure-not-punish, automate-only-when-trusted, turn-hunts-into-durable-coverage, run-it-as-a-program — plus where to go next in the catalog. |

## Lab pack + PowerShell helpers (6)

All helpers are **read-only or preview-first / -WhatIf-gated**, authenticate **interactively** (no
credentials in code), and use **Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`;
`Mail.Send` for the benign PoC test messages; attack-sim **beta** reporting where available) and, where
used, **Exchange Online / Security & Compliance** for reporting and quarantine. Government-cloud
tenants pass the matching environment — *verify endpoints for your cloud.*

| File | Type | What it does |
| --- | --- | --- |
| **`MDOFULL-Labs.kql`** | KQL lab pack | The runnable, progressive email query library — one labeled section per hunting lab (post-delivery clicks, sender/subject campaign, bad-attachment hash, delivered-then-detected), the capstone candidate, and the PoC benign-signal validation queries. The core take-home artifact. |
| **`MDOFULL-Discovery.ps1`** | Read-only | Inventories readiness: Plan 2 presence, email-table freshness (`EmailEvents` etc.), pilot-group membership, and the Action center pending posture. Changes nothing. |
| **`MDOFULL-RunLab.ps1`** | Read-only | Runs a chosen email hunting-lab query (`-Lab <n>`) from the pack via Graph and returns the rows — so learners can execute a lab from PowerShell as well as the portal. |
| **`MDOFULL-TestSignal.ps1`** | `-WhatIf`-gated | Generates **benign** PoC signal — prints the Attack Simulation launch steps and sends GTUBE / EICAR / Safe Links test messages (never real threats); a `-Teardown` mode purges the `MDOFULL-TESTSIGNAL` messages from quarantine and prints the steps to end the simulation. |
| **`MDOFULL-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines: readiness, email tables have data, hunting resolves, the PoC capability checks (Safe Links / Safe Attachments / spam-phish), AIR pending, `Detect-MDOFULL-Pilot` alert-only — and scores the knowledge-check `Check-MDOFULL-Pilot`. |
| **`MDOFULL-Report.ps1`** | Read-only | Reports cohort progress and per-lab email-data availability, and captures the **PoC evidence** — maps observed capabilities to the agreed criteria and writes `MDOFULL Evidence – Pilot Users – Validate.json` + an optional CSV. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-MDOFULL-Cohort-Pilot`
- **Pilot user group:** `Grp-MDOFULL-PilotUsers-Pilot`
- **Explorer saved view:** `Explorer-MDOFULL-Pilot`
- **Shared saved-query set:** `Hunt-MDOFULL-Pilot`
- **Simulation:** `Sim-MDOFULL-Pilot`
- **Training assignment:** `Training-MDOFULL-Pilot`
- **Custom detection (capstone):** `Detect-MDOFULL-Pilot` (alert-only)
- **Knowledge-check:** `Check-MDOFULL-Pilot`
- **PoC test-signal tag:** `MDOFULL-TESTSIGNAL`
- **PoC evidence file:** `MDOFULL Evidence – Pilot Users – Validate.json`

## What this solution deliberately does NOT do

- It does **not** configure the prevention stack — anti-spam/-malware/-phishing, Safe Links, Safe
  Attachments, and mail-flow hygiene are the **Mail Hygiene** solution. This solution **inspects** them
  and proves detections against them.
- It does **not** perform the operational post-delivery rollout — turning the features on org-wide,
  tuning AIR automation, and running gated production remediation is the **Defender for Office 365 (Plan
  2)** solution. This solution builds the **skill** and the **proof**.
- It does **not** execute production remediation — AIR stays **approval-required**, remediation is
  **previewed only**, Explorer take-action is **not** performed against production, the capstone
  detection is **alert-only**, and the PoC generates only **benign** signal.
- It does **not** decide **who to simulate, acceptable click-rate, the AIR automation level, or what
  counts as a PoC "pass"** — those are security-leadership / HR-legal determinations; this solution
  provides the skill, the labs, the data, and the proof.
- It does **not** invent plan, feature, or schema facts — where availability may differ by plan (P1/P2)
  or cloud (GCC/GCC High) it says **verify in your tenant**.

## How it is delivered

Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation as a formatted
Word document and PDF, plus the email KQL lab pack and all five PowerShell helpers, in a single ZIP
(`MDOFULL-Complete-Solution.zip`) — yours to keep and re-run for every new cohort and every new
stakeholder who needs to see the proof.
