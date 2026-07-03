# Troubleshooting — Cloud-First Autopilot Zero-Touch Provisioning (Government / GCC High)

Symptoms and fixes, ordered by how often they bite on a **GCC High / DoD** tenant. Many are
GCC-High-specific (wrong cloud, missing sovereign feature, wrong portal). Run
`CFAPG-Validation.ps1` and `CFAPG-Discovery.ps1` (read-only, `-Environment USGov`) to
gather evidence before changing anything.

> **Portal reminder:** troubleshoot in the `*.us` portals — `https://intune.microsoft.us`,
> `https://entra.microsoft.us` *(verify for GCC High)*, `https://portal.azure.us`.

---

## 1. OOBE completes but the device group is empty and nothing installed

**By far the most common failure.** The device Entra-joins and enrolls, but no apps/scripts
run and `CFAPG-Autopilot-Devices` has no members.

**Cause:** The **Intune Provisioning Client** service principal
(`f1346770-5b25-470b-88bd-d5744ab7952c`) is **not an owner** of the assigned device group,
so **Enrollment Time Grouping** can't add the device.
**Fix:**
1. `CFAPG-Validation.ps1` → confirm the "Provisioning Client OWNS …" check is **FAIL**.
2. `CFAPG-Remediation.ps1` (preview), then `-WhatIf:$false` to add the owner — **or**
   `entra.microsoft.us` → **Groups → `CFAPG-Autopilot-Devices` → Owners → Add owners** →
   add the principal (match by **AppId**, may be named *Intune Autopilot
   ConfidentialClient*).
3. Reset the device and re-provision.

## 2. The device group is Dynamic, not Assigned

**Cause:** `CFAPG-Autopilot-Devices` was created as a **Dynamic** group; Enrollment Time
Grouping requires an **Assigned** group and the owner mechanism does not apply.
**Fix:** Recreate the group as **Assigned** (`03-implementation.md` Step 1), re-add the
Provisioning Client owner (Step 2), point the device preparation profile at it, re-provision.

## 3. "I don't see Windows Autopilot / Deployment Profiles / hardware-hash import"

**Cause:** This is **expected** — **classic Windows Autopilot is not available in GCC
High/DoD** (and there is no plan to add it). You are looking for a Commercial-only surface.
**Fix:** Use **Windows Autopilot device preparation** instead
(`intune.microsoft.us` → **Devices → Windows → Enrollment → Windows Autopilot device
preparation**). Do not import hardware hashes; the user-driven flow does not need them.
(*Confirmed: Microsoft, Intune Government Service overview.*)

## 4. Scripts return nothing / see the "wrong" tenant

**Cause:** The Graph session connected to the **Commercial** cloud, not US Gov.
**Fix:** Always pass **`-Environment USGov`** (or `USGovDoD`). Every script prints
`Environment = …` on connect — confirm it says **USGov**. If it says Global, disconnect
(`Disconnect-MgGraph`) and reconnect with the correct environment. The scripts refuse to
make changes when the environment isn't US Gov.

## 5. Provisioning fails at sign-in / can't reach services

**Cause:** Sovereign endpoints blocked, or **SSL inspection** on `*.manage.microsoft.us`.
**Fix:** Allow (and exempt from SSL inspection) `*.manage.microsoft.us`,
`login.microsoftonline.us`, `enterpriseregistration.microsoftonline.us`,
`graph.microsoft.us`, `login.live.com`, `*.msftconnecttest.com`,
`*.events.data.microsoft.com`, `lgmsapeweu.blob.core.windows.net`, and NTP UDP 123 to
`time.windows.com` (R9). Do **not** paste Commercial `*.manage.microsoft.com` values.

## 6. Device won't provision — unsupported Windows build

**Cause:** Device runs **Windows 10** or a Windows 11 build without **KB5035942**.
**Fix:** Device preparation requires **Windows 11 24H2+** or **22H2/23H2 with KB5035942**
(April 2024 media or later). Re-image/refresh with compliant media (R4). Windows 10 is not
supported for device preparation.

