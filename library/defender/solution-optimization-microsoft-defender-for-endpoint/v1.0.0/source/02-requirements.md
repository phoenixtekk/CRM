# 2. Requirements Guide — Solution Optimization: Microsoft Defender for Endpoint

Verify **every** requirement before tuning. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to optimizing an existing Defender for Endpoint deployment**. Because this is a **tuning** engagement, the defining prerequisite is that MDE is **already deployed and reporting** — not a green field. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 An existing, working Defender for Endpoint deployment
**Description:** Defender for Endpoint is already **onboarded** with devices reporting to `security.microsoft.com`, not a new deployment.
**Why:** This solution *tunes* an existing deployment; there must be devices, alerts, and (ideally) ASR audit history to optimize.
**Verify:** `security.microsoft.com` → **Assets → Devices** shows onboarded devices with **sensor health = Active**; run `SOPMDE-Discovery.ps1`.
**Implement-if-missing:** If MDE is not deployed, stop — onboard it first (see the XDR unified-onboarding solution), then return to optimize.

## 2.2 A defined pilot device ring
**Description:** A named group of representative pilot devices to tune first: device group **`MDE Optimize – Pilot Ring – Pilot`** (and, where policy lives in Intune, an Entra group of the same name).
**Why:** ASR block, hardened policy, and suppressions are validated on a ring before estate-wide rollout (per `global-requirements-defender.md` G6).
**Verify:** The device group/Entra group exists and contains a representative sample (one of each OS/build/role); `SOPMDE-Discovery.ps1` lists device groups.
**Implement-if-missing:** Create the pilot group in **Settings → Endpoints → Device groups** (and/or an Entra group) before applying any change.

## 2.3 ASR rules with audit history
**Description:** ASR rules that have run in **Audit** long enough to produce representative data on your software estate.
**Why:** Moving a rule to **Block** safely depends on knowing what it *would* have blocked — that is exactly what audit data shows. Blocking without audit data risks breaking a line-of-business app.
**Verify:** `security.microsoft.com` → **Reports → Attack surface reduction rules → Audit** shows audited events, or run `SOPMDE-Hunt.ps1 -Mode ASRAudit`. *Rule availability varies by platform/plan — verify current.*
**Implement-if-missing:** Set the target rules to **Audit** first (Implementation Step 2), let them soak, then reassess before switching to Block.

## 2.4 Rights to change ASR, EDR, AV, and tamper policy
**Description:** **Security Administrator** in the Defender portal, plus **Endpoint Security Manager** (or equivalent) in Intune where the endpoint-security policies live; **Security Reader** for read-only reporting accounts.
**Why:** Changing ASR/EDR/AV/tamper policy and creating suppressions/indicators requires write access; reporting only needs read.
**Verify:** Entra → **Roles and administrators**; Intune → **Tenant admin → Roles**; `SOPMDE-Discovery.ps1` reports the running account's effective scopes.
**Implement-if-missing:** Assign the minimum roles at the narrowest scope; prefer PIM eligible activation over standing access.

## 2.5 Where policy is authored (Intune vs Defender vs GPO/CM)
**Description:** A clear answer to **where** ASR/EDR/AV/tamper policy is currently authored — Intune Endpoint security, the Defender portal's configuration management, Group Policy, or Configuration Manager.
**Why:** You must change policy in the **authoritative** location; editing the wrong surface silently loses to the one that actually applies, or creates a conflict.
**Verify:** `security.microsoft.com` → **Configuration management → Endpoint security policies**, and Intune → **Endpoint security**; confirm which owns the target devices. `SOPMDE-Discovery.ps1` reports Intune endpoint-security policies.
**Implement-if-missing:** Decide the single authoritative surface (Intune is recommended for cloud-managed devices) and migrate GPO/CM settings there before tuning, to avoid split-brain policy.

## 2.6 A captured before-state baseline
**Description:** A saved snapshot of the **current** alert volume, false-positive proportion, ASR block coverage, and onboarding/sensor-health coverage — the "before" for before/after measurement.
**Why:** Optimization is only credible if the improvement is **measured**; the baseline is the reference every later report compares against.
**Verify:** A baseline file exists; run `SOPMDE-Report.ps1 -SaveBaseline`.
**Implement-if-missing:** Run `SOPMDE-Report.ps1 -SaveBaseline` before making any change (Implementation Step 1).

## 2.7 Change control, pilot scope, and rollback
**Description:** An approved change record, the named pilot ring, and a documented rollback before switching any ASR rule to block or tightening any policy.
**Why:** ASR block and hardened policy can affect real applications; the pilot-first, audit/`-WhatIf`-first approach and a written back-out are the safety net.
**Verify:** An approved change record, the pilot scope, and a written rollback (revert the ASR rule to audit / re-scope the policy) exist.
**Implement-if-missing:** Capture the baseline (2.6), define the pilot ring (2.2), and write the rollback before Step 2.

## 2.8 Response governance (approval-gated)
**Description:** Confirmation that automated **response** actions (isolate device, restrict app execution, run AV scan) remain **approval-gated** during and after tuning.
**Why:** Reducing noise must not silently loosen response guardrails; disruptive actions stay human-approved until trusted (per `global-requirements-defender.md` G8).
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Advanced features / Automation levels**; confirm the agreed automation posture.
**Implement-if-missing:** Set/confirm the automation level with the SOC. *Incident-response decisions are the security team's; this guide covers the technical configuration.*

---
## Checklist
- [ ] Existing, reporting MDE deployment — `SOPMDE-Discovery.ps1`
- [ ] Pilot device ring `MDE Optimize – Pilot Ring – Pilot` defined
- [ ] ASR rules have audit history — `SOPMDE-Hunt.ps1 -Mode ASRAudit`
- [ ] Security Admin (+ Intune Endpoint Security Manager) and Security Reader roles
- [ ] Authoritative policy surface identified (Intune / Defender / GPO / CM)
- [ ] Before-state baseline saved — `SOPMDE-Report.ps1 -SaveBaseline`
- [ ] Change window, pilot scope, and rollback documented
- [ ] Automated response confirmed approval-gated
