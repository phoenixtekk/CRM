# 2. Requirements Guide — Microsoft Defender for Endpoint

Verify **every** requirement that applies to the workstreams you will run. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to deploying, optimizing, enabling a team on, and proving Microsoft Defender for Endpoint**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

The requirements are grouped by workstream. **Deploy (2.1–2.7)** applies to a fresh or partial deployment; **Operate & Optimize (2.8–2.10)** applies when tuning an existing deployment; **Enable (2.11–2.13)** applies to the team labs; **Prove (2.14–2.16)** applies to the guided PoC. A green-field engagement runs Deploy then Optimize; an already-deployed tenant may start at Optimize; the Enable and Prove workstreams layer on top of an onboarded MDE.

---

## Deploy — onboard MDE end to end

### 2.1 Defender for Endpoint activated
**Description:** MDE initialized for the tenant under `security.microsoft.com` → **Settings → Endpoints**.
**Why:** Onboarding packages, ASR/AV policy, device groups, and RBAC only appear after first-time activation.
**Verify:** Sign in as a Security Administrator and confirm **Settings → Endpoints → Onboarding** loads. Run `MDEFULL-Discovery.ps1`.
**Implement-if-missing:** Complete the one-time MDE activation (Global Administrator required for first-service activation only).

### 2.2 Onboarding channel per platform
**Description:** A working onboarding channel for each platform in scope — **Intune** (default for Windows/macOS), **Group Policy / local script** for Windows, the **macOS** MDM profile + package, and the **Linux** repo + package.
**Why:** MDE collects EDR signal only from onboarded devices; each platform onboards through its own channel.
**Verify:** `MDEFULL-Discovery.ps1` reports the platform mix and current onboarding coverage; confirm the Intune MDE connector is **Enabled**.
**Implement-if-missing:** Establish the channel per platform — *cross-reference the catalog's "Defender for Endpoint Integration" (Intune connector) and "Defender for Endpoint macOS Onboarding via Intune" solutions* — and target the pilot ring first.

### 2.3 Pilot device ring defined
**Description:** A named pilot device group `MDE Device Group – Pilot Ring – Pilot` (Entra/Intune) covering a representative mix of Windows/macOS/Linux.
**Why:** Onboarding and the disruptive controls (ASR, block mode) are validated on a ring before the fleet (per `global-requirements-defender.md` G6).
**Verify:** The group exists; `MDEFULL-Validate.ps1 -Check Onboarding` checks membership/coverage.
**Implement-if-missing:** Create `MDE Device Group – Pilot Ring – Pilot` before onboarding anything that enforces.

### 2.4 EDR / next-gen AV baseline decision
**Description:** A decision on **EDR in block mode** and the antivirus posture (Defender AV primary, or third-party AV with EDR block mode).
**Why:** Block mode is what lets EDR block artifacts behind a non-Microsoft AV; the posture must be agreed.
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Advanced features → EDR in block mode**; `MDEFULL-Validate.ps1 -Check EDR` reports it.
**Implement-if-missing:** Decide the AV posture and plan to enable EDR in block mode after pilot onboarding.

### 2.5 ASR rollout scope (audit-first)
**Description:** The **attack surface reduction** rules to deploy and the plan to run them **audit → block** on the ring.
**Why:** ASR rules can break line-of-business apps if enforced blind; audit-first surfaces the impact.
**Verify:** `MDEFULL-Validate.ps1 -Check ASR` reports current ASR rule states; a rule list and exclusions are drafted.
**Implement-if-missing:** Draft the ASR rule set and exclusions, create the policy `MDE ASR Rules – Pilot Ring – Audit`, and only later promote to `MDE ASR Rules – Pilot Ring – Block`.

### 2.6 Tamper protection and web content filtering scope
**Description:** Intent to enforce **tamper protection** tenant-wide and to configure **web content filtering** categories (P2).
**Why:** Tamper protection stops the stack being disabled; web content filtering adds endpoint web control. *Web content filtering requires P2 and network protection — verify current availability.*
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Advanced features** (tamper protection) and **Web content filtering**; `MDEFULL-Validate.ps1 -Check Config` reports both.
**Implement-if-missing:** Plan tamper protection enforcement and draft the web content filtering categories/policy `MDE Web Content Filtering – Tenant – Prod`.

### 2.7 Device groups, RBAC, live response, and response governance
**Description:** The **device group** structure (with per-group AIR automation levels), the **RBAC** role model (reader / operator), **live response** approval controls, and an agreed position on **automated investigation and response (AIR)** automation levels kept approval-gated during the pilot.
**Why:** Device groups drive automation scope; RBAC scopes analyst permissions; live response is powerful and must be gated; AIR can isolate devices and remediate files, so the organization decides the guardrails (per `global-requirements-defender.md` G8).
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Permissions** (Roles, Device groups) and **Advanced features → Live Response**; `MDEFULL-Validate.ps1 -Check RBAC` reports them; a documented response policy exists.
**Implement-if-missing:** Plan `MDE Device Group – Pilot Ring – Pilot`, roles `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod`, and live-response approval settings; keep AIR approval-gated at first. *Incident-response and automation-guardrail decisions are the SOC/security team's — this guide covers the technical configuration.*

