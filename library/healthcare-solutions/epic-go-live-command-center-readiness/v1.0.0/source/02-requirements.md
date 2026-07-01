# 2. Requirements — Epic Go-Live & Command Center Endpoint Readiness Playbook

This section defines the solution-specific requirements for getting the clinical endpoint fleet ready for an Epic go-live and running the command center through hypercare. **Category-wide prerequisites** (tenant, roles, licensing, HIPAA/HITRUST data handling and change control, maintenance windows, network, test device, rollback) are defined once in **`global-requirements-healthcare-solutions.md`** — read that document first; the requirements below assume it.

Each requirement follows the same four-part structure:

- **Description** — what the requirement is.
- **Why** — why it matters for an Epic activation.
- **Verify** — how to confirm it is already in place.
- **Implement if missing** — what to do when it is not.

Never assume any requirement is already satisfied — verify each one.

---

## R1 — Authoritative in-scope device inventory

**Description.** A single authoritative list of every clinical endpoint that must be ready for the activation — clinical workstations, WOWs (workstations-on-wheels), exam-room PCs, shared/kiosk devices, and the clinical peripherals attached to them — scoped to the go-live's units, floors, departments, or facility.

**Why.** Readiness is meaningless without a denominator. The go/no-go gate reports "X of Y devices PASS"; if Y is wrong, the recommendation is wrong. Devices that exist on the floor but not in inventory are exactly the ones that fail on day 1 because nobody prepared them.

**Verify.** In **Microsoft Intune admin center > Devices > All devices**, filter to the activation's scope and reconcile the count against the Epic program's location/asset list and the network/DHCP view of what is actually on those floors. Run `EPICGOLIVE-Discovery.ps1` to produce a fleet snapshot and compare its device count to the expected count.

**Implement if missing.** Build the inventory by reconciling Intune/Entra device records, the asset-management/CMDB list, and a physical floor walk of the activation area. Tag in-scope devices so they can be grouped (see R10). Resolve every discrepancy (in Intune but not on the floor, on the floor but not in Intune) before validation begins.

---

## R2 — Defined, measurable device readiness standard

**Description.** A written readiness standard — the **Endpoint Readiness Checklist – Clinical Fleet – Pre-Go-Live** — that states, for each device class, the exact conditions a device must meet to be "ready": required Epic client version, required peripherals, Imprivata tap functional, maximum acceptable login time, and required compliance/enrollment state.

**Why.** "Ready" must be objective and the same for everyone, or the validation sweep produces inconsistent results and the go/no-go gate cannot be defended. A measurable standard is also what makes the PowerShell validation possible — a script can only test a concrete threshold.

**Verify.** Confirm a current readiness checklist exists, is approved by the Epic program / Epic technical services (TS), and names concrete values (e.g., the exact target Epic client version string, the login-time target in seconds, the required compliance policy). Confirm each in-scope device class maps to a checklist profile.

**Implement if missing.** Author the checklist with the Epic program and Epic TS supplying the environment-specific values (client version, print pathways, login-time target). Use the artifact name above verbatim. Have it formally approved before it gates anything.

---

## R3 — Correct Epic client version present on every device

**Description.** Every in-scope device runs the **exact** Epic client version (Hyperdrive/Hyperspace) the Epic program has designated for this go-live — no older build, no unexpected newer build.

**Why.** A version mismatch is one of the most common day-1 blockers: the client refuses to connect, prompts for an unwanted upgrade, or behaves differently than staff were trained on. Version drift across the fleet also makes triage unpredictable.

**Verify.** Run `EPICGOLIVE-Discovery.ps1` / `EPICGOLIVE-Validation.ps1` to read the installed Epic client version from each device and compare to the designated version from the readiness checklist (R2). In Intune, check **Apps > Monitor** for the deployment status of the Epic client app.

**Implement if missing.** Deploy or update the designated client version via the Epic client deployment solution (referenced — deep packaging/ring config lives there). Re-run discovery to confirm the version is correct fleet-wide. Do not hand-patch individual devices outside the managed deployment.

---

## R4 — Functional clinical printing

