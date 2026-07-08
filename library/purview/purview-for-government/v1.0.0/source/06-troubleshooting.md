# 6. Troubleshooting — Microsoft Purview for Government

The failure modes you are most likely to hit, and how to fix them. Each entry: **symptom → likely cause →
fix**. Read-only diagnostics first; only change state through `INDGOV-Configure.ps1` (which is `-WhatIf` by
default and keeps DLP in simulation). Remember the boundary: **classification (CJI/CUI/ITAR), CMMC level,
retention adequacy, and ITAR access are compliance/security/records/legal determinations**, and behavior is
**cloud-dependent — verify in your cloud.**

## `Connect-IPPSSession` / `Connect-MgGraph` fails or connects the wrong tenant
- **Likely cause:** you are in a sovereign cloud (GCC High/DoD) but used the **commercial** endpoint — the
  default endpoints will not connect a sovereign tenant.
- **Fix:** pass your cloud's endpoint: `Connect-IPPSSession -ConnectionUri <your cloud's S&C endpoint>` and
  `Connect-MgGraph -Environment USGov|USGovDoD`. All five scripts accept `-ConnectionUri` / `-GraphEnvironment`.
  **Verify the exact endpoint/environment for your cloud from current Microsoft documentation** — do not
  assume the value shown in an example.

## A capability is missing from the portal or a cmdlet errors "not recognized"
- **Likely cause:** the feature is **not licensed** (needs E5 / E5 Compliance in your gov SKU), or **not
  available in your cloud** (GCC/GCC High/DoD differ), or the module is out of date.
- **Fix:** run `INDGOV-Discovery.ps1` licensing section; confirm the plan is present **and assigned** to
  in-scope users (Requirement 2.1). Update `ExchangeOnlineManagement` / `Microsoft.Graph`. If the capability
  genuinely isn't in your cloud, that is a **cloud/licensing gap**, not a config defect — verify with your
  tenant admin.

## Graph licensing check reports plans "NOT found" that you believe you have
- **Likely cause:** **service-plan names differ in government SKUs** and change over time; the indicative
  names in `INDGOV-Discovery.ps1` are examples to **verify**, not authoritative.
- **Fix:** list your actual plans (`Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus'`) and match
  the capability to the plan name **your** tenant uses. Update the script's `$wanted` map to your cloud's
  names. Treat the check as directional.

## A sensitivity label doesn't appear for pilot users
- **Likely cause:** the label exists (`Get-Label`) but isn't **published** via an enabled label policy, or the
  policy isn't scoped to the pilot users, or client/label-availability latency.
- **Fix:** confirm an enabled `Get-LabelPolicy` scopes the government labels to `Gov Pilot – Controlled Data –
  Stage1`; allow for publish latency; re-check with `INDGOV-Validate.ps1` (Labels gates). Publish **pilot-first**
  before broad rollout.

## An encrypting label blocks users who should have access (or lets in users who shouldn't)
- **Likely cause:** the label's **encryption/rights** definition is wrong — the point of Gate 4 is to catch
  this before broad publish. For ITAR, the U.S.-person access constraint may be missing or too broad.
- **Fix:** correct the rights in-portal, re-test access on benign pilot content (Testing Gate 4), and only then
  broaden publish. **The ITAR access rule is legal's determination** — do not set it yourself. Content already
  encrypted retains its protection; verify decryption/access recovery in your tenant before wide use.

## DLP simulation shows no matches (or far too many)
- **Likely cause:** the DLP **conditions / sensitive-info types** are under- or over-matching CJI/CUI/ITAR
  content — exactly what simulation is for.
- **Fix:** review matches with `INDGOV-Report.ps1 -DlpMatches`; tune the rule's conditions/SITs in-portal (the
  SITs are governance's determination). Zero matches during an active simulation usually means **under-matching
  detection**, not that no controlled data moved (Testing Gate 5/6). **Keep the policy in simulation** until it
  matches correctly.

## Endpoint DLP records nothing on a test device
- **Likely cause:** the device is **not onboarded**, endpoint DLP is **not available/licensed in your cloud**,
  or the egress-channel conditions (USB/print/cloud-upload) don't cover the test action.
- **Fix:** confirm device onboarding in the Purview portal → **Settings → Devices**; confirm endpoint DLP is
  available in your cloud (Requirement 2.4/2.1); verify the rule's egress-channel conditions; retest. Endpoint
  DLP only controls **onboarded** devices.

## A DLP policy is blocking legitimate work
- **Likely cause:** a policy was moved to **enforce** before simulation validated it, or the block scope is too
  broad.
- **Fix:** move it **back to simulation** (`Set-DlpCompliancePolicy … -Mode Enable` / recreate via
  `INDGOV-Configure.ps1`), review matches, tune conditions, and only re-enforce after validation and sign-off
  (Implementation Step 8). **DLP is high-impact — simulate first, always.**

## `Get-AdminAuditLogConfig` / `UnifiedAuditLogIngestionEnabled` cannot be read
- **Likely cause:** that cmdlet runs in **Exchange Online PowerShell** (`Connect-ExchangeOnline`), not S&C
  PowerShell, and needs your **cloud** endpoint.
- **Fix:** `Connect-ExchangeOnline -ConnectionUri <your cloud endpoint>` then re-read; `INDGOV-Validate.ps1`
  attempts this fallback automatically. If ingestion is **False**, enable it under change control — audit
  evidence is **not retroactive**.

## Audit retention policy rejected (invalid `RetentionDuration` or unlicensed tier)
- **Likely cause:** the requested long-term duration isn't an accepted value or isn't **licensed** in your
  cloud (Audit Premium).
- **Fix:** verify accepted `-RetentionDuration` values and that the long-term tier is licensed (Requirement
  2.1); adjust `-Duration` and re-run `INDGOV-Configure.ps1 -Control Audit`. Ensure a **unique** `-Priority`.

## The evidence binder has "NOT FOUND" rows
- **Likely cause:** a control in `Control Map – Gov – Purview` has no implementing Purview object, or the object
  name doesn't match the naming convention verbatim.
- **Fix:** create the missing control via `INDGOV-Configure.ps1`, or correct the object name to match the
  convention exactly; re-run `INDGOV-Report.ps1`. A control with no evidence fails an assessment.

## "Is this configuration CJIS/CMMC/ITAR compliant?" — the wrong question for this tool
- **Reality:** this solution **configures and evidences** the technical controls; whether they **satisfy** the
  CJIS Security Policy, CMMC / NIST SP 800-171, or the ITAR — and which CMMC level applies — is a
  **compliance/security/legal determination**. It makes **no certification or authorization-to-operate claim.**
- **Fix:** take the `Evidence – Gov Controls – Binder` and `Control Map – Gov – Purview` to your governance
  functions for the determination; keep the technical controls green via the scheduled read-only chain.
