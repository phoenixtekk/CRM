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
