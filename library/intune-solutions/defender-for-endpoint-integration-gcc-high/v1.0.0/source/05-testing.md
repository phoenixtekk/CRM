# 5. Testing Guide — Microsoft Defender for Endpoint Integration (Government / GCC High)

Work through every test below on the **pilot** before you expand. Each test has an explicit
**Pass / Fail** gate. All portal checks use the **`.us`** (GCC High) portals; all script checks use
the included **US Gov Graph** scripts (`-Environment USGov`).

> **Do not expand** (`03-implementation.md` Step 9) until **every** test here passes on
> **`SG-MDE-Pilot`**.

---

## T1. Connector is Active (Gov-to-Gov)
**Do:** In **`intune.microsoft.us`** → **Endpoint security → Microsoft Defender for Endpoint**, read
**Connection status**. Then run **`MDEG-Validation.ps1`** and read the connector line.
**Pass:** Portal shows **Available / Active**; the script reports the Intune↔MDE connector enabled.
**Fail:** *Unavailable* / disabled → re-check Step 1 was done in **`security.microsoft.us`** (not
`.com`), and that `*.microsoft.us` is not blocked (`02-requirements.md` R6).

## T2. Pilot device is onboarded to the US Gov MDE service
**Do:** On a pilot device run **`MDEG-Discovery.ps1`**, then **`MDEG-Validation.ps1`**.
**Pass:** The device reports **onboarded** and the sensor **running/healthy**, and the onboarding
**environment resolves to US Government** (Gov service URLs, not Commercial).
**Fail:** Not onboarded → confirm the EDR policy (`MDE - EDR Onboarding - Pilot`) is assigned to
`SG-MDE-Pilot` and the device has synced. Onboarded but pointing at Commercial endpoints → the
package was not **Auto from connector**, or a required pre-onboarding KB was missing on a downlevel
build (`02-requirements.md` R7).

## T3. Device appears in the GCC High Defender portal
**Do:** In **`security.microsoft.us`** → **Assets → Devices**, find the pilot device.
**Pass:** The device is listed with a health state and a **risk level**.
**Fail:** Absent after allowing time to check in → sensor cannot reach the **Gov** service endpoints
(R6), or you are viewing the Commercial portal (`security.microsoft.com`).

## T4. Risk score flows into Intune compliance
**Do:** Run **`MDEG-Report.ps1`**. Cross-check in `intune.microsoft.us` → **Devices → Compliance →**
`CP-Windows-MDE-Risk` → device status.
**Pass:** The pilot device shows a machine **risk score**, and its Intune **compliance state**
reflects the `CP-Windows-MDE-Risk` threshold (at/under = Compliant; above = Noncompliant).
**Fail:** No risk score in Intune → the risk setting isn't wired (Step 6) or the connector isn't
active (T1).

## T5. Risk-to-noncompliance reaction (controlled test)
**Do:** On a pilot device, generate a benign MDE detection using Microsoft's guidance (do **not** use
real malware), then re-run **`MDEG-Report.ps1`** and watch the compliance state.
**Pass:** MDE raises the device risk above your threshold and Intune flips the device to
**Noncompliant** within the expected interval.
**Fail:** Risk rises but compliance does not change → threshold in `CP-Windows-MDE-Risk` is too
permissive, or the compliance policy isn't assigned to the pilot population.

## T6. Conditional Access enforcement (if configured)
**Do:** With `CA-Require-Compliant-MDE` enabled (out of Report-only), attempt access from the
device made noncompliant in T5.
**Pass:** Access to the targeted resource is **blocked** while the device is Noncompliant; access
restores after remediation returns the device to Compliant.
**Fail:** Access still granted → CA policy is Report-only, not scoped to the test user/app, or the
device didn't reach Noncompliant (T5).

## T7. Scripts run cleanly against US Gov Graph
**Do:** Run each of **`MDEG-Discovery.ps1`**, **`MDEG-Validation.ps1`**, **`MDEG-Report.ps1`**.
**Pass:** Each connects with **`-Environment USGov`**, returns your tenant's data, and produces no
authority/endpoint errors.
**Fail:** Empty results or a Commercial-authority error → the session connected to the Commercial
cloud; reconnect with `-Environment USGov` (the scripts do this by default — see
`06-troubleshooting.md`).

## T8. Parity expectations confirmed for this tenant
**Do:** Open `gcc-high-parity-notes.md`. For each feature your rollout depends on, confirm in
`security.microsoft.us` that it is actually present in **your** GCC High/DoD tenant.
**Pass:** Every feature your design relies on is available (or you have a documented manual
playbook for the gap).
**Fail:** A relied-upon feature is absent (e.g. Microsoft Threat Experts) → adjust the design and
flag it; **verify for GCC High/DoD**.

---
### Testing gate summary
| Test | Gate |
| --- | --- |
| T1 Connector Active | Available/Active in `intune.microsoft.us` + script |
| T2 Device onboarded (Gov) | Onboarded + healthy + US Gov environment |
| T3 Device in Defender portal | Listed in `security.microsoft.us` with risk level |
| T4 Risk → compliance | Risk score visible; compliance reflects threshold |
| T5 Risk → noncompliance | Device flips Noncompliant on elevated risk |
| T6 CA enforcement | Noncompliant device blocked (if CA configured) |
| T7 Scripts vs US Gov Graph | Clean `-Environment USGov` runs, tenant data returned |
| T8 Parity confirmed | Relied-upon features present or playbooked |

*Sources: Microsoft Learn — Intune/Defender integration and US Government customers pages. Verify
GCC High / DoD specifics in your tenant.*
