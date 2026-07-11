# 2. Requirements Guide — Technical Blocker Mitigation: Defender for Cloud Apps

Verify **every** requirement before diagnosing. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running the MDCA blocker diagnostics**. Objects you create are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Read-only access to the Defender portal and Graph
**Description:** **Security Reader** / **Global Reader** in the Defender portal and consent to the read-only Microsoft Graph scopes (`ThreatHunting.Read.All`, `Policy.Read.All` for Conditional Access reads).
**Why:** The diagnostics read connector/activity signal (`CloudAppEvents`) and Conditional Access App Control policy state — all read-only — to pinpoint the blocker.
**Verify:** Sign in to `security.microsoft.com`; confirm **Cloud apps → App connectors / Cloud discovery** load. `TBMMCA-Discovery.ps1` reports the roles/scopes it resolved.
**Implement-if-missing:** Assign **Security/Global Reader**; grant admin consent to `ThreatHunting.Read.All` and `Policy.Read.All`.

## 2.2 The affected app / connector / policy subset defined
**Description:** A named subset of the apps, connectors, or session policies exhibiting the blocker — the ones you will re-test the fix against before resuming. Name it `MDCA Blocker Triage – Affected Apps – Diagnose`.
**Why:** Fixes are validated on the affected subset first (per `global-requirements-defender.md` G6), in monitor mode, before touching the wider estate.
**Verify:** The list of affected apps/connectors/policies exists; `TBMMCA-Validate.ps1` checks their signal.
**Implement-if-missing:** Document the affected apps/connectors/policies as `MDCA Blocker Triage – Affected Apps – Diagnose`.

## 2.3 Knowledge of the Cloud Discovery source
**Description:** Know how Cloud Discovery is meant to be fed — the automatic **Defender for Endpoint integration**, a **log collector**, a **secure web gateway** feed, or **manual log upload**.
**Why:** "Discovery no-data" is diagnosed differently per source; you cannot fix a feed you have not identified.
**Verify:** `security.microsoft.com` → **Cloud apps → Cloud discovery → Settings**; confirm the intended source. `TBMMCA-Discovery.ps1` reports whether device-based discovery signal is present.
**Implement-if-missing:** Decide/confirm the discovery source with whoever owns it; for MDE-based discovery, confirm endpoints are onboarded to MDE.

## 2.4 The Conditional Access App Control policy identified
**Description:** Know which Entra **Conditional Access** policy is meant to route sessions to the MDCA reverse proxy — e.g. `Use Conditional Access App Control – Pilot Apps – Diagnose` — and which apps/users it targets.
**Why:** Session policies never engage unless a CA policy with the **Conditional Access App Control** session control applies to the session; this is the top session-control blocker.
**Verify:** `entra.microsoft.com` → **Protection → Conditional Access → Policies**; `TBMMCA-ConditionalAccess.ps1` lists policies whose session controls use App Control. *Verify current CA App Control configuration in your tenant.*
**Implement-if-missing:** Identify or plan the CA policy `Use Conditional Access App Control – Pilot Apps – Diagnose` for the fix step.

## 2.5 A test session for session-control verification
**Description:** A pilot user and a browser session you can use to exercise a session-controlled app and confirm the MDCA reverse proxy engages.
**Why:** Session-control verification needs a live session routed through the proxy so you can confirm the inline control applies (or see why it does not).
**Verify:** A pilot user in scope of the CA App Control policy can sign in to the target app in a browser; the session shows the MDCA proxy suffix where applicable.
**Implement-if-missing:** Nominate a pilot user in the affected subset and a test browser. *Verify current session-control behavior in your tenant.*

## 2.6 A place to store the diagnostic output and support bundle
**Description:** A secure location for the JSON snapshots the scripts write and for the support bundle `MDCA Support Bundle – <case> – Escalate`.
**Why:** The before/after snapshots prove the blocker cleared, and the bundle is what you attach to a Microsoft support case.
**Verify:** A working folder exists with least-privilege access; `TBMMCA-Report.ps1` writes there.
**Implement-if-missing:** Create a restricted working folder; do not store tenant/app identifiers in shared/unsecured locations.

---
## Checklist
- [ ] Security/Global Reader + `ThreatHunting.Read.All` + `Policy.Read.All` — `TBMMCA-Discovery.ps1`
- [ ] Affected app/connector/policy subset `MDCA Blocker Triage – Affected Apps – Diagnose` documented
- [ ] Cloud Discovery source known (MDE integration / log collector / SWG / manual)
- [ ] CA App Control policy `Use Conditional Access App Control – Pilot Apps – Diagnose` identified — `TBMMCA-ConditionalAccess.ps1`
- [ ] Test session (pilot user + browser) ready for session-control verification
- [ ] Secure working folder for snapshots and the support bundle
