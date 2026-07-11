# Proof-of-Concept Kit — Microsoft Defender for Office 365

> **Version 1.0.0** · Category: Defender · Solution code: POCMDO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Proof-of-Concept Kit: Microsoft Defender for Office 365

**White-label · Defender**

Deciding on Microsoft Defender for Office 365 (MDO) shouldn't rest on a slide deck. This Proof-of-Concept (PoC) Kit stands up a **scoped, safe** proof of concept in your own tenant: it enables MDO protection on a small group of **pilot users**, generates **benign, simulated** test signal (Microsoft's own **Attack Simulation Training**, the standard **GTUBE** spam-test string, the **EICAR** attachment test file, and a benign **Safe Links** test URL — never real phishing or malware), demonstrates the headline **email & collaboration security** capabilities on that signal, scores the result against your evaluation criteria, and then **cleanly tears the PoC back down**.

The kit is written for an administrator with no prior Defender experience. Everything is **pilot-scoped and reversible**: you protect a handful of test mailboxes, prove the value, capture a scorecard, and roll the scope back — with the wider organisation's mail flow unchanged.

## What you get
- A plain-language **Solution Overview** of MDO and how a PoC proves it on real-but-safe signal.
- A **Requirements Guide** of the PoC-specific prerequisites (the category-wide ones live in `global-requirements-defender.md`).
- An **Implementation Guide** — exact, ordered steps to scope MDO to pilot users, generate benign signal, demonstrate the detections, score, and tear down.
- Five **PowerShell scripts** (Exchange Online Management + Microsoft Graph Security) with **KQL advanced-hunting** queries: a `-WhatIf`-gated pilot enable, a **benign** test-signal helper, a demo/validate check, a criteria scorecard, and a `-WhatIf`-gated teardown.
- **Testing**, **Troubleshooting**, and **Best Practices** guides.

## What this delivers
A concrete, **in-tenant proof** that Microsoft Defender for Office 365 delivers email & collaboration security — a benign phishing simulation and test messages reaching pilot users, **Safe Links** rewriting URLs, **Safe Attachments** detonating the test attachment, **anti-spam/anti-phish** and **zero-hour auto purge (ZAP)** acting, the activity visible in **Threat Explorer** and advanced hunting, and a **scorecard** mapping each observed capability to your pass/fail criteria — all rolled back cleanly at the end.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — here scoped as a PoC: assess readiness, scope MDO to pilot users, generate benign signal, validate and score, then either expand or tear down.

## Boundary
This is an **evaluation kit**, not a production rollout. It proves MDO on pilot users and then rolls the scope back. Organisation-wide policy hardening, mail-flow migration, and long-term operations are separate adjacent solutions (see *Where to go next*). All test signal is **benign and simulated**. Remediation actions are kept **reviewable**; incident-response and policy-hardening decisions remain the customer's security team's.

## Effort
A competent administrator can complete the full PoC — scope, signal, validate, score, and teardown — in a short, focused engagement on a few pilot mailboxes. No organisation-wide mail-flow change is required, and every step is reversible. **Attack Simulation Training and Threat Explorer require a Defender for Office 365 P2 plan — verify current availability in your tenant.**


---


# 1. Solution Overview — Proof-of-Concept Kit: Microsoft Defender for Office 365

## What Microsoft Defender for Office 365 is
Microsoft Defender for Office 365 (MDO) is Microsoft's **email and collaboration security** platform, layered on top of Exchange Online Protection (EOP) and managed from the unified Defender portal at `security.microsoft.com`. Its headline capabilities are:

- **Safe Links** — time-of-click URL protection that rewrites and detonates links in mail and (where licensed) Teams/Office.
- **Safe Attachments** — sandbox detonation of attachments before delivery.
- **Anti-phishing** — impersonation and spoof protection (mailbox intelligence, user/domain impersonation).
- **Anti-spam / anti-malware** (EOP baseline) and **zero-hour auto purge (ZAP)** that retroactively removes mail found malicious after delivery.
- **Threat Explorer** and **advanced hunting** for investigation, plus **automated investigation & response (AIR)**. *Threat Explorer, Attack Simulation Training, and AIR require Defender for Office 365 **P2** — verify current availability in your tenant.*

## What a Proof-of-Concept Kit is
A PoC Kit is a **customer-runnable evaluation**, not a production rollout and not a sales demo. Its job is to answer one question — *does MDO actually catch phishing and malicious mail for our users?* — with evidence, safely, in your own tenant. It does that by:

