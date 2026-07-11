# 3. Implementation Guide — Proof-of-Concept Kit: Microsoft Defender for Cloud Apps

Follow these steps **in order**. All work is in the **unified Defender portal** (`https://security.microsoft.com` → **Cloud apps**). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model (run as a PoC):** Assess readiness, enable discovery + an **audit-mode** policy for **pilot users** only, generate **benign** test signal, validate the detections and score them, then **tear down**. All test signal is Microsoft's sample discovery log and benign policy-matching activity — **never real exfiltration or attacks**. Enforcement (blocking / session control) stays **off**; no production user is affected.

## Naming (set once, reuse verbatim)
- Pilot user group: `MDCA PoC – Pilot Users – Pilot`
- Audit-mode activity policy: `MDCA PoC Activity Policy – Pilot Users – Audit`
- (Optional) app connector: `MDCA PoC Connector – Microsoft365 – Pilot`
- Discovery report: `MDCA PoC Discovery – Pilot – Report`
- Scorecard output file: `MDCA PoC Scorecard – Pilot Users – Validate`
- Test-signal tag (used in notes/hunting): `MDCA-PoC-TESTSIGNAL`

## Step 1 — Assess readiness (read-only)
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `POCMDCA-Enable.ps1 -WhatIf` — previews (changes nothing): the MDCA plan, admin roles, whether MDCA is activated, the discovery source, connectors, and whether `MDCA PoC – Pilot Users – Pilot` exists.
3. In **Entra → Groups**, create `MDCA PoC – Pilot Users – Pilot` and add a handful of **test** users (including the account you will use to generate benign activity).

## Step 2 — Enable discovery and an audit-mode policy
1. `security.microsoft.com` → **Cloud apps → Cloud discovery → Settings** — confirm a discovery source (enable the **Defender for Endpoint integration**, or plan to upload the sample log in Step 3).
2. `security.microsoft.com` → **Cloud apps → Policies → Policy management → Create policy → Activity policy**. Name it `MDCA PoC Activity Policy – Pilot Users – Audit`. Scope the filter to `MDCA PoC – Pilot Users – Pilot`, choose a benign, repeatable trigger (e.g. a specific administrative activity or a download threshold), and set **Governance actions = none** (audit only — no alerts-to-block, no session control).
3. Alternatively run `POCMDCA-Enable.ps1` (without `-WhatIf`) — it is `-WhatIf`-gated and guides/marks the audit-policy creation scoped to the pilot group.
4. (Optional) **Cloud apps → Connected apps → App connectors** → add `MDCA PoC Connector – Microsoft365 – Pilot` in **monitor** mode.

## Step 3 — Generate benign test signal
1. Run `POCMDCA-TestSignal.ps1` (or follow its printed steps). It performs only **benign, documented** actions tagged `MDCA-PoC-TESTSIGNAL`:
   - **Cloud Discovery:** upload Microsoft's **sample Cloud Discovery log** — `Cloud apps → Cloud discovery → Actions → Create Cloud Discovery snapshot report` → upload the sample log. This produces the Shadow IT report `MDCA PoC Discovery – Pilot – Report` from safe, sample data.
   - **Policy-matching activity:** as the test account, perform the **benign** action the audit policy watches for (e.g. download a few non-sensitive files from a monitored app, or perform the benign administrative activity). This is normal activity that the audit policy is configured to notice — nothing is exfiltrated.
2. **Do not** exfiltrate real data, connect a malicious app, or grant a risky OAuth consent. The sample log and benign activity are sufficient.
3. Note the time of each signal for the scorecard latency comparison.

## Step 4 — Validate and demonstrate the detections
1. Run `POCMDCA-Validate.ps1` — it confirms (read-only): the discovery report populated, the audit policy `MDCA PoC Activity Policy – Pilot Users – Audit` matched, an alert surfaced (`AlertInfo`), and activity appears in `CloudAppEvents`.
2. In the portal, walk the demo: `Cloud apps → Cloud discovery → Dashboard` shows the Shadow IT report; `Cloud apps → Activity log` shows the benign activity; `Cloud apps → Alerts` (or **Incidents & alerts**) shows the policy match.
3. Confirm **no governance action** was taken (audit only) and no production user affected.

## Step 5 — Score against your criteria
1. Run `POCMDCA-Scorecard.ps1 -CriteriaPath .\criteria.json -OutFile "MDCA PoC Scorecard – Pilot Users – Validate.json"`. It maps each observation (discovery populated, policy matched, alert surfaced, activity visible) to your pass/fail criteria and writes the scorecard.
2. Review the scorecard with stakeholders — the decision artefact.

## Step 6 — Tear down (clean rollback)
1. Run `POCMDCA-Teardown.ps1 -WhatIf` first to preview, then for real.
2. Teardown: **delete** the policy `MDCA PoC Activity Policy – Pilot Users – Audit`, **delete** the discovery report `MDCA PoC Discovery – Pilot – Report`, **remove** the optional connector, and **resolve** the `MDCA-PoC-TESTSIGNAL` alerts.
3. Optionally delete the pilot group `MDCA PoC – Pilot Users – Pilot`. Keep the scorecard as your record.

## Step 7 — Decide: expand or stop
1. If the PoC passed and you choose to proceed, move to an **org-wide MDCA governance / session-control / DLP** engagement — a separate, adjacent solution (see *Where to go next*).
2. If not proceeding, confirm teardown with `POCMDCA-Validate.ps1` (the policy and report should be gone).

---
### Order of operations
`Assess (-WhatIf) → enable discovery + audit-mode policy (pilot users) → upload sample discovery log + benign policy-matching activity → validate + demonstrate → score vs criteria → teardown (-WhatIf then real) → decide expand or stop`
