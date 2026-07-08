# Implementation — Windows Always On VPN — Device Tunnel Before User Logon (IKEv2, Machine-Certificate Auth) via Intune

This is the ordered, click-by-click build. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Do **not** skip the pilot — the device tunnel
touches the pre-logon boot path. Use the **exact object names** shown — later steps, tests,
troubleshooting, and scripts reference them verbatim.

> **Vendor boundary:** the VPN gateway head-end (**RRAS** or **Azure VPN Gateway**) — its IKEv2
> parameters, address pool/routes, the CA it trusts, and the server certificate it presents — is
> **deferred to Microsoft's official documentation**. This guide covers the Intune, Entra, and
> Windows/PKI side at full detail and *consumes* the head-end's gateway address/FQDN, IKEv2 settings,
> and CA trust as inputs.

## Object naming convention (use verbatim)

| Object | Name |
|---|---|
| Pilot DEVICE group | `PILOT – AOVPN Device Tunnel – Devices` |
| Production DEVICE group | `PROD – AOVPN Device Tunnel – Devices` |
| Custom OMA-URI ProfileXML profile | `AOVPN – Device Tunnel – ProfileXML – Windows` |
| VPN profile name inside the XML / OMA-URI path segment | `AOVPN Device Tunnel` |
| Trusted Root CA profile | `AOVPN – Device Tunnel – Trusted Root CA – Windows` |
| SCEP machine certificate profile | `AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows` |
| Assignment filter (optional) | `Filter – AOVPN Device Tunnel – Windows` |

> **The one rule that matters most:** the ProfileXML is pushed on the **`./Device/`** OMA-URI path, so
> it runs in **device/SYSTEM context** and **must be assigned to a DEVICE group**
> (`PILOT – AOVPN Device Tunnel – Devices`), **never a user group**. Assigning it to a user group is
> the single most common reason the device tunnel never appears (see `06-troubleshooting.md`).

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Gather the head-end inputs (from your network team, per Microsoft docs):
   - **Gateway external address / FQDN** (e.g. `vpn.your-company.com`)
   - Confirmation that **IKEv2** and **machine-certificate** auth are enabled for the **device tunnel**
   - The **root/issuing CA** the head-end trusts, and that the gateway presents a valid **server
     certificate** (R6)
   - The **routes / subnets** the device tunnel should carry (typically DC/management only) and any
     **DNS suffix / NRPT** rules (R7)
3. Confirm the pilot devices are **Enterprise/Education, 1709+, domain-joined or hybrid-joined** (R2).
4. Decide the pilot audience (3–10 **devices**, at least one that a *brand-new* user can test a
   first-logon on).
5. Run the discovery script to baseline readiness:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVDT-Discovery.ps1`
   Review its readiness table before building anything.

**Gate A (Assess):** All requirements pass, all head-end inputs recorded, pilot devices confirmed
Enterprise/Education + domain/hybrid-joined, and discovery shows the tenant is ready (PKI/connector
healthy). If not, stop and remediate.

---

# Phase 2 — Configure

## 2.0 Create the target DEVICE groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\AOVDT-Set-ScopeTargeting.ps1 -PilotDevices DEVICE01,DEVICE02`
  (creates `PILOT – AOVPN Device Tunnel – Devices` and adds the **device** objects you name).
- **Portal:** Entra admin center (`https://entra.microsoft.com`) → **Identity > Groups > All groups >
  New group** → **Group type: Security** → **Group name:** `PILOT – AOVPN Device Tunnel – Devices` →
  add the pilot **devices** under **Members** (search device display names) → **Create**. Repeat for
  `PROD – AOVPN Device Tunnel – Devices`.

> These are **device** groups (members are devices, not users), because the ProfileXML deploys in
> device context.

## Phase 2 — Certificate lifecycle for the device tunnel (machine certificate via SCEP/PKCS)

**Do this before the ProfileXML.** The device tunnel authenticates with a **machine certificate in
`LocalMachine\My`** — there is no user at boot, so a **device** certificate must already exist when
the tunnel tries to connect. If the certificate is missing, the wrong EKU, or issued by a CA the
head-end does not trust, the tunnel will never authenticate no matter how correct the ProfileXML is.

### 2.1 Deploy the Trusted Root CA profile (first)

1. Intune admin center → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*. **Profile type:** *Templates* → **Trusted certificate** →
   **Create**.
3. **Name:** `AOVPN – Device Tunnel – Trusted Root CA – Windows`. Add a description. **Next.**
4. **Configuration settings:** upload the **root (and intermediate, as a second profile if needed)**
   CA `.cer` from R5; **Destination store:** *Computer certificate store – Root* (for intermediates,
   *Computer certificate store – Intermediate*). **Next.**