1. **Enabling** MDO protection (a preset security policy) scoped to a small group of **pilot users** only.
2. **Generating benign test signal** — Microsoft's **Attack Simulation Training** (a safe, built-in phishing simulator), the standard **GTUBE** spam-test string, the **EICAR** attachment test file, and a benign **Safe Links** test URL. These are documented, harmless triggers. **No real phishing, malware, or malicious payload is ever used.**
3. **Demonstrating** that the signal produces the expected outcomes — Safe Links rewriting, Safe Attachments detonation, spam/phish handling, ZAP, and visibility in Threat Explorer.
4. **Scoring** what you observed against your evaluation criteria.
5. **Tearing down** — rolling the pilot scope back and clearing test artefacts.

## Why this matters
Email remains the number-one intrusion vector, and a vendor deck can't show you how MDO behaves on *your* mail flow, with *your* users and *your* policy posture. A scoped PoC replaces "trust the deck" with "watch it catch the simulation." Because it is **pilot-scoped and reversible**, the wider organisation's mail flow is untouched, and you get proof without committing to an org-wide policy change before you've seen the value.

## How it works
1. **Assess** readiness with `POCMDO-Enable.ps1 -WhatIf` — MDO plan (P1/P2), admin roles, Exchange Online mail flow, and a defined pilot user group.
2. **Configure & enable** the **Standard preset security policy** scoped **only** to `MDO PoC – Pilot Users – Pilot` (Safe Links, Safe Attachments, anti-phishing).
3. **Generate benign signal** with `POCMDO-TestSignal.ps1` — launch a Microsoft Attack Simulation phishing campaign to the pilot users and send GTUBE / EICAR / Safe Links test messages.
4. **Validate & demonstrate** with `POCMDO-Validate.ps1` — confirm Safe Links rewrote, Safe Attachments detonated, ZAP/quarantine acted, and the events appear in `EmailEvents`, `UrlClickEvents`, and Threat Explorer.
5. **Score** with `POCMDO-Scorecard.ps1` against your criteria.
6. **Tear down** with `POCMDO-Teardown.ps1 -WhatIf` first, then for real — remove the pilot scope, end the simulation, purge test messages from quarantine.

## What you can control
- **Pilot users** — exactly which mailboxes the preset policy protects; the rest of the org is untouched.
- **Which capabilities to prove** — Safe Links, Safe Attachments, anti-phish, ZAP, Threat Explorer, AIR.
- **Simulation content** — Microsoft's built-in benign phishing templates only.
- **Scorecard criteria** — the pass/fail bar you evaluate against.
- **Teardown** — full, reversible scope rollback.

## Limitations (be honest with buyers)
- MDO and several features are **license-gated** — Safe Links/Safe Attachments/anti-phish need **P1**; **Threat Explorer, Attack Simulation Training, and AIR need P2**. *Verify current plan availability in your tenant.*
- Test signal is **benign and simulated only** — Attack Simulation Training, GTUBE, EICAR, a benign test URL. This proves the protection pipeline, not resilience to a real targeted campaign.
- **ZAP and detonation** act after delivery / at click time — allow a short delay before judging.
- This is a **PoC**, not a production rollout — it stays scoped to pilot users and is designed to be rolled back. Org-wide hardening is a separate solution.
- MDO improves email security; it does not replace user training, identity hardening, or the SOC's incident-response decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com`) for preset policies, Threat Explorer, Attack Simulation, quarantine, and Secure Score.
- **Exchange Online Management** PowerShell for preset-policy scoping and quarantine operations.
- **Microsoft Graph Security** and the advanced-hunting API (`EmailEvents`, `UrlClickEvents`, `EmailAttachmentInfo`) for read-only validation and scoring.
- Least-privilege roles: **Security Administrator** (and **Exchange Administrator** for policy scope), **Security Reader** for read-only work, **Attack Simulation Administrator** for the simulation, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness → configure/scope MDO to a pilot user group → generate benign test signal → validate the detections and score → expand or tear down.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, run here as a safe, reversible PoC with remediation kept reviewable.


---


# 2. Requirements Guide — Proof-of-Concept Kit: Microsoft Defender for Office 365