---

## Operate & Optimize — tune an existing deployment

### 2.8 An existing, working deployment with ASR audit history
**Description:** Where you are tuning rather than deploying fresh: MDE is already **onboarded** with devices reporting, and the target ASR rules have run in **Audit** long enough to produce representative data on your software estate.
**Why:** Optimization tunes an existing deployment; moving a rule to **Block** safely depends on knowing what it *would* have blocked — that is exactly what audit data shows.
**Verify:** `security.microsoft.com` → **Assets → Devices** shows onboarded devices with **sensor health = Active**; **Reports → Attack surface reduction rules → Audit** shows audited events, or run `MDEFULL-Hunt.ps1 -Mode ASRAudit`. *Rule availability varies by platform/plan — verify current.*
**Implement-if-missing:** Complete the Deploy workstream first; set target rules to **Audit** and let them soak before reassessing for Block.

### 2.9 Authoritative policy surface identified
**Description:** A clear answer to **where** ASR/EDR/AV/tamper policy is currently authored — Intune Endpoint security, the Defender portal's configuration management, Group Policy, or Configuration Manager.
**Why:** You must change policy in the **authoritative** location; editing the wrong surface silently loses to the one that actually applies, or creates a split-brain conflict.
**Verify:** `security.microsoft.com` → **Configuration management → Endpoint security policies** and Intune → **Endpoint security**; confirm which owns the target devices. `MDEFULL-Discovery.ps1` reports Intune endpoint-security policies.
**Implement-if-missing:** Decide the single authoritative surface (Intune is recommended for cloud-managed devices) and migrate GPO/CM settings there before tuning.

### 2.10 A captured before-state baseline, change control, and rollback
**Description:** A saved snapshot of the current alert volume, false-positive proportion, ASR block coverage, and onboarding/sensor-health coverage — the "before" — plus an approved change record and a documented rollback before switching any ASR rule to block or tightening any policy.
**Why:** Optimization is only credible if the improvement is **measured**; and ASR block / hardened policy can affect real applications, so the pilot-first, audit/`-WhatIf`-first approach and a written back-out are the safety net.
**Verify:** A baseline file exists (`MDEFULL-Report.ps1 -SaveBaseline`); an approved change record, the pilot scope, and a written rollback (revert the ASR rule to audit / re-scope the policy) exist.
**Implement-if-missing:** Run `MDEFULL-Report.ps1 -SaveBaseline` and write the rollback before making any change.

---

## Enable — hands-on team labs

### 2.11 A learner cohort and a non-critical lab device group
**Description:** An Entra security group of the learners — `MDE Enablement Cohort – Team – Pilot` — and a small **device group** of non-critical devices, `MDE Lab Devices – Pilot Ring – Pilot`, for the live-response and ASR-audit labs.
**Why:** Live response connects to a real device and ASR audit generates events; practising on dedicated, non-critical devices is the safe way (category **G6**). Do **not** use executives' or production-critical machines for the labs.
**Verify:** Both groups exist and the lab devices are onboarded and healthy; `MDEFULL-Discovery.ps1` lists device groups.
**Implement-if-missing:** Create both groups and add a couple of non-critical onboarded test devices to the lab group.

### 2.12 Plan appropriate to the labs (P1 vs P2) and split roles
**Description:** The plan that covers the lab features — **EDR, advanced hunting, live response, and custom detections are Plan 2 capabilities** — and a role split where learners hold a **read/hunt** role (Security Reader with hunting, or Security Operator) while the instructor holds live-response permission and the ability to author custom detections.
**Why:** The investigation/hunting/live-response/detection labs depend on P2, and labs run at least privilege — only the gated demos need instructor elevation. *Verify current plan-to-feature mapping in your tenant.*
**Verify:** Confirm **Advanced hunting**, **Live Response**, and **Custom detection rules** load; **Permissions & roles** show the split; **Settings → Endpoints → Advanced features → Live Response** is enabled. `MDEFULL-Discovery.ps1` reports advanced-features state.
**Implement-if-missing:** Assign Defender for Endpoint **Plan 2** (often bundled in M365 E5 / E5 Security); assign read/hunt roles to the cohort (prefer PIM-eligible for elevated roles where Entra ID P2 is available — *verify licensing*); enable live response and grant the instructor the response role. On P1, run the prevention/ASR labs and defer the P2-only labs.

