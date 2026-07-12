# 7. Best Practices — Microsoft Defender for Endpoint

Field-proven guidance for keeping the Defender for Endpoint lifecycle protective, operable, measurable, and low-risk — across all four workstreams.

## Deploy in rings, never all at once
- Onboard `MDE Device Group – Pilot Ring – Pilot` first — a representative Windows/macOS/Linux mix — validate, then expand in waves. Sequencing catches platform-specific issues before they hit the fleet.
- Onboard **every** platform in scope; a Linux or macOS fleet left un-onboarded is a blind spot.

## Bring ASR and block mode up audit-first — and earn every block with evidence
- Always run **ASR** in `MDE ASR Rules – Pilot Ring – Audit` first, review what it *would* block (`MDEFULL-Report.ps1 -Section ASR` / `MDEFULL-Hunt.ps1 -Mode ASRAudit`), add exclusions for legitimate line-of-business behavior, then promote to `MDE ASR Rules – Pilot Ring – Block`. Never flip a rule straight to block.
- Preview every flip with `MDEFULL-PromoteASR.ps1` (`-WhatIf` default) before applying, and promote ring-by-ring, validating each ring clean before the next.
- Fix a single blocked app with a **scoped exclusion**, not by disabling the whole rule. Whether an app is business-critical is the app owner's call.

## Enforce tamper protection early, and harden without a split brain
- Turn on **tamper protection** so an attacker (or misconfiguration) cannot disable the protection stack — one of the highest-value, lowest-friction controls. Keep **EDR in block mode** on.
- Author ASR/EDR/AV/tamper policy in **one** authoritative surface (Intune recommended for cloud-managed devices). Editing GPO and Intune for the same setting creates conflicts that silently win in ways you didn't intend.

## Structure device groups, tags, and RBAC deliberately
- Use **device groups** to scope AIR automation levels and analyst access; keep the pilot at **Semi — require approval**. Grant least privilege via `MDE Security Reader – Tenant – Prod` and `MDE Security Operator – Tenant – Prod` — only responders get response permissions.
- Standardize **device tags and groups** so policy, RBAC, and reporting target the right machines — inconsistent tagging is why "we thought it was covered" incidents happen.
- **Live response** is powerful (remote shell) — restrict who can run it and gate it per policy.

## Measure everything you optimize
- Capture the **before** state (`MDEFULL-Report.ps1 -SaveBaseline`) before you touch anything; optimization you cannot measure is just change. Re-baseline after each wave so the trend reflects real scope growth.
- Work **TVM exposure as a trend** — triage the highest-impact vulnerabilities first and track the delta each cycle.

## Tune noise with a scalpel, not a chainsaw
- Prefer a **precise indicator** or a tightly scoped **suppression** over a broad AV exclusion — exclusions are blind spots an attacker can hide in.
- Every suppression/indicator is **named, justified, and time-bound** (`MDE FP Suppression – <detection> – Prod`). Review them on a cadence so they don't become permanent gaps. The goal is a queue where a remaining alert **means something** — not zero alerts.

## Enable the team as a program, not a one-off class
- **Investigate, don't just triage:** before closing an alert, walk the **incident graph** and **alert story** and open the **device timeline** to establish root cause and blast radius. Re-hunt every new indicator across all devices, not just the one that alerted.
- **Read-only live response by default** (`processes`, `dir`, `fileinfo`, `getfile`); reserve change commands for real incidents under the SOC's approvals — never as a lab reflex. Match the response action to the scenario and know how to reverse it.
- **Alert-only first** for detections: promote a hunt to `MDE Lab Detection – Team – Pilot` only once it is quiet and accurate. A noisy detection trains the team to ignore alerts. Version your endpoint KQL library in source control.
- Schedule recurring investigation drills, rotate who leads the hunt of the week, and re-run the take-home runbook + knowledge-check for new hires.

## Prove value safely and reversibly
- Onboard **test devices only** into `MDE PoC – Pilot Ring – Pilot`; never point a PoC at production endpoints. Preview every change with `-WhatIf` first.
- Use **EICAR** and Microsoft's **built-in evaluation simulations** exclusively — enough to prove the detection pipeline. Do **not** download live malware or run exploit frameworks; adversary emulation belongs in a separate, governed engagement.
- Agree the **evaluation criteria in writing first**; a PoC that defines "pass" afterwards proves nothing. Allow warm-up before judging a "fail," then **tear down completely** and confirm nothing is left onboarded.

## Keep automated response approval-gated until trusted
- Leave **AIR** at **Semi — require approval** during deployment, tuning, labs, and the PoC. Raising automation is the SOC/security team's decision, made only after coverage and detections are proven (per `global-requirements-defender.md` G8).

## Keep licensing and preview facts current
- MDE **P1/P2**, MDVM add-ons, web content filtering, advanced hunting, live response, custom detections, and device-tagging behavior are plan-gated, and Microsoft's simulation catalogue and ASR rule GUIDs change. **Verify current plan requirements and availability in your tenant** before relying on a capability.

## Defer the security decisions to the owners
- Which detections are **true incidents**, whether a **suppression or residual risk** is acceptable, which web categories to block, which ASR rules to enforce in production, whether the PoC "passed," and every production response are the **SOC/security team's** determinations. This solution delivers the controls, the skills, and the before/after evidence — not the incident-response or risk decision.

## Where to go next
Once MDE is deployed, tuned, team-ready, and proven, the natural next steps in the catalog:
- The **Defender for Endpoint Integration** solution for deeper Intune-connector configuration, and the **macOS Onboarding via Intune** solution for a macOS-specific rollout — cross-reference rather than re-do.
- The **Microsoft Defender XDR — Unified Onboarding** solution to correlate MDE with Identity, Office 365, and Cloud Apps in one incident view.
- The **SOC onboarding — Sentinel + Defender XDR** solution to stream MDE into a SIEM for long-term hunting and SOAR.
- The **Advanced KQL Threat Hunting** solution to adopt and operate a curated, maintained hunt program built on the endpoint hunting skill this solution gives you.
- The **Microsoft Defender for Cloud Apps** — MDE's discovery feed powers Cloud Discovery.
