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