### 2.13 A read-only / no-production-response lab posture
**Description:** An agreed rule that all labs are **read-only or preview-first**: live response uses **only investigative commands**, ASR lab rules run in **audit**, the capstone detection is **alert-only**, and **no response action** (isolate, delete, disable) is executed against production during the labs.
**Why:** Learners operate against live devices; the posture must be explicit so no one isolates a machine or runs a destructive command "to see what happens."
**Verify:** The lab plan states the posture; ASR lab rules are audit; the detection is alert-only; live-response transcripts show only read-only commands. `MDEFULL-Validate.ps1 -Check Enablement` flags any block-mode lab rule or non-alert-only detection.
**Implement-if-missing:** State it at kickoff; route any real finding to the SOC's normal incident process (category **G8**).

---

## Prove — guided proof-of-concept

### 2.14 Pilot ring of test devices only, with evaluation criteria agreed up front
**Description:** A small set of **non-production test devices** grouped as `MDE PoC – Pilot Ring – Pilot`, plus a short, written list of what "pass" means (e.g. *detection fires within N minutes, appears on the device timeline, is queryable in advanced hunting, triggers an automated investigation*).
**Why:** The PoC must touch only disposable test devices so it can be torn down with zero production impact; and a PoC is only conclusive if the bar is set **before** you run it.
**Verify:** An Entra/Intune device group `MDE PoC – Pilot Ring – Pilot` exists with test devices, and a criteria list exists; `MDEFULL-PoC.ps1 -Action Enable -WhatIf` lists membership and `MDEFULL-PoC.ps1 -Action Score` accepts the criteria file.
**Implement-if-missing:** Create the group and add one to three test devices (a spare laptop or a test VM is ideal); draft 5–8 criteria with the evaluating stakeholders before enabling. *What counts as "good enough" is the customer's decision.*

### 2.15 A tester workstation for benign signal, with advanced-hunting read access
**Description:** Interactive access to a pilot device where a tester can drop the **EICAR** test file and run a Microsoft built-in simulation, plus permission to run advanced-hunting queries via the portal and the Graph Security API (`ThreatHunting.Read.All`).
**Why:** The benign signal must be generated **on** an onboarded device to produce the detection; the validate and scorecard steps confirm it landed in the hunting tables (`DeviceEvents`, `AlertInfo`, `AlertEvidence`).
**Verify:** You can sign in interactively to a device in `MDE PoC – Pilot Ring – Pilot`; **Hunting → Advanced hunting** runs a query; `MDEFULL-Validate.ps1 -Check PoC` authenticates and returns rows.
**Implement-if-missing:** Ensure at least one pilot device is accessible (console, RDP, or physical); grant the running account **Security Reader** (or higher) and consent to the read-only hunting scope.

### 2.16 Response governance for the PoC (approval-gated)
**Description:** Agreement that **AIR** stays in an **approval/semi** posture for the duration of the PoC.
**Why:** Even in a pilot, AIR can take actions (isolate, quarantine); the PoC proves detection without letting automation act unattended (per `global-requirements-defender.md` G8).
**Verify:** AIR automation level for `MDE PoC – Pilot Ring – Pilot` is **Semi — require approval**; `MDEFULL-Validate.ps1 -Check PoC` reports it.
**Implement-if-missing:** Set the pilot group's automation level to **Semi — require approval** before generating signal. *The automation-guardrail decision is the SOC/security team's.*

---

## Checklist
**Deploy**
- [ ] MDE activated — `MDEFULL-Discovery.ps1`
- [ ] Onboarding channel per platform (Intune/GPO/script/macOS/Linux)
- [ ] Pilot device ring `MDE Device Group – Pilot Ring – Pilot` defined
- [ ] EDR block mode / AV posture decided
- [ ] ASR rollout scope (audit-first) drafted — `MDE ASR Rules – Pilot Ring – Audit`
- [ ] Tamper protection + web content filtering scope planned
- [ ] Device groups, RBAC, live-response, and AIR governance planned (approval-gated)

**Operate & Optimize**
- [ ] Existing, reporting deployment with ASR audit history — `MDEFULL-Hunt.ps1 -Mode ASRAudit`
- [ ] Authoritative policy surface identified (Intune / Defender / GPO / CM)
- [ ] Before-state baseline saved, change window + rollback documented — `MDEFULL-Report.ps1 -SaveBaseline`

**Enable**
- [ ] Cohort `MDE Enablement Cohort – Team – Pilot` + lab group `MDE Lab Devices – Pilot Ring – Pilot`
- [ ] Plan supports the labs (P2) and roles split (read/hunt vs instructor)
- [ ] Read-only / no-production-response lab posture agreed

**Prove**
- [ ] Pilot ring `MDE PoC – Pilot Ring – Pilot` (test devices only) + written criteria
- [ ] Tester workstation for benign EICAR/simulation signal + advanced-hunting read access
- [ ] AIR kept approval-gated for the PoC