## 7. Self-deploying / pre-provisioning / device-rename options are missing or ignored

**Cause:** These modes are **not yet available in GCC High** (Microsoft lists them as
"planned").
**Fix:** Use **user-driven** deployment; rename devices **after** provisioning. Do not
design kiosk/self-deploying flows on GCC High yet. (*Confirmed: Intune Government Service
overview.*)

## 8. Too many apps during OOBE / low provisioning success rate

**Cause:** Large OOBE app list — Microsoft deliberately limits apps during device-prep OOBE
for stability.
**Fix:** In `CFAPG-DevicePrep-UserDriven-EntraJoin` select only the **essential** apps/
scripts for OOBE; assign the rest to `CFAPG-Autopilot-Devices` for post-provisioning
install. Keep the ESP blocking app list short.

## 9. Windows Hello for Business PIN reset doesn't work

**Cause:** The **Microsoft hosted PIN reset service is not available in Azure Government.**
**Fix:** Configure PIN recovery via allowed sign-in URLs through Intune/CSP/GPO rather than
the hosted service. Validate on a pilot device. *(Verify for GCC High for your exact Windows
build.)*

## 10. Update/servicing policies don't appear or don't apply

**Cause:** You configured **Windows Autopatch** or **Feature/Quality/Expedite/Driver update
policies** — **none are available in GCC High.**
**Fix:** Service via **Update rings for Windows 10 and later**
(`CFAPG-UpdateRing-Pilot`). Remove any dependency on Autopatch or update-policy reports.

## 11. Compliance policy always evaluates non-compliant on an attestation rule

**Cause:** A rule requires **Device Health Attestation** results — **DHA is not available in
GCC High.**
**Fix:** Use locally evaluated rules (BitLocker, Secure Boot, OS build, Defender) in
`CFAPG-Compliance-Win11`; remove DHA-dependent rules.

## 12. Certificate provisioning expected via Cloud PKI

**Cause:** **Cloud PKI is not available in GCC High.**
**Fix:** Use **SCEP/PKCS** with your own PKI/NDES for certificate delivery instead.

## 13. Remote assistance for a stuck device isn't available

**Cause:** **Remote Help is not available in GCC High** (planned).
**Fix:** Use your organization's approved alternative remote-assist tool for
post-provisioning support (document it in your runbook).

## 14. Device was previously a classic Autopilot device elsewhere

**Cause:** If a device is registered/added as a **Windows Autopilot** device, that profile
**takes precedence** over the device preparation policy.
**Fix:** Deregister the device from Windows Autopilot, then re-provision via device
preparation. (*Confirmed: Autopilot device preparation overview.*)

## 15. RBAC admin can't configure device preparation

**Cause:** The role lacks **Enrollment programs → Enrollment time device membership
assignment** (or the Device configurations set).
**Fix:** Confirm `CFAPG Device Preparation Administrator` has exactly the permissions in
`03-implementation.md` Step 4, including **Enrollment time device membership assignment =
Yes**.

---

## Escalation checklist (attach to any support case)

- Output of `CFAPG-Discovery.ps1` and `CFAPG-Validation.ps1` (confirming **USGov**).
- The device group's **membership type** (Assigned) and **Owners** list.
- The device preparation profile mode (**user-driven**) and **join type** (**Entra join**).
- Confirmation the tenant is **GCC High/DoD** (not Commercial/GCC).
- Endpoint/proxy config showing sovereign URLs allowed and `*.manage.microsoft.us` exempt
  from SSL inspection.
- The Windows build on the failing device (`winver`).

## Sources

- Microsoft, *Intune Government Service overview* (not-available/planned features).
- Microsoft, *Overview / requirements of Windows Autopilot device preparation* (Assigned
  group + Provisioning Client owner, Entra-join only, OOBE app limit, Autopilot precedence).
- Microsoft, *Network endpoints for US government deployments* (sovereign endpoints, no SSL
  inspection).
- Microsoft, *Configure Windows Hello for Business* (PIN reset service unavailable in Azure
  Government).
