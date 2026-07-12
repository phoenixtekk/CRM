# 3. Implementation Guide — Microsoft Defender for Endpoint

Follow these steps **in order** within each workstream. Configuration spans the **unified Defender portal** (`https://security.microsoft.com`) and the **Intune admin center** (`https://intune.microsoft.com`) as the default onboarding/policy channel. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model (every workstream):** Assess readiness, configure on a **pilot ring** first, validate against explicit gates, then expand. Bring the disruptive controls (**ASR**, **EDR block mode**) up **audit → block**; keep **automated response (AIR)** approval-gated throughout; measure **before/after** when optimizing; run enablement labs **read-only/preview-first**; make the PoC **fully reversible**. Never remove an existing control to "test."

The Implementation runs in four parts, matching the lifecycle **Deploy → Operate & Optimize → Enable → Prove**. A green-field tenant runs Part A then Part B; an already-deployed tenant can start at Part B. Parts C and D layer on an onboarded MDE. A team still evaluating MDE before purchase can run **Part D (Prove)** first as a pre-deployment proof, then come back to Part A.

## Naming (set once, reuse verbatim)
**Deploy / Optimize**
- Pilot device group: `MDE Device Group – Pilot Ring – Pilot`
- Onboarding profile (Intune, Windows): `MDE Onboarding – Pilot Ring – Pilot`
- Next-gen AV / hardening policy: `MDE Next-Gen AV – Pilot Ring – Prod`, `MDE Endpoint Hardening – Pilot Ring – Pilot`
- ASR policies: `MDE ASR Rules – Pilot Ring – Audit`, `MDE ASR Rules – Pilot Ring – Block`, `MDE ASR Rules – All Devices – Prod`
- Web content filtering policy: `MDE Web Content Filtering – Tenant – Prod`
- RBAC roles: `MDE Security Reader – Tenant – Prod`, `MDE Security Operator – Tenant – Prod`
- Noise tuning (per item): `MDE FP Suppression – <detection> – Prod`, `MDE Allow Indicator – <object> – Prod`
- Advanced-hunting saved query: `MDE Onboarding Coverage – Tenant – Validate`

**Enable**
- Learner cohort group: `MDE Enablement Cohort – Team – Pilot`
- Lab device group: `MDE Lab Devices – Pilot Ring – Pilot`
- Shared saved-query set: `MDE Hunt Library – Team – Pilot`
- ASR lab config (audit): `MDE ASR Lab – Lab Devices – Audit`
- Custom detection (capstone, alert-only): `MDE Lab Detection – Team – Pilot`
- Knowledge-check: `MDE Knowledge Check – Team – Pilot`

**Prove**
- PoC pilot device group: `MDE PoC – Pilot Ring – Pilot`
- PoC Intune EDR onboarding policy: `MDE PoC EDR Onboarding – Pilot Ring – Pilot`
- Scorecard output: `MDE PoC Scorecard – Pilot Ring – Validate`
- Test-signal run tag: `MDE-PoC-TESTSIGNAL`

---

# Part A — Deploy (onboard MDE end to end)

