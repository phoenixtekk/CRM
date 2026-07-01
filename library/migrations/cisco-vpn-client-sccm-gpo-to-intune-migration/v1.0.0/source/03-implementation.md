# 3. Implementation Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Follow these steps **in order**. Inventory (Step 1) runs against the **Configuration Manager console**
(`Software Library → Application Management`) and **Group Policy Management**. Everything on the target
side is in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) and **Microsoft
Entra** (`https://entra.microsoft.com`).

> **Model:** Inventory the SCCM/GPO client + profile + cert delivery, rebuild each in Intune with
> parity, assign to a pilot wave, validate the tunnel, then expand wave by wave — removing each wave
> from the legacy path as it joins Intune — and finally retire the SCCM package and unlink the GPO. The
> pilot wave is the gate; a device is only ever on **one** delivery path at a time (no double-deploy).

> **Vendor boundary:** the Cisco Secure Client installer/switches, the VPN profile XML schema, and the
> head-end (ASA/Firepower) are configured per **Cisco documentation**. Steps below cover Intune/Entra/
> SCCM/GPO/certificate actions at exact detail and reference the Cisco-provided artifacts by role.

## Named objects (reuse these names verbatim everywhere)
We name every object so it is self-describing and searchable.

| Object | Name to create |
|---|---|
| Pilot wave group | `PILOT – VPN Migration Wave 1` |
| Later wave group (example) | `VPN Migration – Wave 2` |
| Intune Win32 app (client) | `Cisco Secure Client – Win32` |
| Intune VPN profile | `Cisco VPN – Profile` |
| Intune SCEP certificate profile | `Cisco VPN – Client Cert (SCEP)` |
| Intune Trusted certificate profile | `Cisco VPN – Trusted Root CA` |

## Step 1 — Assess: inventory the legacy delivery
1. **SCCM:** In the Configuration Manager console, `Software Library → Application Management →
   Applications` (or `Packages`). Identify the Cisco Secure Client app/package, its **deployment**, and
   the **target collection**. Note the install command and content source.
2. **GPO:** In **Group Policy Management**, find the GPO(s) that (a) install the client (software-install
   or startup script), (b) drop the **VPN profile XML**, and (c) auto-enrol the **VPN certificate** (AD
   CS auto-enrolment + template). Record each GPO's **links (OUs)** and **security-group filtering**.
3. **Device-level:** Run `CVPNMIG-Discovery.ps1` on sample devices to capture the installed **client
   version**, the **profile XML** path/content, and the **VPN certificate** (issuer/template/EKUs), and
   to flag whether each artifact came from SCCM or GPO.
4. Confirm you now hold: the Cisco installer + silent command (Req 2.2), the authoritative profile XML
   (Req 2.3), the legacy mechanisms + scope (Req 2.4), and the certificate mapping (Req 2.5).

## Step 2 — Plan waves
1. Group in-scope devices into waves (start small: a pilot wave of representative devices that use the
   VPN daily). Record the wave order.
2. Decide the coexistence rule up front: **each device leaves the SCCM collection and the GPO scope in
   the same change it is added to its Intune wave** (Req 2.7). Never both, per device.

## Step 3 — Create the wave groups
1. Entra → **Groups → New group → Security** → name `PILOT – VPN Migration Wave 1`; add the pilot
   devices. **Create**.
2. Create later wave groups (e.g. `VPN Migration – Wave 2`) as needed. (Or run
   `CVPNMIG-Set-ScopeTargeting.ps1`.)

## Step 4 — Configure: package the client as an Intune Win32 app
1. On a packaging workstation, wrap the **Cisco-provided** Secure Client installer into an
   `.intunewin` with the Microsoft Win32 Content Prep Tool. (Installer switches per Cisco docs.)
2. Intune → **Apps → Windows → Add** → app type `Windows app (Win32)` → **Select**.
3. Upload the `.intunewin`. **App information:** `Name` = `Cisco Secure Client – Win32`; set
   `Publisher` = `Cisco` and a short description. **Next**.
4. **Program:** set the **Install command** and **Uninstall command** from Cisco's silent switches;
   `Install behavior` = `System`. **Next**.
5. **Requirements:** OS architecture `64-bit`, a minimum OS floor. **Next**.
6. **Detection rules:** `Manually configure` → add a rule proving the client is installed (e.g. the
   Secure Client MSI product code, or the client `.exe` file+version, or its uninstall registry key —
   use the evidence captured in Step 1). **Next**.
7. Do **not** assign yet. **Review + create → Create.** (Assignment is Step 8.)

## Step 5 — Configure: deliver the VPN profile
1. Take the authoritative **profile XML** from Step 1 (single source of truth).
2. Deliver it from Intune so it lands in the Secure Client profile directory on the device, named
   `Cisco VPN – Profile`. Two supported approaches (pick one and use it consistently):
   - **Win32/packaged delivery:** wrap the profile XML in a small Win32 app or add it to the client
     package so it is written to the profile directory (the same location the legacy SCCM/GPO delivery
     used — confirm the path from Step 1).
   - **Custom configuration profile:** deliver the profile via **Devices → Configuration → Create →
     Windows → Templates** as a configuration payload that writes the profile.
