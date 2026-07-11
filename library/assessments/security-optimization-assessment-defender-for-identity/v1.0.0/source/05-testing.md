# 5. Testing — Security Optimization Assessment: Defender for Identity

Because this is a **read-only** assessment, "testing" proves two things: the assessor has **read-only** access (and no write), and the **report is accurate** — above all that the **sensor-coverage denominator (the DC inventory) is real** and reconciles with the Defender portal. Run these gates in order; each has an explicit **pass/fail**.

## Gate 1 — Read-only access proven (run `SOAMDI-Validate.ps1`)
**Procedure:** Run `SOAMDI-Validate.ps1` with the assessor identity from a domain-joined host.
**Pass:** Success on all of — AD read enumerates domain controllers; `Connect-MgGraph` with read scopes; an advanced-hunting query (`IdentityInfo | take 1`) returns; and it confirms **no write scope** is present.
**Fail:** Any read fails (fix access per R2–R4) **or** a write scope is detected (reduce to Security Reader — an assessment must not hold write access).

## Gate 2 — The DC inventory is complete (the denominator)
**Procedure:** Compare the DC list from `Get-ADDomainController -Filter *` against the AD team's authoritative list (R5).
**Pass:** The AD-derived DC list matches operational reality — every domain, every site, including recently-promoted DCs.
**Fail:** DCs are missing from the enumeration (e.g. an unreachable child domain, a trust not traversed). Resolve scope/trust access first — an incomplete denominator hides the exact blind spots the assessment exists to find.

## Gate 3 — Discovery completeness (run `SOAMDI-Discovery.ps1`)
**Procedure:** Run discovery; inspect the run folder.
**Pass:** Raw outputs exist for every area — AD inventory, sensor list/health, DSA signal, honeytoken/tagged entities, ISPM recommendations, and detection activity — with `verify` flags clearly marking any item that needs portal confirmation (rather than silently omitting it).
**Fail:** An area is silently empty. If sensor/DSA/honeytoken data has no API in your tenant, it must be **flagged for portal confirmation**, not dropped — confirm those values in the portal and record them.

## Gate 4 — Coverage names the blind spots (run `SOAMDI-Coverage.ps1`)
**Procedure:** Run coverage; open the un-sensored-server list.
**Pass:** DC sensor coverage is a fraction of the **AD-derived** DC count, and every un-sensored or unhealthy DC (and AD FS / AD CS server) is **named**, not just counted. Honeytoken and DSA signals are present.
**Fail:** Coverage is computed against the sensor list alone (can never reveal a DC with no sensor), or blind DCs are counted but not named — re-run with the AD inventory as the denominator.

## Gate 5 — Scoring is defensible (run `SOAMDI-Assess.ps1`)
**Procedure:** Run scoring; open the scorecard CSV.
**Pass:** Every check has **Pass/Partial/Fail/N-A**, a **severity** on each non-pass (un-sensored DC = High), the **baseline name** stamped in, and the weighted posture score computes. Absent features (e.g. no AD CS in the environment) are **N-A**, not Fail.
**Fail:** Checks unscored, severities missing, or an un-sensored DC scored anything other than High.

## Gate 6 — Report reconciles with the portal (run `SOAMDI-Report.ps1`)
**Procedure:** Generate the report; spot-check the **top findings** and any `verify`-flagged item.
**Pass:** Each matches the portal — a DC the report flags as un-sensored is genuinely absent (or unhealthy) under **Settings → Identities → Sensors**; the DSA/honeytoken `verify` items are confirmed. Findings sorted High → Low with evidence and remediation pointers.
**Fail:** A spot-checked finding does not match — re-run discovery for a fresh snapshot, confirm the `verify` items in the portal, and never deliver an unreconciled report.

## Gate 7 — Repeatability (trend)
**Procedure:** Re-run the full sequence against the same scope file into a new dated folder.
**Pass:** Runs are comparable; sensor coverage climbing toward 100% is visible as remediation lands and new DCs are onboarded.
**Fail:** Scope drifted (e.g. DCs added/removed without updating the scope file) — reconcile the inventory each run so the trend is valid.

> These gates test the **assessment**, not the tenant's identity security. A low coverage number with named blind DCs is a *successful* assessment — it found the real gaps. The failure conditions are about the assessment's own accuracy and read-only guarantee.
