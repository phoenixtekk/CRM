# Diagnostic Workflow

This is the core deliverable: the ordered workflow for a pre-logon VPN incident. It adapts the
category-standard **Assess → Configure → Pilot → Validate → Expand** model to a diagnostic shape:

**Collect → Analyze → Remediate → Verify.**

During an incident, start here. Work it in order — **Collect once**, then **Analyze** the area the
symptom points to with the focused `Check-*` tools, **Remediate** in the owning plane (referencing the
matching deployment product), and **Verify** by re-running the tools until the failing precondition is
clean.

> Names used verbatim (from `01-solution-overview.md` / `02-requirements.md`):
> **`Pre-Logon VPN – Device Tunnel – Profile`**, **`Pre-Logon VPN – SBL Module – Win32`**,
> **`Pre-Logon VPN – SBL – Profile`**, **`Pre-Logon VPN – Trusted Root`**,
> **`Pre-Logon VPN – Device Cert (SCEP)`**, **`PILOT – Pre-Logon VPN Devices`**.

---

## Phase 1 — Collect (always start here)

Run the master collector **once** on the failing device to snapshot every precondition for **both**
mechanisms into one report — so you spend the incident reasoning, not gathering.

```
powershell -ExecutionPolicy Bypass -File .\PLAPDX-Collect-Diagnostics.ps1 -OutFile .\plapdx-report.txt
```

Run it **elevated** (R2) so it can read `LocalMachine\My`, the all-user VPN connections, and the
Credential Providers registry key. The report captures:

- **OS** SKU + build (device tunnel needs Enterprise/Education);
- **Join type** via `dsregcmd /status` (device tunnel needs domain-joined / hybrid-joined);
- **Cisco Secure Client** version (SBL relevance);
- **`vpnplap64.dll`** presence and **PLAP credential-provider registration** (SBL tile);
- the **`UseStartBeforeLogon`** value in the Secure Client VPN profile;
- the **AOVPN device tunnel** (`Get-VpnConnection -AllUserConnection`) and its `DeviceTunnel`/`AlwaysOn`
  flags and tunnel type;
- the **machine certificate** (`LocalMachine\My`: EKU + expiry + private key).

The report ends with a **flagged mechanism and symptom**. Read it, then jump to the matching branch in
**Phase 2**.

**Gate (Collect):** the report wrote successfully and names the intended mechanism's state. If the
device can't run PowerShell elevated, resolve R1/R2 first.

---

## Phase 2 — Analyze (run the focused check for the flagged area)

Pick the branch by **symptom**. Each focused tool prints **PASS/FAIL per precondition** and the exact
remedy for each FAIL.

### Symptom → tool map

| Symptom | Mechanism | Run this tool | Precondition it isolates |
|---|---|---|---|
| The **Network sign-in** / PLAP tile never appears on the logon screen | SBL/PLAP | `PLAPDX-Check-PlapSbl.ps1` | Module installed · `vpnplap64.dll` present · provider registered · `UseStartBeforeLogon=true` |
| Tile appears, but it's a device meant to use the **device tunnel** | Device tunnel | `PLAPDX-Check-DeviceTunnel.ps1` | Wrong mechanism in use — see remediation |
| The **device tunnel never comes up** at boot | Device tunnel | `PLAPDX-Check-DeviceTunnel.ps1` | SKU/join eligible · exactly one device tunnel · IKEv2 · machine cert · AlwaysOn |
| Tunnel/tile is there, but **authentication is rejected** | Either | `PLAPDX-Check-Certificate.ps1` | Cert present · not expired · Client Auth EKU · chains to trusted root · private key |
| A **first-time user can't log on off-network** (no DC reachable) | Either | `PLAPDX-Check-PlapSbl.ps1` **or** `PLAPDX-Check-DeviceTunnel.ps1` | Whichever mechanism should provide the pre-logon path |
| **Nothing works fleet-wide**, or you suspect mis-assignment | Either | `PLAPDX-Check-Intune.ps1` | Objects exist · assigned · **device-tunnel profile on a device group** |

### Branch A — SBL/PLAP tile missing

```
powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-PlapSbl.ps1
```

