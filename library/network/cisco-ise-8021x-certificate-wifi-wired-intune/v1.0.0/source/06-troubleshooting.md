# Troubleshooting

Work the problem in the order of the **three gates** — most authentication failures are actually a
missing certificate (gate 1) or a mis-linked profile (gate 2) surfacing as an ISE reject (gate 3).
Object names below are the exact ones created in *Implementation*.

> **Vendor boundary:** ISE Live Logs, ISE policy, and switch/WLC configuration are on the **Cisco
> side** and are referenced at the architectural level — read the ISE failure reason and the switch
> port state per **Cisco documentation**; this guide does not fabricate ISE/IOS menu paths.

---

## A. No certificate on the device (gate 1)

**Symptom:** `ISE8021X-Validation.ps1` reports no client cert, or the machine **Personal (My)** store
has no Client-Authentication cert.

- **`Cisco 802.1X – SCEP Cert` shows an error in Intune (Device status).** Check the **Certificate
  Connector** health (Tenant administration → Connectors and tokens) — if it is down, no SCEP request
  succeeds. For Cloud PKI, confirm the issuing CA is **Active**.
- **Connector healthy but still no cert.** Verify the **SCEP URL** is reachable from the device and
  the **NDES/SCEP template** matches the profile (key usage, EKU, validity). A template mismatch
  causes silent enrollment failure.
- **Root not present, so the chain can't build.** Confirm `Cisco 802.1X – Trusted Root` deployed
  **first** and is in the machine Root store; the SCEP profile references it under **Root
  certificate**.
- **Wrong device targeting.** Confirm the device is in `PILOT – 802.1X Devices` and the profile
  assignment includes that group.

---

## B. Profile not applied (gate 2)

**Symptom:** cert is present but the Wi-Fi or wired profile is missing / shows an error.

- **Profile shows "Error"/"Conflict" in Intune.** Open **Device status** on the specific profile; a
  **conflict** usually means another Wi-Fi/wired profile targets the same device with different
  settings — remove the conflicting one.
- **Wi-Fi profile applied but SSID never appears.** The **SSID string is case-sensitive** and must
  match the WLC exactly. Re-check `Corp Wi-Fi – EAP-TLS` against the real SSID.
- **Wired profile applied but nothing happens.** Confirm **Wired AutoConfig (dot3svc)** is running
  (`sc query dot3svc`); the wired profile should start it. If stopped, the supplicant never engages
  the port.
- **Platform mismatch.** A Windows wired profile won't apply to a non-Windows device — confirm the
  profile **platform** matches the target OS.
- **Not synced yet.** Force a sync (Company Portal / Settings → Access work or school → Sync) and
  re-check.

---

## C. ISE rejects the authentication (gate 3)

**Symptom:** cert + profiles present, but the device won't get on the network; ISE Live Logs show
**Access-Reject** *(read the ISE reason — Cisco side)*.

- **"Untrusted certificate" / chain not trusted at ISE.** ISE does not trust the **CA that issued the
  device certificate**. The device CA chain must be in **ISE's trusted certificate store** — a
  Cisco-side fix per Cisco docs.
- **Device rejects ISE's server certificate.** The device is missing **ISE's** root — confirm
  `Cisco 802.1X – Trusted Root` is the correct root for ISE's *server/EAP* certificate (not the
  device CA), and that server-name matching (if enabled) matches ISE's actual name.
- **Identity/SAN mismatch.** ISE's **certificate authentication profile** reads a field (CN, SAN-DNS,
  SAN-UPN) that your `Cisco 802.1X – SCEP Cert` does not populate the way ISE expects. Align the
  **Subject/SAN format** (R4) with what ISE reads — coordinate with the ISE admin.
- **EAP-TLS not permitted / wrong policy set.** ISE's policy set for this SSID/port range doesn't
  allow EAP-TLS or lacks an authorization result — Cisco-side policy fix per Cisco docs.
- **Device unknown to ISE as a NAD path.** The **WLC/switch isn't defined in ISE** as a network
  access device, or the **shared RADIUS secret** is wrong — Cisco-side fix.

---

## D. Supplicant issues

- **Windows keeps prompting for a password on the corporate SSID.** The supplicant isn't using
  EAP-TLS / the client cert. Confirm `Corp Wi-Fi – EAP-TLS` sets **EAP type = EAP-TLS** and points at
  `Cisco 802.1X – SCEP Cert`; confirm a matching cert exists in the store it looks in (machine vs
  user).
- **Machine vs user certificate mismatch.** If ISE expects a **machine** cert but the profile presents
  a **user** cert (or vice-versa), it rejects. Match the **certificate type** (Device/User) and the
  profile's **authentication mode** to ISE's policy.
- **Server-name validation failing.** If you enabled trusted **server-name** matching, a mismatch with
  ISE's real certificate name blocks auth — correct the server name(s) in the profile.
- **TPM / key provider errors.** If **Enroll to TPM if present** is set on a device without a working
  TPM, enrollment can fail — allow software KSP fallback or fix the TPM.

---

## E. Wired vs wireless differences (why one works and the other doesn't)

- **Wired needs Wired AutoConfig (dot3svc); Wi-Fi needs WLAN AutoConfig (wlansvc).** These are
  *different* services. Wi-Fi can authenticate while wired does nothing simply because **dot3svc is
  stopped** — start/enforce it via `Wired 802.1X – EAP-TLS`.
- **Different profiles, different fixes.** `Corp Wi-Fi – EAP-TLS` and `Wired 802.1X – EAP-TLS` are
  separate objects; a fix to one does not apply to the other. Validate and troubleshoot each
  independently.
- **The switch port vs the SSID.** Wired auth also depends on **802.1X being enabled on that specific
  switch port** with the right host mode; Wi-Fi depends on the **SSID** being 802.1X-enabled on the
  WLC. A device that authenticates on Wi-Fi but not wired often just hit a **non-802.1X or
  differently-configured switch port** — a Cisco-side check.
- **Order of authentication (machine vs user) can differ** between the wired and Wi-Fi profiles;
  align both with ISE's expected policy.

---

## F. Fast triage checklist

1. Run **`ISE8021X-Validation.ps1`** on the device → is the **cert** present? (gate 1)
2. Are **both** profiles **Succeeded** in Intune, and is **dot3svc** running? (gate 2)
3. In **ISE Live Logs** *(Cisco side)*, is it **Accept** or **Reject** — and what is the **reason**?
   (gate 3)
4. Reject reason points the fix: **untrusted cert** → trust chain (device CA in ISE / ISE root on
   device); **identity mismatch** → SAN/CN vs ISE cert-auth profile; **method not allowed** → ISE
   policy set; **unknown NAD** → WLC/switch RADIUS definition.
5. If only **one transport** fails, compare the Wi-Fi vs wired profile and the service (wlansvc vs
   dot3svc) and the network device (SSID vs switch port).