Verify **every** requirement before enabling anything. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running a scoped MDO proof of concept**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Office 365 plan available to activate
**Description:** A licensed **Defender for Office 365 P1 or P2** plan the tenant can apply for the PoC.
**Why:** Safe Links / Safe Attachments / anti-phish need P1; **Threat Explorer, Attack Simulation Training, and AIR need P2** — these are the capabilities being proven.
**Verify:** Admin center → **Billing → Licenses** shows an MDO plan; `security.microsoft.com` → **Email & collaboration → Policies & rules** loads. Run `POCMDO-Enable.ps1 -WhatIf`. *Verify current plan features (P1 vs P2) in your tenant.*
**Implement-if-missing:** Assign the MDO plan (often bundled in M365 E5 / E5 Security). For the simulation and Threat Explorer demos, ensure **P2**.

## 2.2 Exchange Online mail flow
**Description:** The tenant routes mail through **Exchange Online** for the pilot mailboxes.
**Why:** MDO policies apply to Exchange Online mail; without it there is nothing to protect and no signal to generate.
**Verify:** `security.microsoft.com` → **Email & collaboration → Policies & rules**; confirm mail routes through Exchange Online; `POCMDO-Enable.ps1 -WhatIf` reports mail-flow status.
**Implement-if-missing:** Confirm Exchange Online is the mail path for the pilot users (MX / connectors as applicable).

## 2.3 Pilot user group (test mailboxes)
**Description:** A small set of **pilot mailboxes** grouped as `MDO PoC – Pilot Users – Pilot` — ideally test/volunteer users who expect the simulation.
**Why:** The preset policy and the benign phishing simulation apply only to this group, so the org-wide mail flow is untouched and teardown is clean.
**Verify:** A mail-enabled security group `MDO PoC – Pilot Users – Pilot` exists; `POCMDO-Enable.ps1 -WhatIf` lists membership.
**Implement-if-missing:** Create the group and add a handful of pilot mailboxes. *Coordinate with the users so the benign phishing simulation is expected.*

## 2.4 Attack Simulation Training available (for the phishing demo)
**Description:** **Attack Simulation Training** enabled in the portal (Defender for Office 365 **P2**).
**Why:** It is Microsoft's built-in, **safe** phishing simulator — the sanctioned way to generate benign phishing signal without sending real phishing.
**Verify:** `security.microsoft.com` → **Email & collaboration → Attack simulation training** loads. *Verify P2 licensing and current availability in your tenant.*
**Implement-if-missing:** Ensure P2 is assigned; if unavailable, use only the GTUBE / EICAR / Safe Links test-message path (still benign) and note the simulation demo as "not licensed."

## 2.5 Evaluation criteria agreed up front
**Description:** A short, written list of what "pass" means — e.g. *Safe Links rewrote the test URL, Safe Attachments detonated EICAR, the spam string was actioned, the simulation was captured in Threat Explorer.*
**Why:** A PoC is only conclusive if the bar is set **before** you run it; the scorecard maps observations to these criteria.
**Verify:** A criteria list exists; `POCMDO-Scorecard.ps1` accepts it as input.
**Implement-if-missing:** Draft 5–8 criteria with the evaluating stakeholders before Step 1. *What counts as "good enough" is the customer's decision.*

## 2.6 Advanced-hunting read access
**Description:** Permission to run advanced-hunting queries via the portal and the Graph Security API (`ThreatHunting.Read.All`).
**Why:** The validate and scorecard scripts confirm the signal landed in `EmailEvents`, `UrlClickEvents`, and `EmailAttachmentInfo`.
**Verify:** `security.microsoft.com` → **Hunting → Advanced hunting** runs a query; `POCMDO-Validate.ps1` returns rows.
**Implement-if-missing:** Grant the running account **Security Reader** (or higher) and consent to the read-only hunting scope.

## 2.7 Quarantine review access (for teardown)
**Description:** Permission to view and release/purge **quarantine** (Security Administrator / Quarantine Administrator).
**Why:** Benign test messages may be quarantined; teardown purges them cleanly.
**Verify:** `security.microsoft.com` → **Email & collaboration → Review → Quarantine** loads.
**Implement-if-missing:** Assign the quarantine review permission to the running account.