## Step A1 — Assess readiness
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MDEFULL-Discovery.ps1` to capture current state: MDE activation, licensed plan (P1/P2) hints, admin roles, platform mix, onboarding coverage, sensor health, endpoint-table freshness, device groups/tags, and the Intune MDE connector status.
3. In **Intune/Entra → Groups**, create `MDE Device Group – Pilot Ring – Pilot` with a representative Windows/macOS/Linux mix.

## Step A2 — Onboard the pilot ring
1. `security.microsoft.com` → **Settings → Endpoints → Onboarding**. If MDE is not initialized, complete the one-time activation.
2. **Windows via Intune (default):** confirm `intune.microsoft.com` → **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**. Create the EDR onboarding profile `MDE Onboarding – Pilot Ring – Pilot` and assign it only to `MDE Device Group – Pilot Ring – Pilot`. (GPO/local-script channels use the package from **Settings → Endpoints → Onboarding** against the pilot OU.)
3. **macOS:** deploy the MDM onboarding profile + package to the pilot Macs (*cross-reference the macOS onboarding solution*). **Linux:** onboard via the documented repo + package method on the pilot Linux hosts. *Verify current macOS/Linux onboarding steps and support.*
4. On pilot devices, confirm onboarding in **Assets → Devices**.
5. Run `MDEFULL-Validate.ps1 -Check Onboarding` to confirm each pilot device reports EDR signal.

## Step A3 — Next-gen AV and EDR in block mode
1. In Intune → **Endpoint security → Antivirus**, create `MDE Next-Gen AV – Pilot Ring – Prod` (real-time protection, cloud-delivered protection, PUA) assigned to the pilot ring.
2. `security.microsoft.com` → **Settings → Endpoints → Advanced features** — enable **EDR in block mode** (lets EDR block artifacts behind a third-party AV).
3. Run `MDEFULL-Validate.ps1 -Check EDR` to confirm block mode and AV posture.

## Step A4 — Attack surface reduction (audit first)
1. In Intune → **Endpoint security → Attack surface reduction**, create `MDE ASR Rules – Pilot Ring – Audit` with the chosen ASR rules set to **Audit**, assigned to the pilot ring.
2. Let it run, then review what the rules *would* block with `MDEFULL-Report.ps1 -Section ASR` and the advanced-hunting `DeviceEvents` for `Asr*Audited`. Add exclusions for legitimate line-of-business behavior.
3. Only after review, create `MDE ASR Rules – Pilot Ring – Block` with the validated rules set to **Block**, assigned to the pilot ring.
4. **Preview the flip first:** run `MDEFULL-PromoteASR.ps1` (defaults to `-WhatIf`) to see exactly which rules would change to Block; re-run with `-Apply` (or complete it in the portal). Then run `MDEFULL-Validate.ps1 -Check ASR` to confirm rule states.

## Step A5 — Tamper protection and web content filtering
1. `security.microsoft.com` → **Settings → Endpoints → Advanced features → Tamper Protection** — enforce it (protects the stack from being disabled).
2. **Settings → Endpoints → Web content filtering** — create `MDE Web Content Filtering – Tenant – Prod` for the categories to control (P2). *Web content filtering requires P2 and network protection — verify current availability.*
3. Run `MDEFULL-Validate.ps1 -Check Config` to confirm tamper protection and web filtering.

## Step A6 — Device groups and RBAC
1. `security.microsoft.com` → **Settings → Endpoints → Permissions → Device groups** — define `MDE Device Group – Pilot Ring – Pilot` with the pilot ring and set its **automation level** to **Semi — require approval** during the pilot.
2. **Settings → Endpoints → Permissions → Roles** — create `MDE Security Reader – Tenant – Prod` (read-only) and `MDE Security Operator – Tenant – Prod` (read + response); assign least privilege.
3. Run `MDEFULL-Validate.ps1 -Check RBAC` to confirm device groups and roles.

## Step A7 — Live response and automated response (approval-gated)
1. `security.microsoft.com` → **Settings → Endpoints → Advanced features → Live Response** — enable it, and require **live response for servers** / approval per your policy. Live response is powerful — restrict who can run it via the RBAC roles above.
2. Confirm the pilot device group's AIR **automation level** remains **Semi — require approval** (Step A6). Record it with `MDEFULL-Report.ps1`.
3. *The decision to raise automation or broaden live response is the SOC/security team's — this guide leaves it approval-gated.*

## Step A8 — Validate coverage, detections, and TVM baseline on the ring
1. Run `MDEFULL-Hunt.ps1 -Mode Coverage` to execute `MDE Onboarding Coverage – Tenant – Validate` — it confirms `DeviceInfo` shows the pilot devices onboarded/healthy and that `DeviceEvents`/`DeviceTvmSoftwareVulnerabilities` are populating.
2. Run the Microsoft-provided **EDR detection test** (safe, documented) on a pilot device and confirm the alert appears in **Incidents & alerts**. Confirm an ASR-block event on a device once block mode is on.
3. `security.microsoft.com` → **Vulnerability management → Dashboard** — record the exposure baseline with `MDEFULL-Report.ps1 -SaveBaseline`.
4. Complete the **Testing Guide** (Tests 1–8) before expanding.

## Step A9 — Expand across the fleet
1. **Onboarding:** broaden the Intune assignment (or create the next ring) to cover remaining Windows devices in waves; extend the macOS/Linux onboarding to the rest of those fleets.
2. **ASR/block mode:** promote `MDE ASR Rules – Pilot Ring – Block` to `MDE ASR Rules – All Devices – Prod` (and block mode) to production rings after each ring validates clean.
3. **Web filtering / tamper protection:** confirm tenant-wide.
4. **RBAC / automation:** review AIR automation levels with the SOC only after coverage and detections are trusted (still their decision).
5. Re-baseline exposure with `MDEFULL-Report.ps1 -SaveBaseline` and track coverage/exposure drift each cycle.

---

# Part B — Operate & Optimize (tune the deployment)

> Baseline the current deployment, tune on the pilot ring first, **measure the before/after delta**, then expand ring by ring. Every disruptive change starts in **audit / `-WhatIf`**, and every step names a rollback. *Which detections are true incidents, and whether a suppression or ASR block is acceptable for a business-critical app, are the SOC/security team's decisions.*

## Step B1 — Baseline the current deployment (measure "before")
1. `security.microsoft.com` → **Reports → Attack surface reduction rules** and **Assets → Devices**. Note current ASR rule states, onboarded/active device counts, and open-alert volume.
2. Run `MDEFULL-Discovery.ps1` to capture, read-only: onboarded devices and sensor health, device groups/tags, ASR rule states, tamper/EDR-block-mode/web-filtering state, and Intune endpoint-security policies.
3. Run `MDEFULL-Report.ps1 -SaveBaseline` to record the **before** metrics — alert volume, false-positive proportion, ASR block coverage, and onboarding/sensor-health coverage — to the baseline file.
4. Run `MDEFULL-Hunt.ps1 -Mode ASRAudit` to list which ASR rules have audit hits and on which devices (your evidence for safe block decisions).

## Step B2 — Move ASR rules audit → block on the pilot ring
1. Review the ASR audit evidence: any rule with **only benign** audited events across the pilot ring is a safe **Block** candidate; any rule blocking a real line-of-business app needs an **allow/exclusion** or stays in audit. *Whether a given app is business-critical is the app owner's call.*
2. In the authoritative surface, set the vetted rules to **Block** on `MDE ASR Rules – Pilot Ring – Block` (Intune → **Endpoint security → Attack surface reduction**, or `security.microsoft.com` → **Configuration management → Endpoint security policies**); keep unproven rules at **Audit**.
3. **Preview the flip first:** run `MDEFULL-PromoteASR.ps1 -PolicyName 'MDE ASR Rules – Pilot Ring – Block' -Rules <ids>` (defaults to `-WhatIf`) to see exactly which rules would change to Block; re-run with `-Apply`.
4. **Assign** the policy to `MDE Device Group – Pilot Ring – Pilot` only. Add any exception as a scoped ASR **file/folder exclusion** on the same policy, documented — never disable the whole rule to fix one app.

## Step B3 — Reduce alert noise and false positives (pilot)
1. `security.microsoft.com` → **Incidents & alerts → Alerts**. Identify the **repeating, benign** detections analysts already dismiss (`MDEFULL-Hunt.ps1 -Mode Noise` ranks them).
2. For a confirmed benign, recurring detection, create a **suppression rule** (Alert → **Create a suppression rule**), scoped as tightly as possible, named `MDE FP Suppression – <detection> – Prod`, with a **justification and review date**.
3. For a known-good file/cert/IP/URL, add an **allow indicator**: **Settings → Endpoints → Indicators → Add**, named `MDE Allow Indicator – <object> – Prod` — prefer a precise indicator over a broad AV exclusion.
4. Only where truly required, add a narrow antivirus **exclusion** in the AV policy — the last resort, because exclusions are blind spots.
5. Re-run `MDEFULL-Hunt.ps1 -Mode Noise` to confirm the tuned detections drop in volume. **Do not over-suppress** — every suppression is justified and time-bound.

## Step B4 — Expand coverage and standardize tags/groups
1. Run `MDEFULL-Hunt.ps1 -Mode Coverage` (and `MDEFULL-Discovery.ps1`) to find devices **not onboarded** or whose **sensor health** is Inactive/Misconfigured.
2. Onboard the stragglers through the authoritative channel (Part A). *Truly unmanaged devices must be brought under management first.*
3. Apply a consistent **device tag** scheme (by role/site) — **Assets → Devices → (device) → Manage tags**, or a dynamic rule — and confirm **device groups** target correctly for policy and RBAC.
4. Run `MDEFULL-Validate.ps1 -Check Tuning` → confirms sensor health improved and tags/groups resolve.

## Step B5 — Harden tamper protection, EDR block mode, and web filtering (pilot)
1. Create `MDE Endpoint Hardening – Pilot Ring – Pilot`: Intune → **Endpoint security → Antivirus / Endpoint detection and response** — enable **Tamper Protection**, confirm **EDR in block mode** is on, and set AV settings (cloud-delivered protection, PUA, real-time) to best practice.
2. Preview the tamper/EDR state with `MDEFULL-PromoteASR.ps1 -Mode Hardening` (reports current vs intended tamper/EDR state; changes nothing).
3. Confirm `MDE Web Content Filtering – Tenant – Prod` blocks the risk categories the security team specifies. *Web content filtering availability/plan — verify current. Choice of blocked categories is the security team's.*
4. **Assign** the hardening policy to `MDE Device Group – Pilot Ring – Pilot` only.

## Step B6 — Validate the pilot (measure "after") and expand ring by ring
1. Run `MDEFULL-Validate.ps1 -Check Tuning` → confirms ASR block rules applied, tamper on, EDR block mode on, web filtering active, sensor health healthy.
2. Run `MDEFULL-Report.ps1 -BaselinePath <baseline>` → shows the **before/after delta**: lower alert/false-positive volume, higher ASR block coverage, higher onboarding/sensor-health coverage.
3. Confirm no legitimate application broke on the pilot ring. Then clone the validated pilot policies to production scope (`MDE ASR Rules – All Devices – Prod` and the hardening/web-filtering policies), roll the suppression/indicator and tag/group discipline out estate-wide, and **re-baseline** after each wave with `MDEFULL-Report.ps1 -SaveBaseline`.

---

# Part C — Enable (hands-on team labs)

> A sequence of **guided hands-on labs** that take admins/SOC to confident EDR investigation and response. Run against real telemetry, **read-only or preview-first** — the only changes are one **alert-only** capstone detection and **audit-mode** lab ASR rules. This part **uses** the deployed MDE; it does not reconfigure it.

## Step C1 — Prepare the cohort and lab environment
1. Run `MDEFULL-Discovery.ps1` to confirm devices are reporting and endpoint tables have recent rows.
2. In **Entra → Groups → New group** create `MDE Enablement Cohort – Team – Pilot` and add learners.
3. In the Defender portal (or Intune) create `MDE Lab Devices – Pilot Ring – Pilot` with a couple of non-critical onboarded devices.
4. Assign read/hunt roles to learners; reserve live-response + detection-authoring to the instructor. Agree the **read-only / no-production-response** posture.
5. Open `MDEFULL-Labs.kql`; confirm you can paste a query into **Advanced hunting** and run it. Save each lab's good query into shared queries under `MDE Hunt Library – Team – Pilot`.
6. Note the ASR rules you will demonstrate in **audit** only as `MDE ASR Lab – Lab Devices – Audit`, scoped to `MDE Lab Devices – Pilot Ring – Pilot`. **Do not set any lab rule to block.** *Verify current ASR rule GUIDs/behavior.*

## Step C2 — Run the guided labs
- **Lab 1 — Console & the EDR mental model.** Tour **Incidents & alerts**, **Assets → Devices**, and a device page. *Check:* navigate to any incident/device/timeline/hunting blade unaided.
- **Lab 2 — Investigate an incident (graph + alert story).** Open a real (or built-in evaluation) incident; walk the graph, expand the alert story, identify the **root cause process** and **impacted assets**. *Check:* state what started it and how far it spread.
- **Lab 3 — Read a device timeline.** On a lab device, open **Timeline**, filter a window/event types, reconstruct a sequence. *Check:* answer "what did this machine do at time X?"
- **Lab 4 — Endpoint advanced hunting.** Run the pack's **Lab 4** queries (encoded-PowerShell, process→network correlation, per-device rollup) read-only via `MDEFULL-RunLab.ps1 -Lab 4`. *Check:* find a behavior across devices and explain it.
- **Lab 5 — ASR audit first, read the events.** Set the demo rules to **audit** as `MDE ASR Lab – Lab Devices – Audit`; hunt the audit events in `DeviceEvents` (pack **Lab 5**). *Check:* read ASR audit results and reason about enforcing a rule.
- **Lab 6 — Live response (read-only only).** With the instructor (holding live response), connect to a lab device and run **only** `processes`, `dir`, `getfile` on a benign file. *Check:* understand how to pull evidence live — and why change commands stay behind approvals.
- **Lab 7 — Response actions: understand and gate.** Walk isolate / restrict / collect-package / stop-and-quarantine / run-AV-scan in the UI **without executing** against production; discuss the approval each needs and how to reverse it. *Check:* describe the right action for a scenario and its approval.
- **Lab 8 — From hunt to detection (alert-only).** Open your tuned Lab 4 query → **Create detection rule**; name it `MDE Lab Detection – Team – Pilot`, map device/account entities, set the response to **generate an alert only**. *Check:* the detection exists and is alert-only.

## Step C3 — Validate (capstone + knowledge-check) and operationalize
1. **Capstone:** each learner takes an incident, establishes root cause and scope from the graph + timeline, writes a two-line summary, and names the response action they **would** recommend (not execute).
2. **Knowledge-check:** run `MDEFULL-Validate.ps1 -Check Enablement` — it walks the Testing gates (readiness, lab queries resolve, `MDE ASR Lab – Lab Devices – Audit` is audit-only, live response used read-only, `MDE Lab Detection – Team – Pilot` is alert-only) and reports a score against `MDE Knowledge Check – Team – Pilot`.
3. **Cohort report:** `MDEFULL-Report.ps1 -Section Enablement`.
4. **Operationalize deliberately:** move tuned queries from `MDE Hunt Library – Team – Pilot` into the team's standing library; advance clean lab ASR rules to block **as an operations decision** (staged, with rollback — feed this back to Part B); promote `MDE Lab Detection – Team – Pilot` to production only if it proves quiet and accurate; use live-response change commands only through the SOC's approvals. Feed tuned hunts to the **Advanced KQL Threat Hunting** program.

---

# Part D — Prove (guided proof-of-concept)

> Enable MDE on a **pilot ring of test devices only**, generate **benign** signal, validate/score, then **tear down**. All test signal is EICAR or a Microsoft built-in simulation — **never real malware or attacks**. Keep **AIR approval-gated** throughout. Nothing production is changed. `MDEFULL-PoC.ps1` runs the whole cycle via `-Action Enable|TestSignal|Score|Teardown`, each `-WhatIf`-gated where it changes anything.

## Step D1 — Assess readiness (read-only)
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MDEFULL-PoC.ps1 -Action Enable -WhatIf` — it previews (changes nothing): the licensed MDE plan, admin roles, whether MDE is already activated, the onboarding channel, and whether `MDE PoC – Pilot Ring – Pilot` exists.
3. In **Entra → Groups**, create `MDE PoC – Pilot Ring – Pilot` and add one to three **test** devices only.

