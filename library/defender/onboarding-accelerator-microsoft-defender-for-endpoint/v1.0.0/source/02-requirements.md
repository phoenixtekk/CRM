# 2. Requirements Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to onboarding Defender for Endpoint end to end**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Endpoint activated
**Description:** MDE initialized for the tenant under `security.microsoft.com` → **Settings → Endpoints**.
**Why:** Onboarding packages, ASR/AV policy, device groups, and RBAC only appear after first-time activation.
**Verify:** Sign in as a Security Administrator and confirm **Settings → Endpoints → Onboarding** loads. Run `MDEONB-Discovery.ps1`.
**Implement-if-missing:** Complete the one-time MDE activation (Global Administrator required for first-service activation only).

## 2.2 Onboarding channel per platform
**Description:** A working onboarding channel for each platform in scope — **Intune** (default for Windows/macOS), **Group Policy / local script** for Windows, the **macOS** MDM profile + package, and the **Linux** repo + package.
**Why:** MDE collects EDR signal only from onboarded devices; each platform onboards through its own channel.
**Verify:** `MDEONB-Discovery.ps1` reports the platform mix and current onboarding coverage; confirm the Intune MDE connector is **Enabled**. 
**Implement-if-missing:** Establish the channel per platform — *cross-reference the catalog's "Defender for Endpoint Integration" (Intune connector) and "Defender for Endpoint macOS Onboarding via Intune" solutions* — and target the pilot ring first.

## 2.3 Pilot device ring defined
**Description:** A named pilot device group `MDE Device Group – Pilot Ring – Pilot` (Entra/Intune) covering a representative mix of Windows/macOS/Linux.
**Why:** Onboarding and the disruptive controls (ASR, block mode) are validated on a ring before the fleet (per `global-requirements-defender.md` G6).
**Verify:** The group exists; `MDEONB-Validate.ps1 -Check Onboarding` checks membership/coverage. 
**Implement-if-missing:** Create `MDE Device Group – Pilot Ring – Pilot` before onboarding anything that enforces.

## 2.4 EDR / next-gen AV baseline decision
**Description:** A decision on **EDR in block mode** and the antivirus posture (Defender AV primary, or third-party AV with EDR block mode).
**Why:** Block mode is what lets EDR block artifacts behind a non-Microsoft AV; the posture must be agreed.
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Advanced features → EDR in block mode**; `MDEONB-Validate.ps1 -Check EDR` reports it. 
**Implement-if-missing:** Decide the AV posture and plan to enable EDR in block mode after pilot onboarding.

## 2.5 ASR rollout scope (audit-first)
**Description:** The **attack surface reduction** rules to deploy and the plan to run them **audit → block** on the ring.
**Why:** ASR rules can break line-of-business apps if enforced blind; audit-first surfaces the impact.
**Verify:** `MDEONB-Validate.ps1 -Check ASR` reports current ASR rule states; a rule list and exclusions are drafted. 
**Implement-if-missing:** Draft the ASR rule set and exclusions, create the policy `MDE ASR Rules – Pilot Ring – Audit`, and only later promote to `MDE ASR Rules – Pilot Ring – Block`.

## 2.6 Tamper protection and web content filtering scope
**Description:** Intent to enforce **tamper protection** tenant-wide and to configure **web content filtering** categories (P2). 
**Why:** Tamper protection stops the stack being disabled; web content filtering adds endpoint web control. *Web content filtering requires P2 — verify current availability.*
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Advanced features** (tamper protection) and **Web content filtering**; `MDEONB-Validate.ps1 -Check Config` reports both. 
**Implement-if-missing:** Plan tamper protection enforcement and draft the web content filtering categories/policy.

## 2.7 Device groups, RBAC, and live response controls
**Description:** The **device group** structure (with per-group AIR automation levels), the **RBAC** role model (reader / operator), and **live response** approval controls.
**Why:** Device groups drive automation scope; RBAC scopes analyst permissions; live response is powerful and must be gated.
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Permissions** (Roles, Device groups) and **Advanced features → Live Response**; `MDEONB-Validate.ps1 -Check RBAC` reports them. 
**Implement-if-missing:** Plan `MDE Device Group – Pilot Ring – Pilot`, roles `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod`, and live-response approval settings (Step 7).

## 2.8 Response governance
**Description:** An agreed position on **automated investigation and response (AIR)** automation levels, kept approval-gated during the pilot.
**Why:** AIR can isolate devices and remediate files; the organization decides the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented response policy exists; the pilot group's automation level is approval-gated. `MDEONB-Report.ps1` reports it. 
**Implement-if-missing:** Keep AIR approval-gated at first; *incident-response and automation guardrail decisions are the SOC/security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] MDE activated — `MDEONB-Discovery.ps1`
- [ ] Onboarding channel per platform (Intune/GPO/script/macOS/Linux)
- [ ] Pilot device ring `MDE Device Group – Pilot Ring – Pilot` defined
- [ ] EDR block mode / AV posture decided
- [ ] ASR rollout scope (audit-first) drafted — `MDE ASR Rules – Pilot Ring – Audit`
- [ ] Tamper protection + web content filtering scope planned
- [ ] Device groups, RBAC, live-response controls planned
- [ ] Response governance (AIR approval-gated) documented