---
## Checklist
- [ ] Defender for Office 365 plan (P1/P2) available — `POCMDO-Enable.ps1 -WhatIf`
- [ ] Exchange Online mail flow for the pilot mailboxes
- [ ] Pilot user group `MDO PoC – Pilot Users – Pilot` (test/volunteer users)
- [ ] Attack Simulation Training available (P2) — or note the simulation demo as unlicensed
- [ ] Evaluation criteria agreed and written down — `POCMDO-Scorecard.ps1`
- [ ] Advanced-hunting read access (`ThreatHunting.Read.All`)
- [ ] Quarantine review access for teardown


---


# Global Requirements — Defender (category-level)

These requirements apply to every solution in the Defender category (Microsoft Defender XDR and Defender
for Cloud). Published once at the category level so listings stay small. Confirm before deploying any
Defender solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Defender changes touch detection and response for the whole tenant. Onboard in a ring (pilot devices/
> users first), keep automated response in an approval/simulate posture until trusted, and never disable
> an existing control to "test."

## G1. Microsoft 365 / Entra tenant
Description: An active Microsoft 365 tenant with Entra ID.
Why: Defender XDR services and the unified portal (security.microsoft.com) are tenant workloads.
Verify: Sign in to `https://security.microsoft.com` as an administrator.
Implement: Provision a Microsoft 365 tenant and confirm Entra ID identities exist.

## G2. Defender licensing
Description: The Defender plans for the pillars in scope — e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, and Defender for Cloud plans.
Why: Each pillar/feature is license-gated; onboarding without the plan fails or silently limits features.
Verify: Admin center -> `Billing -> Licenses` (or the Defender portal). *Confirm the exact plan each feature needs — verify current availability in your tenant.*
Implement: Assign the required plans (often bundled in M365 E5 / E5 Security) before onboarding.

## G3. Administrative roles (least privilege)
Description: Security Administrator (and Global Administrator for first-time service activation).
Why: Onboarding, RBAC, and policy changes in the Defender portal require these roles.
Verify: Entra -> `Roles and administrators`; confirm Security Administrator.
Implement: Assign Security Administrator; reserve Global Administrator for one-time activations.

## G4. Onboarding reach to endpoints / identity / workloads
Description: A management channel to onboard the pillars — Intune/Configuration Manager/GPO/script for endpoints, domain controllers/AD FS for Identity sensors, and cloud connectors for Defender for Cloud.
Why: Each pillar collects signal from a source that must be reachable and instrumented.
Verify: Endpoints are managed (Intune/CM); DCs are reachable; cloud subscriptions are connected. Run the solution's discovery script.
Implement: Establish the onboarding channel per pillar (see the relevant catalog endpoint/identity solutions).

## G5. Network access to Defender service endpoints
Description: Outbound HTTPS to the Microsoft Defender / Microsoft 365 service URLs from onboarded assets.
Why: Sensors and agents report to the cloud service; blocked endpoints break onboarding and detections.
Verify: Confirm the documented Defender endpoint URLs/IP ranges are allowed. *Verify current endpoint list.*
Implement: Allow the Defender/M365 endpoints through proxy/firewall.

## G6. A pilot ring
Description: A defined set of pilot devices/users/subscriptions to onboard first.
Why: XDR onboarding and automated response are validated on a ring before tenant-wide rollout.
Verify: A pilot group exists in Entra/Intune.
Implement: Create the pilot ring before enabling anything that acts automatically.

## G7. Log Analytics workspace (where required)
Description: A Log Analytics workspace for Defender for Cloud / advanced hunting export where used.
Why: Some Defender data and continuous export land in a workspace.
Verify: A workspace exists and is access-controlled. Run the discovery script.
Implement: Provision a workspace (or reuse the SIEM/observability one) with least-privilege access.

## G8. Response governance
Description: An agreed position on automated response (auto-remediation levels, approval requirements).
Why: XDR/AIR can take disruptive actions (isolate, delete, disable); the organization must decide the guardrails.
Verify: A documented response policy exists; automation is in an approval/simulate posture until trusted.
Implement: Define response guardrails; keep AIR/automation approval-gated at first. *Incident-response decisions are the SOC/security team's; this guide covers the technical configuration.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Proof-of-Concept Kit: Microsoft Defender for Office 365

Follow these steps **in order**. Most work is in the **unified Defender portal** (`https://security.microsoft.com`); policy scoping uses **Exchange Online Management** PowerShell. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model (run as a PoC):** Assess readiness, scope MDO protection to **pilot users** only, generate **benign** test signal, validate the detections and score them, then **tear down**. All test signal is Attack Simulation Training, GTUBE, EICAR, or a benign test URL — **never real phishing or malware**. The wider org's mail flow is never changed.