## Step D2 — Enable MDE on the pilot ring
1. `security.microsoft.com` → **Settings → Endpoints → Onboarding**. If MDE is not yet initialized, complete the one-time activation (first time only).
2. `intune.microsoft.com` → **Endpoint security → Microsoft Defender for Endpoint** — confirm **Connection status: Enabled**.
3. **Endpoint security → Endpoint detection and response → Create Policy** (Windows). Name it `MDE PoC EDR Onboarding – Pilot Ring – Pilot`; set **client configuration package type = Auto from connector**; assign **only** to `MDE PoC – Pilot Ring – Pilot`.
4. Alternatively run `MDEFULL-PoC.ps1 -Action Enable` (without `-WhatIf`) to assign the EDR policy to the pilot ring — it is `-WhatIf`-gated and shows exactly what it will do first.
5. Confirm onboarding in **Assets → Devices**. In **Settings → Endpoints → Advanced features**, confirm **Automated Investigation** is on and set the pilot group's **automation level** to **Semi — require approval**.

## Step D3 — Generate benign test signal
1. Run `MDEFULL-PoC.ps1 -Action TestSignal` from an onboarded pilot device (or follow its printed manual steps). It performs only **benign, documented** actions tagged `MDE-PoC-TESTSIGNAL`:
   - Drops the **EICAR** anti-malware test file (the standard harmless string) to trigger Microsoft Defender Antivirus.
   - Prints the exact portal path to launch a **Microsoft built-in EDR simulation**: `security.microsoft.com` → **Endpoints → Evaluation & tutorials → Tutorials & simulations** → run a documented scenario against the pilot device. *These simulations are provided by Microsoft for safe evaluation — verify the current catalogue.*