3. Ensure the delivered XML is **byte-identical** to the legacy profile so an overlap is a no-op.
   (Profile XML schema and any edits are per Cisco docs.) Do **not** assign yet.

## Step 6 — Configure: deliver the VPN certificate
1. Confirm the Intune **Certificate connector** is **Active** (Req 2.5).
2. Create the **Trusted certificate** profile `Cisco VPN – Trusted Root CA`: Intune → **Devices →
   Configuration → Create → Windows → Templates → Trusted certificate** → upload the root/issuing CA.
   Do not assign yet.
3. Create the **SCEP** profile `Cisco VPN – Client Cert (SCEP)`: **Templates → SCEP certificate** →
   set `Certificate type`, `Subject name format` and `SAN` to match the legacy AD CS template intent,
   the correct **EKUs** (e.g. Client Authentication), key usage, and the SCEP URI. Reference the Trusted
   root above. Do not assign yet. (Use **PKCS** instead if that matches your PKI.)

## Step 7 — Bind the certificate to the VPN profile
1. Ensure the `Cisco VPN – Profile` delivery references (or the client is configured to use) the
   certificate issued by `Cisco VPN – Client Cert (SCEP)` for authentication, matching how the legacy
   profile selected its certificate. (Certificate-matching behavior in the profile is per Cisco docs;
   the **certificate delivery** is the Intune SCEP profile above.)

## Step 8 — Pilot: assign the four objects to Wave 1
Assign all four to `PILOT – VPN Migration Wave 1` so a pilot device gets a complete Intune-delivered
VPN:
1. `Cisco Secure Client – Win32` → **Assignments → Required → Add group →** `PILOT – VPN Migration
   Wave 1`.
2. `Cisco VPN – Trusted Root CA` → assign to the wave group.
3. `Cisco VPN – Client Cert (SCEP)` → assign to the wave group.
4. `Cisco VPN – Profile` → assign to the wave group.
5. **Coexistence guard:** the pilot devices are still in the SCCM collection / GPO scope at this moment
   — this is the brief validation overlap only. Because the client version and profile XML match, the
   overlap is a no-op. Proceed straight to validation, then remove them from legacy in Step 10.

## Step 9 — Validate parity on the pilot (gate)
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Run `CVPNMIG-Validation.ps1` to confirm the **Intune-delivered** client version, profile, and
   certificate are present and the **tunnel establishes**. Complete the **Testing Guide**.
3. Run `CVPNMIG-Report.ps1` to confirm the wave shows Intune-managed.
4. **Gate:** the wave passes only when the Intune-delivered client + profile + cert are present and the
   VPN connects. If it fails, fix and re-validate — the legacy path is still live so the VPN never
   drops.

## Step 10 — Cut over Wave 1 (remove from legacy — no double-deploy)
Only after the pilot passes, remove the pilot devices from the **legacy** delivery so the device is on
Intune alone:
1. **SCCM:** remove the pilot devices/collection from the Cisco Secure Client **deployment** (or remove
   them from the target collection). Confirm SCCM no longer targets them.
2. **GPO:** move the pilot devices out of the GPO scope — either remove them from the security group the
   GPO is filtered to, or move their computer objects out of the linked OU. Confirm the client-install,
   profile, and cert-enrolment GPOs no longer apply (`gpresult`).
3. Re-run `CVPNMIG-Discovery.ps1` on a pilot device and confirm the artifacts now show **Intune** as the
   only source (no SCCM/GPO tags).

## Step 11 — Expand: repeat per wave
For each subsequent wave (`VPN Migration – Wave 2`, …):
1. Add the wave group to the four objects' **Assignments** (Steps 8.1–8.4).
2. Validate the wave (Step 9).
3. Cut it over — remove that wave from the SCCM collection and GPO scope (Step 10).
4. Re-run `CVPNMIG-Report.ps1` each cycle to track legacy-vs-Intune coverage; chase laggards with
   `CVPNMIG-Remediation.ps1` (default `-WhatIf`).

## Step 12 — Retire the legacy delivery
Once **all** waves are Intune-managed and validated:
1. **SCCM:** delete/retire the Cisco Secure Client **deployment**, then the package/application and its
   now-empty collection.
2. **GPO:** unlink (then delete, per change control) the GPO(s) that installed the client, dropped the
   profile XML, and auto-enrolled the VPN certificate. Confirm no device still receives them
   (`gpresult`).
3. Run `CVPNMIG-Report.ps1` for a final sweep — **100% Intune-managed, zero legacy artifacts** — and
   spot-check with `CVPNMIG-Discovery.ps1`.

---
### Order of operations
`Inventory SCCM package + GPO(s) + device state → plan waves → wave groups → package client (Win32) →
deliver profile → deliver cert (Trusted root + SCEP) → bind cert to profile → assign pilot (brief
overlap) → validate tunnel → remove pilot from SCCM + GPO (cutover) → expand wave by wave →
retire SCCM package + unlink GPOs`