## Naming (set once, reuse verbatim)
- Pilot user group: `MDO PoC – Pilot Users – Pilot`
- Preset policy: **Standard preset security policy**, scoped **only** to `MDO PoC – Pilot Users – Pilot`
- Attack Simulation campaign: `MDO PoC Phish Simulation – Pilot Users – Pilot`
- Scorecard output file: `MDO PoC Scorecard – Pilot Users – Validate`
- Test-signal subject tag: `MDO-PoC-TESTSIGNAL`

## Step 1 — Assess readiness (read-only)
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `POCMDO-Enable.ps1 -WhatIf` — previews (changes nothing): the MDO plan (P1/P2), admin roles, Exchange Online mail flow, whether `MDO PoC – Pilot Users – Pilot` exists, and whether Attack Simulation Training is available.
3. In **Entra** → **Groups** (or Exchange admin center), create the mail-enabled security group `MDO PoC – Pilot Users – Pilot` and add a handful of **test/volunteer** mailboxes. Tell those users a benign simulation is coming.

## Step 2 — Enable MDO on the pilot users
1. `security.microsoft.com` → **Email & collaboration → Policies & rules → Threat policies → Preset security policies**.
2. Turn on the **Standard** preset and scope its recipients **only** to `MDO PoC – Pilot Users – Pilot`. This enables Safe Links, Safe Attachments, and anti-phishing for the pilot users, leaving the org unchanged.
3. Alternatively run `POCMDO-Enable.ps1` (without `-WhatIf`) — it is `-WhatIf`-gated and scopes the Standard preset rule to the pilot group via Exchange Online, showing the plan before it applies.
4. Confirm the scope: `security.microsoft.com` → the preset shows the pilot group as the applied recipients.

## Step 3 — Generate benign test signal
1. Run `POCMDO-TestSignal.ps1` — it performs only **benign, documented** actions, tagged `MDO-PoC-TESTSIGNAL`:
   - **Launch a phishing simulation:** prints the exact steps (and, where permitted, kicks off via Graph) for `security.microsoft.com` → **Attack simulation training → Launch a simulation** → name it `MDO PoC Phish Simulation – Pilot Users – Pilot`, choose a **built-in benign template**, target `MDO PoC – Pilot Users – Pilot`. *This is Microsoft's safe simulator — no real phishing is sent.*
   - **Send a benign spam test:** a message containing the standard **GTUBE** anti-spam test string.
   - **Send a benign attachment test:** a message with the **EICAR** test file attached (exercises Safe Attachments).
   - **Send a benign link test:** a message containing a benign **Safe Links** test URL to exercise time-of-click rewriting.
2. **Do not** send real phishing, real malware, or live malicious URLs. The benign signals above are sufficient.
3. Note the time of each signal for the scorecard latency comparison.

## Step 4 — Validate and demonstrate the detections
1. Run `POCMDO-Validate.ps1` — it confirms (read-only): Safe Links rewrote the test URL (`UrlClickEvents`), Safe Attachments actioned the EICAR message (`EmailAttachmentInfo` / `EmailEvents`), the spam string was handled, and the simulation appears (`EmailEvents`).
2. In the portal, walk the demo: `security.microsoft.com` → **Email & collaboration → Explorer** (Threat Explorer, P2) shows the simulation and test messages; open a message → view **Safe Links** verdict; **Review → Quarantine** shows quarantined test items; **Attack simulation training** shows the campaign results.
3. Confirm no production mailbox outside the pilot group was affected.

## Step 5 — Score against your criteria
1. Run `POCMDO-Scorecard.ps1 -CriteriaPath .\criteria.json -OutFile "MDO PoC Scorecard – Pilot Users – Validate.json"`. It maps each observation (Safe Links rewrite, Safe Attachments detonation, spam/phish handling, Threat Explorer visibility) to your pass/fail criteria and writes the scorecard.
2. Review the scorecard with stakeholders — the decision artefact.

## Step 6 — Tear down (clean rollback)
1. Run `POCMDO-Teardown.ps1 -WhatIf` first to preview, then for real.
2. Teardown: **remove** the pilot scope from the Standard preset (return it to off/its prior state), **end** the simulation `MDO PoC Phish Simulation – Pilot Users – Pilot`, and **purge** the `MDO-PoC-TESTSIGNAL` test messages from quarantine/inboxes.
3. Optionally delete the pilot group `MDO PoC – Pilot Users – Pilot`. Keep the scorecard as your record.