2. **Do not** download real malware, run exploit tools, or disable any control. EICAR and the built-in simulations are sufficient and safe.
3. Note the time you generated each signal — you will compare against detection time in the scorecard.

## Step D4 — Validate, demonstrate, and score
1. Run `MDEFULL-Validate.ps1 -Check PoC` — it confirms (read-only) the benign signal produced an **alert**, a **device timeline** entry, rows in advanced hunting (`DeviceEvents`, `AlertInfo`, `AlertEvidence`), and that an **automated investigation** started (kept approval-gated).
2. In the portal, walk the demo: open the incident → **alert story** → **device page → Timeline** → **Automated investigations** → an **Advanced hunting** query on the pilot device. Confirm AIR did **not** auto-act (Semi — require approval).
3. Run `MDEFULL-PoC.ps1 -Action Score -CriteriaPath .\criteria.json` — it maps each observation (detection fired, latency, timeline present, hunting visible, AIR started) to your agreed criteria and writes `MDE PoC Scorecard – Pilot Ring – Validate`. Review it with stakeholders — this is the decision artefact.

## Step D5 — Tear down (clean rollback) and decide
1. Run `MDEFULL-PoC.ps1 -Action Teardown -WhatIf` first to preview every removal, then for real: **offboard** the pilot devices (**Settings → Endpoints → Offboarding**, or the Intune offboarding policy), **remove** `MDE PoC EDR Onboarding – Pilot Ring – Pilot`, **delete** the EICAR file, and **resolve** the `MDE-PoC-TESTSIGNAL` test alerts.
2. Optionally delete the pilot group; keep the scorecard file as your record.
3. If the PoC passed and you choose to proceed, move to **Part A** for a real production onboarding — do **not** scale from the PoC ring. If not proceeding, confirm teardown with `MDEFULL-Validate.ps1 -Check PoC` (it should report nothing left onboarded).

---
### Order of operations
`[Deploy] Assess → onboard pilot ring (Win/macOS/Linux) → NGAV + EDR block mode → ASR audit → block → tamper + web filtering → device groups + RBAC → live response + AIR approval-gated → validate coverage + detections + TVM → expand` → `[Optimize] baseline (before) → ASR audit→block on evidence → tune noise/FPs → expand coverage + tags → harden → validate before/after → expand ring by ring` → `[Enable] prepare cohort → guided Labs 1–8 → capstone + knowledge-check → operationalize` → `[Prove] assess (-WhatIf) → enable pilot ring → benign EICAR/simulation signal → validate + demo → score → teardown (-WhatIf then real) → decide`