**Description.** Every device can print to the printers its workflow needs — label/wristband printers, document printers, and any specialty printers (e.g., prescription, MAR) — through the print pathway the Epic environment uses.

**Why.** Printing failures (wristbands, labels, scripts) are a top day-1 ticket category and directly affect patient safety and throughput. A device that logs in fine but can't print a wristband is not ready.

**Verify.** Confirm printers are mapped/available on each device and that a test print succeeds through the intended pathway. Validate that print configuration is delivered consistently (e.g., via the print management method the environment uses) rather than manually per device.

**Implement if missing.** Map the required printers and confirm drivers/pathway are correct; coordinate with the print-server / Epic print team for the print-routing configuration. Document the print pathway in the readiness checklist so the triage runbook can reference it.

---

## R5 — Attached peripherals present and working

**Description.** Every required clinical peripheral — barcode/label scanners, badge readers, signature pads, document scanners, card swipes — is physically attached, recognized by the OS, and functional on the device.

**Why.** Clinical workflows (medication administration, patient ID, document capture) depend on peripherals. A missing or non-functional scanner stops the workflow cold at the bedside.

**Verify.** Run `EPICGOLIVE-Validation.ps1` to check that expected peripherals enumerate on each device, and confirm a functional test (scan a barcode, tap a badge, sign on the pad) during the validation sweep. Cross-check the expected peripheral set per device class against the readiness checklist.

**Implement if missing.** Attach/replace missing or faulty peripherals, install/confirm drivers, and re-test. Where a peripheral is delivered by policy/driver package, confirm the package is applied. Record each device's expected peripheral set so validation knows what "complete" means.

---

## R6 — Imprivata tap-and-go (SSO) functional

**Description.** Imprivata tap-and-go single sign-on works on every device that uses it: badge tap authenticates, fast user switching / proximity workflows behave as configured, and the Imprivata agent is healthy.

**Why.** Tap-and-go is how clinicians log in dozens of times a shift. If the tap fails, staff fall back to manual credentials, login times spike, and the floor slows to a crawl — the single most felt endpoint failure at go-live.

**Verify.** Confirm the Imprivata agent is installed and reporting healthy on each device, and perform a badge-tap test during the validation sweep. Check the readiness checklist for which device classes require tap-and-go.

**Implement if missing.** Install/repair the Imprivata agent and confirm enrollment/policy (deep OneSign config lives in the referenced Imprivata solution). Re-test the tap. Ensure a documented manual-login fallback exists for the triage runbook.

---

## R7 — Login time within target

**Description.** The time from badge tap / credential entry to a usable Epic session is at or below the maximum defined in the readiness checklist (R2) for each device class.

**Why.** Slow logins are a leading source of clinician frustration and lost productivity at go-live and a frequent disguised symptom of deeper problems (profile bloat, GPO/login-script delays, resource contention). A measured target turns "it feels slow" into a pass/fail.

**Verify.** Measure login time on representative devices per class during validation; capture the metric in the readiness scorecard. Compare to the checklist target.

**Implement if missing.** Investigate and remediate the dominant contributor (roaming profile size, startup apps, login scripts, GPO processing, antivirus on-access scope, disk/RAM on the device). Re-measure until within target. Persistent outliers are flagged in the scorecard and weighed at the go/no-go gate.

---

## R8 — Devices enrolled and compliant

**Description.** Every in-scope device is enrolled in Microsoft Intune, is the expected managed identity in Microsoft Entra, and is **compliant** with the assigned compliance policy (encryption, OS build, security baseline, etc.).

**Why.** A not-enrolled or non-compliant device may be blocked by Conditional Access from reaching Epic or its dependencies, may lack the management channel needed to push fixes, and is invisible to the readiness tooling. "Not enrolled" is a classic day-1 surprise.

**Verify.** Run `EPICGOLIVE-Discovery.ps1` to list enrollment and compliance state per device from Intune/Entra via Graph. In Intune, review **Devices > Compliance** and **Devices > Conditional access** impact for the in-scope group.