## Step 7 — Decide: expand or stop
1. If the PoC passed and you choose to proceed, move to an **org-wide MDO hardening** engagement — a separate, adjacent solution (see *Where to go next*); do not simply widen the pilot scope without a plan.
2. If not proceeding, confirm teardown with `POCMDO-Validate.ps1` (it should now report the pilot scope removed).

---
### Order of operations
`Assess (-WhatIf) → scope Standard preset to pilot users → generate benign simulation/GTUBE/EICAR/Safe Links signal → validate + demonstrate (Threat Explorer) → score vs criteria → teardown (-WhatIf then real) → decide expand or stop`


---


# 5. Testing Guide — Proof-of-Concept Kit: Microsoft Defender for Office 365

Run these checks during the PoC (Steps 2–6 of the Implementation Guide). Each test has a **pass/fail gate**. All signal is **benign** (Attack Simulation Training / GTUBE / EICAR / benign test URL). Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Pilot scope applied
**Procedure:** Run `POCMDO-Enable.ps1 -WhatIf`, then confirm the **Standard preset** applies to `MDO PoC – Pilot Users – Pilot` and to no one else.
**Pass:** The preset is scoped to the pilot group only; the wider org is unchanged.
**Fail:** Scope is wrong or org-wide — see Troubleshooting *Preset scope wrong*.

## Test 2 — Benign signal generated
**Procedure:** Run `POCMDO-TestSignal.ps1`; confirm the simulation launched and the GTUBE / EICAR / Safe Links test messages were sent to pilot users.
**Pass:** All benign signals were generated; no real phishing/malware used.
**Fail:** A signal did not send — see Troubleshooting *Test message not delivered*.

## Test 3 — Safe Links rewriting
**Procedure:** In a pilot mailbox open the benign link test; confirm the URL was rewritten; `POCMDO-Validate.ps1` checks `UrlClickEvents`.
**Pass:** The test URL is rewritten by Safe Links and click telemetry appears.
**Fail:** URL not rewritten — see Troubleshooting *Safe Links not rewriting*.

## Test 4 — Safe Attachments detonation
**Procedure:** Confirm the EICAR attachment message was actioned (blocked/quarantined); `POCMDO-Validate.ps1` checks `EmailAttachmentInfo` / `EmailEvents`.
**Pass:** Safe Attachments detonated/actioned the EICAR message.
**Fail:** Attachment delivered clean — see Troubleshooting *Safe Attachments not detonating*.

## Test 5 — Spam/phish handling
**Procedure:** Confirm the GTUBE message was treated as spam (quarantined/junked); check advanced hunting and quarantine.
**Pass:** The spam-test message was actioned per policy.
**Fail:** GTUBE delivered to inbox — see Troubleshooting *GTUBE not actioned*.

## Test 6 — Threat Explorer / simulation visibility
**Procedure:** `security.microsoft.com` → **Explorer** (P2) and **Attack simulation training** show the campaign and test messages; `POCMDO-Validate.ps1` confirms `EmailEvents` rows.
**Pass:** The simulation and test signal are visible for investigation.
**Fail:** Nothing appears — allow warm-up; see Troubleshooting *No Explorer visibility*.

