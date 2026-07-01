# Testing & Validation

Testing is organized around the **three gates** used throughout this solution. A device is not
"done" until all three pass, on **both** Wi-Fi and wired, across representative device types.

> **The three gates:** **(1) cert present** → **(2) profile applied** → **(3) ISE 802.1X auth
> success.** They are ordered — a failure at gate 1 or 2 explains most gate-3 failures, so always
> test in order.

Run the validation from two angles: **per-device** (`ISE8021X-Validation.ps1` on a pilot device) and
**fleet-wide** (`ISE8021X-Report.ps1` against Graph). The Cisco-side confirmation (ISE Live Logs) is
**deferred to the Cisco console** and noted where relevant.

---

## Gate 1 — Certificate present (device identity)

| Check | How to test | Pass | Fail |
| --- | --- | --- | --- |
| Trusted root installed | Machine **Trusted Root Certification Authorities** store (certlm.msc) or `ISE8021X-Validation.ps1` | ISE's issuing root is present | Root missing → Wi-Fi/wired will reject ISE's server cert |
| Client cert issued | Machine **Personal (My)** store | A cert with **Client Authentication** EKU, expected Subject/SAN, chaining to the ISE root | No cert, or wrong EKU/SAN |
| Cert not expired | Inspect validity dates | Valid and not near expiry | Expired/near expiry → renewal not working (see Troubleshooting) |

**Gate 1 pass condition:** trusted root present **and** a valid client cert with Client
Authentication EKU and the ISE-expected Subject/SAN.

---

## Gate 2 — Profiles applied (supplicant configured)

| Check | How to test | Pass | Fail |
| --- | --- | --- | --- |
| `Cisco 802.1X – Trusted Root` | Intune → profile → **Device status**; or `ISE8021X-Validation.ps1` | **Succeeded** on device | Error/pending |
| `Cisco 802.1X – SCEP Cert` | Intune → profile → **Device status** | **Succeeded** | Error → connector/template/SCEP URL issue |
| `Corp Wi-Fi – EAP-TLS` | `netsh wlan show profiles` / Intune status | Corporate SSID profile present, EAP-TLS | Missing profile |
| `Wired 802.1X – EAP-TLS` | `netsh lan show profiles`; **dot3svc** running (`sc query dot3svc`) | Wired profile present, EAP-TLS, Wired AutoConfig running | Missing profile or dot3svc stopped |

**Gate 2 pass condition:** all four Intune objects **Succeeded**, both network profiles present with
**EAP-TLS**, and **Wired AutoConfig (dot3svc)** running for wired.

---

## Gate 3 — ISE 802.1X authentication success (end to end)

| Check | How to test | Pass | Fail |
| --- | --- | --- | --- |
| Wi-Fi association | Connect pilot device to corporate SSID | Associates with **no password prompt** (cert used); has network access | Prompts for password / fails to associate |
| Wired authorization | Plug pilot device into 802.1X-enabled port | Port authorizes; device gets its VLAN/access | Port stays unauthorized / no network |
| ISE verdict *(Cisco side)* | **ISE → Operations → RADIUS → Live Logs** (per Cisco docs) | **Access-Accept**, method **EAP-TLS**, for the device | **Access-Reject** — read the ISE failure reason |

**Gate 3 pass condition:** Wi-Fi **and** wired both authenticate, and ISE Live Logs show
**Access-Accept / EAP-TLS** for the device.

---

## Pilot exit criteria (all must be true before Expand)

- [ ] Gate 1, 2, 3 pass on **multiple** pilot devices.
- [ ] Both **Wi-Fi and wired** authenticate via EAP-TLS.
- [ ] Representative **device types/OS** covered (e.g. Windows laptop + any other in scope).
- [ ] **Certificate renewal** verified (a cert nearing expiry re-enrolls; test by shortening validity
      on a lab device or confirming the renewal threshold).
- [ ] **Rollback** exercised once (remove assignment → device falls back cleanly per plan).
- [ ] ISE Live Logs are clean (no unexpected rejects) across the pilot window.

Only when every box is checked do you widen assignment to the production group (Implementation, Step
8).

---

## Fleet coverage (ongoing)

Run **`ISE8021X-Report.ps1`** to produce a coverage report across the fleet:

- devices with the **client certificate** present,
- devices with **`Corp Wi-Fi – EAP-TLS`** applied,
- devices with **`Wired 802.1X – EAP-TLS`** applied,
- gaps (in the target group but missing a cert or profile).

Coverage gaps are the input to **`ISE8021X-Remediation.ps1`** (which defaults to `-WhatIf`).