It checks, in order: is the **Start Before Logon module** installed (Core VPN first), is
**`vpnplap64.dll`** present, is the **PLAP credential provider registered** under
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`, is the Secure
Client **VPN profile present**, and does it carry **`<UseStartBeforeLogon>true</UseStartBeforeLogon>`**.
The first FAIL is almost always the whole reason the tile is missing.

### Branch B — device tunnel won't establish

```
powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-DeviceTunnel.ps1
```

It checks: **OS SKU/join type eligible** (Enterprise/Education + domain/hybrid-joined), **exactly one**
device tunnel exists, it is **IKEv2**, it carries **`DeviceTunnel=true`/`AlwaysOn=true`**, and a valid
**machine certificate** backs it. More than one device tunnel, a non-IKEv2 type, or a user-context
profile are the usual causes.

### Branch C — authentication rejected (certificate deep-check)

```
powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-Certificate.ps1 -CaThumbprint <expected-issuing-CA-thumbprint>
```

It reports, for each candidate machine certificate: **present**, **not expired**, **Client
Authentication EKU present**, **chains to a trusted root**, **private key present**, and — if you pass
`-CaThumbprint` — whether it was issued by the **expected CA**. A cert that passes device-side but is
still rejected points at the gateway's CA trust (R7, vendor-deferred).

### Branch D — Intune object / scoping audit

```
powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-Intune.ps1
```

It confirms the expected objects exist and are assigned to `PILOT – Pre-Logon VPN Devices`, and flags
the classic mis-scope: a **device-tunnel profile assigned to a user group** (it must target a
**device** group, because the device tunnel has no user at connect time). Read-only Graph scopes only.

**Gate (Analyze):** the flagged tool reports a specific **FAIL** with a named remedy (or all PASS —
in which case the fault is at the gateway/service, R7). Do not guess past a FAIL; fix it and re-check.

---

## Phase 3 — Remediate (in the owning plane)

The toolkit is **read-only** — it never changes the device, tenant, or gateway. Apply the indicated
fix in the plane that owns it, using the matching **deployment** product for the exact click-by-click
steps. Typical remedies by finding:

| Finding | Where to fix | Typical remedy |
|---|---|---|
| SBL module not installed | Intune (app) | Deploy `Pre-Logon VPN – SBL Module – Win32` (Core VPN first) to the device group |
| `UseStartBeforeLogon` not set | Intune (VPN profile) | Set `<UseStartBeforeLogon>true</UseStartBeforeLogon>` in `Pre-Logon VPN – SBL – Profile` and re-push |
| PLAP provider not registered | Device | Repair/reinstall the SBL module so `vpnplap64.dll` registers |
| Wrong OS SKU / join type (device tunnel) | Device / provisioning | Move to Enterprise/Education + domain/hybrid join, or use SBL instead |
| More than one device tunnel | Device (management plane) | Remove the extra device tunnel; only one is allowed |
| Non-IKEv2 device tunnel | Intune (ProfileXML) | Reissue `Pre-Logon VPN – Device Tunnel – Profile` as IKEv2 |
| Machine cert missing / wrong EKU / expired | Intune (cert) | Fix `Pre-Logon VPN – Device Cert (SCEP)` (Client Auth EKU, renewal) after the trusted root |
| Issuing CA not trusted by the gateway | Gateway (vendor) | Add the issuing CA to the head-end trust store — **deferred to vendor docs** |
| Device-tunnel profile on a user group | Intune (assignment) | Re-assign `Pre-Logon VPN – Device Tunnel – Profile` to a **device** group |

Because several of these touch outward-facing/shared services (the issuing CA, the gateway, broadly
assigned profiles), remediate under **change control** — see `07-best-practices.md`.

---

## Phase 4 — Verify (re-run until clean)

After a fix, **re-run the focused tool** for the branch you worked, then re-run the collector to prove
the whole picture is clean and no new gap opened:

```
powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-PlapSbl.ps1        # or -DeviceTunnel / -Certificate
powershell -ExecutionPolicy Bypass -File .\PLAPDX-Collect-Diagnostics.ps1  # confirm the full picture
```

Then prove it **on the logon screen / at boot**: reboot the device and confirm the **Network sign-in**
tile appears (SBL) or the **device tunnel connects before logon** (device tunnel), and that a
first-time user can sign in off-network. Confirm each gate in `05-testing.md`.

**Gate (Verify):** the failing precondition now PASSes, the collector shows no other FAIL, and the
device demonstrably brings up pre-logon connectivity. Only then is the incident closed. Record the
root-cause precondition on the ticket (see `07-best-practices.md`, closing the loop).