## Test 7 — Scorecard produced
**Procedure:** Run `POCMDO-Scorecard.ps1` and confirm `MDO PoC Scorecard – Pilot Users – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria.
**Fail:** Missing observations — re-run the relevant validate step first.

## Test 8 — Clean teardown
**Procedure:** Run `POCMDO-Teardown.ps1 -WhatIf`, then for real; re-run `POCMDO-Validate.ps1`.
**Pass:** The pilot scope is removed, the simulation ended, and test messages purged — validate reports the scope gone.
**Fail:** Residue remains — see Troubleshooting *Teardown left residue*.

---
### Exit gate
Tests 1–7 pass to call the PoC conclusive; Test 8 passes to close it out cleanly. Keep the scorecard file as the decision record.


---


# 6. Troubleshooting Guide — Proof-of-Concept Kit: Microsoft Defender for Office 365

Common field issues, in **symptom → cause → fix** form. Run `POCMDO-Enable.ps1 -WhatIf` and `POCMDO-Validate.ps1` first — most causes surface there. All test signal is benign (Attack Simulation / GTUBE / EICAR / benign test URL).

## Preset scope wrong
**Symptom:** The Standard preset applies org-wide or to the wrong recipients.
**Cause:** The preset recipient scope was not restricted to `MDO PoC – Pilot Users – Pilot`, or a prior preset already covers the org.
**Fix:** In **Policies & rules → Preset security policies**, set the Standard preset recipients to the pilot group only; confirm no broader preset overlaps. Re-run `POCMDO-Enable.ps1 -WhatIf`.

## Test message not delivered
**Symptom:** A GTUBE / EICAR / Safe Links test message never arrives at the pilot mailbox.
**Cause:** The message was blocked before delivery (expected for EICAR/GTUBE — check quarantine), the sending account is not permitted, or mail flow is misrouted.
**Fix:** Check **Review → Quarantine** — EICAR/GTUBE messages are *meant* to be caught; that is a pass, not a delivery failure. Confirm the sender and Exchange Online mail flow. Re-run `POCMDO-TestSignal.ps1`.

## Safe Links not rewriting
**Symptom:** Test 3 fails — the benign test URL is not rewritten in the pilot mailbox.
**Cause:** The preset is not applied to the pilot users, Safe Links is off in the applied policy, or the message bypassed policy (e.g. internal sender exceptions).
**Fix:** Confirm the Standard preset covers the pilot users and Safe Links is enabled; send the link from an external test sender; allow a moment and re-check `UrlClickEvents` with `POCMDO-Validate.ps1`.

## Safe Attachments not detonating
**Symptom:** Test 4 fails — the EICAR attachment is delivered without action.
**Cause:** Safe Attachments is not in the applied preset, the MDO plan is not licensed, or the file was stripped upstream.
**Fix:** Confirm Safe Attachments is on for the pilot users and the MDO plan is licensed (P1+); resend the EICAR attachment; check `EmailAttachmentInfo`. *Verify current plan features.*

## GTUBE not actioned
**Symptom:** Test 5 fails — the GTUBE spam-test message lands in the inbox.
**Cause:** Anti-spam policy is not applied to the pilot users or an allow-rule/safe-sender overrides it.
**Fix:** Confirm anti-spam (EOP) applies to the pilot users and no allow-list overrides the sender; resend GTUBE from an external address and check quarantine.

## No Explorer visibility
**Symptom:** Test 6 fails — Threat Explorer or the simulation shows nothing.
**Cause:** Threat Explorer / Attack Simulation Training require **P2**, or signal has not populated yet.
**Fix:** Confirm **P2** licensing (*verify current availability*); allow warm-up time for `EmailEvents`; re-run `POCMDO-Validate.ps1`. If P2 is unavailable, record the Explorer/simulation demos as "not licensed," not "failed."

## Simulation will not launch
**Symptom:** The Attack Simulation campaign cannot be created.
**Cause:** Missing **Attack Simulation Administrator** role or P2 licensing, or the target group is empty.
**Fix:** Assign the role and confirm P2; ensure `MDO PoC – Pilot Users – Pilot` has members; retry the launch per Implementation Step 3.

## Script cannot authenticate
**Symptom:** `POCMDO-*.ps1` fails on connect or returns access-denied.
**Cause:** The Exchange Online Management / Microsoft Graph modules are missing, scopes were not consented, or the account lacks the role.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-ExchangeOnline` / `Connect-MgGraph` and consent to the read-only scopes; confirm **Security Reader** plus **Exchange Administrator** for scoping. Re-run.

## Teardown left residue
**Symptom:** After `POCMDO-Teardown.ps1`, the pilot scope or test messages remain.
**Cause:** Teardown ran in `-WhatIf` only, or quarantine purge needs the quarantine role.
**Fix:** Run teardown **without** `-WhatIf`; confirm the Quarantine Administrator/Security Administrator role; purge the `MDO-PoC-TESTSIGNAL` items and re-confirm with `POCMDO-Validate.ps1`.


---


# 7. Best Practices — Proof-of-Concept Kit: Microsoft Defender for Office 365

Field-proven guidance for running a clean, safe, conclusive MDO proof of concept.