5. **Assignments:** add `PILOT – AOVPN Device Tunnel – Devices`. **Next > Review + create > Create.**

> Deploy the trusted root **before** the SCEP profile so the device already trusts the chain when its
> machine certificate is issued.

### 2.2 Deploy the SCEP machine-certificate profile

1. Intune admin center → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*. **Profile type:** *Templates* → **SCEP certificate** →
   **Create**. (Use **PKCS certificate** instead if your PKI uses PKCS — the field intent is the same.)
3. **Name:** `AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows`. Add a description. **Next.**
4. **Configuration settings:**
   - **Certificate type:** **Device** (this is what puts the certificate in `LocalMachine\My` with no
     user — critical for the device tunnel).
   - **Subject name format:** e.g. `CN={{DeviceName}}` (or the format your head-end matches on).
   - **Subject alternative name:** add a **DNS** SAN of `{{FullyQualifiedDomainName}}` (or the value
     your head-end expects).
   - **Certificate validity period:** per your PKI policy.
   - **Key storage provider (KSP):** *Enroll to Trusted Platform Module (TPM) KSP if present,
     otherwise Software KSP*.
   - **Key usage:** *Digital signature* and *Key encipherment*.
   - **Extended key usage:** add **Client Authentication** (`1.3.6.1.5.5.7.3.2`) — the device tunnel
     requires it.
   - **Root Certificate:** click **Root Certificate**, choose the
     `AOVPN – Device Tunnel – Trusted Root CA – Windows` profile from 2.1.
   - **SCEP Server URLs:** the SCEP/NDES (or Cloud PKI) enrollment URL(s) from R4.
   - **Renewal threshold (%):** set comfortably ahead of expiry (e.g. **20%**) so the certificate
     renews **before** it lapses and the tunnel never loses authentication.
5. **Assignments:** add `PILOT – AOVPN Device Tunnel – Devices`. **Next > Review + create > Create.**

> **Head-end trust (deferred to Microsoft docs):** the VPN gateway must **trust the issuing CA** and
> **present its own server certificate** (R6) with **Server Authentication** EKU whose subject matches
> the gateway address/FQDN. That trust/server-cert configuration is done on the RRAS / Azure VPN
> Gateway side **per Microsoft's official documentation** — this solution ensures the device holds the
> right client certificate and trusts the right root.

**Gate B-cert (Certificate):** On a pilot device, `AOVPN – Device Tunnel – Trusted Root CA – Windows`
and `AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows` both show *Succeeded* in Intune, and a
certificate with **Client Authentication** EKU is present in `Cert:\LocalMachine\My`. If not, resolve
before deploying the ProfileXML.

## 2.3 Author the ProfileXML