**Implement if missing.** Enroll missing devices and remediate compliance failures (the cause is reported per device). Use `EPICGOLIVE-Remediation.ps1` (read-only / `-WhatIf` by default; `-Apply` to act) for the safe, supported remediation actions. Re-run discovery until the in-scope group is fully enrolled and compliant.

---

## R9 — Command-center operating model defined

**Description.** A defined command-center structure before go-live: the **Command Center Roster – Endpoint Support – Hypercare** (roles, support tiers, dispatch model, at-the-elbow assignments, on-call coverage), the **Rapid-Fix Triage Runbook – Day-1 Endpoint – Hypercare**, and the **Comms & Escalation Plan – Endpoint Domain – Activation**.

**Why.** A command center improvised on day 1 cannot keep up with a live clinical floor. Defined roles, a dispatch model, and a triage runbook are what let the team resolve high-volume issues in minutes and escalate the rest cleanly.

**Verify.** Confirm the roster, triage runbook, and comms/escalation plan exist, name real people/roles for the activation window, and have been walked through with the command-center and at-the-elbow staff. Confirm a ticketing/dispatch channel is ready.

**Implement if missing.** Build the three artifacts (templates and structure are in `03-implementation.md`), staff them for the activation window including off-hours, and dry-run the dispatch and escalation paths before go-live.

---

## R10 — Readiness device group for targeting

**Description.** A managed device group — the **Readiness Device Group – Clinical Fleet – Validation** — in Intune/Entra that contains exactly the in-scope devices, so the validation sweep, remediation, and any deployments target the right set and nothing else.

**Why.** Targeting by group keeps validation, remediation, and reporting scoped to the activation. A wrong or stale group either misses devices (false readiness) or sweeps unrelated production devices (noise and risk).

**Verify.** Confirm the group exists in **Microsoft Entra admin center > Groups** (or **Intune > Groups**), that its membership matches the R1 inventory, and that its name matches the artifact name verbatim. Run `EPICGOLIVE-Set-ReadinessGroup.ps1 -WhatIf` to preview the intended membership against current.

**Implement if missing.** Create the group and populate it from the R1 inventory (dynamic membership rule on the in-scope tag/attribute, or assigned membership for a fixed list). Use `EPICGOLIVE-Set-ReadinessGroup.ps1` (preview with `-WhatIf` first) to manage membership. Keep it in sync as devices are added/removed during prep.

---

## R11 — Go/no-go gate and decision authority

**Description.** A defined **Go/No-Go Gate – Endpoint Domain – Activation** checklist and a named decision authority (typically the Epic program lead, advised by the endpoint lead) who accepts the endpoint domain's go/no-go recommendation.

**Why.** Validation produces data; someone must turn data into a decision and own it. Without a defined gate and authority, readiness debates happen ad hoc at the worst time, and conditional-go conditions go untracked.

**Verify.** Confirm the gate checklist exists, defines the PASS thresholds (e.g., minimum percent of in-scope devices at PASS, zero unresolved safety-critical failures), and names the decision authority and the meeting/time at which the gate is walked.

**Implement if missing.** Author the gate with explicit thresholds tied to the readiness scorecard, identify the decision authority, and schedule the go/no-go review inside the activation timeline. Define how conditional-go items are tracked into hypercare.

---

## R12 — Hypercare exit criteria defined

**Description.** A defined **Hypercare Exit Criteria – Endpoint Domain – Handover** — the measurable conditions under which the command center retires and ownership moves to steady-state service desk (e.g., endpoint ticket volume below a threshold for N consecutive days, no open safety-critical endpoint issues, knowledge transferred).

**Why.** Without exit criteria, hypercare either ends arbitrarily (leaving the service desk unprepared) or never ends (burning out the command-center team). Clear criteria make the handover a decision, not a default.

**Verify.** Confirm exit criteria exist, are measurable, and are agreed with service-desk leadership who will inherit ownership.

**Implement if missing.** Define the criteria with command-center and service-desk leadership, tie them to the same metrics the command center already tracks, and document the handover package contents (open items, known issues, updated runbook). See `03-implementation.md` Phase 5.