## Keep the PoC scoped and reversible
- Scope the preset security policy to **pilot users only** (`MDO PoC – Pilot Users – Pilot`). Never widen it to the whole org during a PoC — the value is that you can roll the scope back without touching production mail flow.
- Preview every change with `-WhatIf` first (`POCMDO-Enable.ps1`, `POCMDO-Teardown.ps1`).

## Benign signal only — never real phishing or malware
- Use **Attack Simulation Training**, **GTUBE**, **EICAR**, and a benign **Safe Links** test URL exclusively. They are the sanctioned, harmless ways to exercise MDO.
- **Never** send real phishing, attach real malware, or embed a live malicious URL. Attack Simulation Training exists precisely so you don't have to.

## Tell the pilot users
- Coordinate with the pilot mailboxes before launching the simulation. A PoC is an evaluation, not a covert test of the users — that framing keeps trust and produces cleaner results.

## Set the bar before you run
- Agree the **evaluation criteria** in writing first (Requirement 2.5). Feed them into `POCMDO-Scorecard.ps1` so the verdict is objective, not a vibe.

## Allow for delivery, detonation, and ZAP timing
- Safe Attachments detonation, Safe Links time-of-click, and ZAP act at different moments. Give the pipeline a few minutes before scoring a "fail," and use `POCMDO-Validate.ps1` to see when signal has arrived.

## Mind the licensing gates
- Safe Links / Safe Attachments / anti-phish need **P1**; **Threat Explorer, Attack Simulation Training, and AIR need P2**. **Verify current plan availability in your tenant** before assuming a capability is included, and if P2 is absent, note the simulation/Explorer demos as unlicensed rather than "failed."

## Tear down completely
- Remove the pilot scope, end the simulation, and **purge** the `MDO-PoC-TESTSIGNAL` messages from quarantine and inboxes. Then confirm with `POCMDO-Validate.ps1`. Keep only the scorecard.

## Defer the decisions to the owners
- Whether the PoC "passed," how to weight criteria, and whether to proceed to org-wide hardening are **the customer's** decisions. Policy-hardening and incident-response runbooks are the **security team's**. This kit delivers the proof, not the verdict.

## Where to go next
Once the PoC proves MDO, natural next steps in the catalogue:
- The **Defender for Office 365 (P2) — Threat Explorer, Attack Simulation & AIR** solution to operationalise the email pillar org-wide.
- The **EOP / MDO email-hygiene hardening** solution for baseline anti-spam/anti-phish tuning.
- The **Defender XDR Deployment & Unified Onboarding** solution to correlate MDO with Endpoint, Identity, and Cloud Apps.
- The **Sentinel SOC/XDR integration** solution to stream MDO into a SIEM for long-term hunting.


---


# 8. Deliverables Summary — Proof-of-Concept Kit: Microsoft Defender for Office 365

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | What the PoC proves, the boundary, and the effort |
| 1. Solution Overview | What MDO / email & collaboration security is and how a scoped, safe PoC proves it |
| 2. Requirements Guide | PoC-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — scope to pilot users, generate benign signal, validate, score, tear down |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Safe-PoC guidance and where to go next |

## PowerShell scripts (Exchange Online Management / Microsoft Graph Security + KQL)
| Script | What it does |
|---|---|
| `POCMDO-Enable.ps1` | `-WhatIf`-gated pilot enable — previews readiness, then scopes the Standard preset security policy to `MDO PoC – Pilot Users – Pilot` (safe preview by default) |
| `POCMDO-TestSignal.ps1` | **Benign** test-signal helper — launches an Attack Simulation phishing campaign and sends GTUBE / EICAR / Safe Links test messages (no real phishing or malware, ever) |
| `POCMDO-Validate.ps1` | Read-only demo/validate — confirms Safe Links rewriting, Safe Attachments detonation, spam/phish handling, and Threat Explorer / hunting visibility |
| `POCMDO-Scorecard.ps1` | Scores observations against your evaluation criteria and writes `MDO PoC Scorecard – Pilot Users – Validate` |
| `POCMDO-Teardown.ps1` | `-WhatIf`-gated clean rollback — removes the pilot scope, ends the simulation, purges test messages from quarantine |

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — run here as a safe, reversible PoC with remediation kept reviewable.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A concrete, in-tenant proof that Microsoft Defender for Office 365 delivers email & collaboration security — a benign phishing simulation and test messages handled by Safe Links, Safe Attachments, anti-phish and ZAP, visible in Threat Explorer and advanced hunting — scored against your criteria and cleanly rolled back.