Author the device-tunnel **ProfileXML** (per Microsoft's Always On VPN ProfileXML reference). The
device-tunnel-defining elements are:

- `<AlwaysOn>true</AlwaysOn>` and `<DeviceTunnel>true</DeviceTunnel>` — this is what makes it the
  boot-time device tunnel (the Intune VPN *template* cannot set `DeviceTunnel`).
- `<NativeProfile>` with `<Servers>` = the gateway address/FQDN (R7) and
  `<NativeProtocolType>IKEv2</NativeProtocolType>` — **IKEv2 only, no SSTP fallback**.
- `<Authentication>` = **machine certificate** (the device presents its `LocalMachine\My` cert; no
  user credential).
- **Routes / traffic filters** — the subnets the device tunnel carries (keep minimal: DC/management),
  and where **trusted network detection** (`<TrustedNetworkDetection>` DNS suffixes) and **DNS
  (NRPT)** rules go. The exact route values come from R7 / the head-end (deferred to Microsoft docs);
  the ProfileXML is *where they live*.

Keep the authored XML on a single line (or escape it) for the OMA-URI value in 2.4. The **VPN profile
name inside the XML / OMA-URI path segment is `AOVPN Device Tunnel`** — use it verbatim.

## 2.4 Build the Custom OMA-URI ProfileXML profile (primary deployment path)

1. Intune admin center → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*. **Profile type:** *Templates* → **Custom** → **Create**.
3. **Name:** `AOVPN – Device Tunnel – ProfileXML – Windows`. Add a description. **Next.**
4. **Configuration settings → Add** an OMA-URI setting:
   - **Name:** `AOVPN Device Tunnel ProfileXML`
   - **OMA-URI:** `./Device/Vendor/MSFT/VPNv2/AOVPN Device Tunnel/ProfileXML`
     (the path segment `AOVPN Device Tunnel` is the VPN profile name; keep it identical everywhere).
   - **Data type:** **String**.
   - **Value:** paste the ProfileXML authored in 2.3.
   - **Save.**
5. **Assignments:** add **`PILOT – AOVPN Device Tunnel – Devices`** (a **DEVICE** group — because the
   OMA-URI is on the **`./Device/`** path). Optionally attach `Filter – AOVPN Device Tunnel – Windows`.
   **Next > Review + create > Create.**

> **Do not** assign this Custom profile to a user group. The `./Device/` path is device/SYSTEM context;
> a user-group assignment silently does nothing at the machine level, and the device tunnel never
> appears.

### (Reference only) The equivalent built-in VPN template fields

Intune's **Windows 10 and later > Templates > VPN** profile can set **Connection type = IKEv2**,
**Always On = Enable**, and **Authentication method = Machine certificates** — useful to understand the
equivalent settings — but it **cannot set the `DeviceTunnel` flag**. Deploy the device tunnel through
the Custom OMA-URI ProfileXML above; the template is not a substitute.

**Gate B (Configure):** The Trusted Root CA profile, the SCEP machine-certificate profile, and the
Custom OMA-URI ProfileXML profile all exist, are named to convention, and are assigned to
`PILOT – AOVPN Device Tunnel – Devices`. Re-run `AOVDT-Discovery.ps1` — every expected object should
now be found and assigned to the **device** group.

---

# Phase 3 — Pilot

1. Ensure the pilot **devices** are enrolled, compliant, Enterprise/Education + domain/hybrid-joined,
   and members of `PILOT – AOVPN Device Tunnel – Devices`.
2. Trigger a sync (Intune → **Devices > (device) > Sync**, or on the device **Settings > Accounts >
   Access work or school > Info > Sync**) to pull the certificate profiles and the ProfileXML.
3. Allow time for the certificate to issue (`LocalMachine\My`) and the VPNv2 profile to apply.
4. **Reboot** the pilot device so the device tunnel establishes at boot.

**Gate C (Pilot):** Every pilot device shows the two certificate profiles and the Custom ProfileXML
profile *Succeeded* in Intune monitoring, and the machine certificate is present. If any fail, go to
`06-troubleshooting.md` before proceeding.

---

# Phase 4 — Validate

1. On a pilot device, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVDT-Validation.ps1`
   It confirms the `AOVPN Device Tunnel` profile is present and a valid machine certificate exists on
   *this* device.
2. Perform the **decisive pre-logon test** in `05-testing.md`: **reboot the device and, at the Windows
   logon screen with no user signed in**, confirm the device tunnel is up and a domain controller is
   reachable (e.g. `Get-VpnConnection -AllUserConnection` shows `AOVPN Device Tunnel` *Connected*, and
   a DC/internal host is reachable before any user logs on).
3. Run the fleet report to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVDT-Report.ps1`

**Gate D (Validate):** On every pilot device, both certificate profiles and the ProfileXML apply, and
the **device tunnel is Connected at the logon screen before user sign-in** with a domain controller
reachable. All Testing guide pass/fail gates are green. Only then proceed.

---

# Phase 5 — Expand

1. For the two certificate profiles and the Custom ProfileXML profile, **add**
   `PROD – AOVPN Device Tunnel – Devices` to the **Assignments**. Keep
   `PILOT – AOVPN Device Tunnel – Devices` assigned (pilot devices stay covered).
2. Expand in waves if the fleet is large (add production sub-groups of devices over several days) and
   watch the report between waves.
3. Monitor with `AOVDT-Report.ps1` for coverage and with Intune **Devices > Configuration** for
   profile success.
4. Remediate stragglers with `AOVDT-Remediation.ps1` (defaults to **-WhatIf** preview — review, then
   re-run with `-WhatIf:$false` to act).

**Rollback (any phase):** Remove `PILOT`/`PROD – AOVPN Device Tunnel – Devices` from the ProfileXML
and certificate profile **Assignments**; to actively remove the tunnel, push a Custom profile that
removes the `AOVPN Device Tunnel` VPNv2 profile. Because it is a pre-logon path, test the rollback on a
disposable device first (Testing T8).

**Gate E (Expand):** Fleet coverage meets your target (e.g. ≥ 95% of assigned devices with both
certificate profiles and the ProfileXML *Succeeded* and the device tunnel connecting pre-logon);
remaining failures are triaged. Deployment is complete.
