# 6. Troubleshooting — Microsoft Defender for Endpoint Integration (Government / GCC High)

Symptoms and fixes specific to running the integration on **GCC High**. Most GCC High problems trace
back to one root cause: **something is pointed at the Commercial cloud instead of the US sovereign
cloud.** Check that first.

> **Golden rule:** if a portal, script, or device "can't see the tenant / the feature is missing,"
> confirm you are on a **`.us`** host / `-Environment USGov` / a **Gov** service endpoint before
> anything else.

---

## A. Connector never becomes Active
**Symptoms:** In `intune.microsoft.us` → Endpoint security → Microsoft Defender for Endpoint,
**Connection status** stays *Unavailable*.
**Likely causes & fixes:**
1. **Toggle set in the wrong portal.** You must enable **Microsoft Intune connection** in
   **`security.microsoft.us`** (GCC High Defender portal) → **Settings → Endpoints → Advanced
   features**. If you set it in `security.microsoft.com`, it affects a Commercial tenant. Re-do in
   `.us`.
2. **`*.microsoft.us` blocked.** Filtering is dropping the sovereign endpoints. Allow the Gov/GCC/DoD
   URLs (`02-requirements.md` R6) and re-check.
3. **Propagation delay.** Wait a few minutes and select **Refresh**.
**Verify fixed:** `MDEG-Validation.ps1` reports the connector enabled and portal shows
**Available/Active**.

## B. Device onboarded but pointing at the wrong cloud
**Symptoms:** Device shows onboarded locally but never appears in `security.microsoft.us`, or appears
in the Commercial portal.
**Likely causes & fixes:**
1. **Manual Commercial onboarding package.** The EDR policy used a pasted package sourced from the
   Commercial cloud. Recreate the policy with **Configuration package type = Auto from connector**
   (`03-implementation.md` Step 4) so the **Gov** endpoints are baked in.
2. **Downlevel device missing the pre-onboarding KB.** On some downlevel Windows 10 builds the
   required KB must be deployed **before** onboarding so the sensor registers to the Gov environment.
   Offboard, deploy the KB, re-onboard. Cited: Microsoft — Endpoint versions.
3. **MMA server on Commercial cloud.** Reinstall/reconfigure the agent selecting **Azure US
   Government** (or `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`).
**Verify fixed:** `MDEG-Validation.ps1` resolves the onboarding environment to **US Government** and
the device appears in `security.microsoft.us`.

## C. Sensor unhealthy / not reporting
**Symptoms:** Device present but sensor state is *Inactive*/*Misconfigured*, or risk never updates.
**Likely causes & fixes:**
1. **Gov service endpoints blocked** after a network change — re-apply the streamlined/standard
   Gov/GCC/DoD URL allow-list.
2. **Time/certificate issues** on the device preventing TLS to `*.microsoft.us`.
3. **Proxy not honoring the device's system context** — MDE uses the system account; ensure the
   proxy config applies system-wide.
**Verify fixed:** `MDEG-Validation.ps1` shows the sensor healthy and last-seen recent.

## D. Risk score not flowing into Intune compliance
**Symptoms:** Device is in the Defender portal with a risk level, but Intune compliance shows no MDE
risk.
**Likely causes & fixes:**
1. **Risk not wired into the policy.** In `CP-Windows-MDE-Risk` set **Require the device to be at or
   under the machine risk score** (`03-implementation.md` Step 6).
2. **Connector not active** (see A).
3. **Compliance policy not assigned** to the device's group (`SG-MDE-Pilot` / `SG-MDE-Prod-Wave1`).
**Verify fixed:** `MDEG-Report.ps1` shows the device with a risk score and the expected compliance
state.

## E. Conditional Access not blocking a noncompliant device
**Symptoms:** A device is Noncompliant but still reaches resources.
**Likely causes & fixes:**
1. **CA policy in Report-only.** Move `CA-Require-Compliant-MDE` to **On** once validated.
2. **Scope mismatch** — the test user/app isn't in the policy's assignment.
3. **Grant control** isn't **Require device to be marked as compliant**.
**Verify fixed:** T6 in `05-testing.md` passes.

## F. Scripts return nothing / authority errors
**Symptoms:** `MDEG-*` scripts run but return empty results, or throw an authentication/authority
error.
**Likely causes & fixes:**
1. **Connected to the Commercial cloud.** The Graph session must use **`-Environment USGov`**. The
   included scripts default to this — if you customized them, restore it. Run
   `Disconnect-MgGraph` then re-run the script so it reconnects to US Gov.
2. **Wrong module version.** Ensure a current **Microsoft.Graph** module is installed
   (`Install-Module Microsoft.Graph`).
3. **Missing scopes/consent.** Re-consent the delegated scopes the script requests when prompted.
**Verify fixed:** `MDEG-Discovery.ps1` returns your tenant's devices with no authority error.

## G. "The feature isn't there" (parity, not a bug)
**Symptoms:** A capability shown in Commercial docs (e.g. Microsoft Threat Experts, enterprise IoT
security, some Secure Score recommendations, certain analytics/reporting) is missing in
`security.microsoft.us`.
**Likely cause & fix:** This is **expected parity behavior**, not a fault. GCC High/DoD lack some
capabilities and lag others. Consult `gcc-high-parity-notes.md`, confirm availability for your tenant,
and use a documented manual playbook for the gap. **Flag "verify for GCC High/DoD"** on anything
unconfirmed; do not assume Commercial behavior. Cited: Microsoft — Feature parity with commercial.

---
### Fast triage checklist
- [ ] Every portal URL ends in **`.us`** (GCC High).
- [ ] Every script session used **`-Environment USGov`**.
- [ ] EDR package is **Auto from connector** (Gov endpoints baked in).
- [ ] Gov/GCC/DoD connectivity URLs allowed through filtering.
- [ ] Downlevel devices patched **before** onboarding; MMA set to **Azure US Government**.
- [ ] Risk wired into `CP-Windows-MDE-Risk`; connector **Active**.
- [ ] Missing feature checked against `gcc-high-parity-notes.md` (parity, not a bug).

*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"; Intune ↔
Defender integration pages. Verify GCC High / DoD specifics in your tenant.*
