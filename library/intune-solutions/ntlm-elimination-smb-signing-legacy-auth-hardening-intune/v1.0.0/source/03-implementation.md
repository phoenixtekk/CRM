# 3. Implementation — NTLM Elimination & SMB Signing (Legacy Auth Hardening)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the steps
below are deliberately short and exact so you can **click to implement**. Throughout, the repeatable
pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against a **pilot
group** first — and **do not skip the audit phase**.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted.

> **This hardens endpoints (client/member side) only.** It audits NTLM, then refuses LM/NTLMv1, enforces
> NTLM SSP session security and SMB signing on both ends, and closes insecure guest logons and
> unauthenticated RPC. It does not touch domain-controller NTLM policy or Kerberos infrastructure.

---

## Phase 1 — Assess (know the fleet before you touch it)

### Step 1. Confirm enrollment, edition, and build
1. Go to **Devices → Windows → Windows devices** and confirm the pilot device is **managed**.
2. Open the device → **Hardware** and confirm Windows 10 **21H2+** or Windows 11, and a **Pro /
   Enterprise / Education** edition (Home/Core lacks some Local Security Options — R2).
3. Run **`NTLMHARD-Discovery.ps1`** from an admin workstation to inventory current posture (existing
   NTLM/SMB policies, edition/build) across the tenant.

### Step 2. Pick the pilot group and identify likely dependencies
1. Confirm your **pilot security group** (Global Requirement G5) contains the pilot user/device (R10).
2. List systems you already suspect use NTLM or unsigned SMB — legacy apps, NAS, scanners/MFPs, backup
   agents (R6). You will confirm and expand this in Phase 2.

---

## Phase 2 — Audit NTLM first (find dependencies before refusing)

> **Do not skip this.** Refusing NTLM blind causes outages. The audit policy reveals every app,
> appliance, and service still using NTLM so you can plan around them.

### Step 3. Create the NTLM audit policy
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **Windows 10 and later**; **Profile type** = **Settings catalog** → **Create**.
3. **Basics → Name:** **`NTLM Audit - Pilot`**. Description, e.g. *Audit-only NTLM usage discovery before
   enforcement.* Click **Next**.
4. On **Configuration settings → Add settings**, search **Local Policies Security Options** and add:
   - **Network Security: Restrict NTLM: Audit NTLM Authentication In This Domain** → **Enable all**
     *(display strings vary — verify in your tenant; the intent is "Audit all")*.
   - **Network Security: Restrict NTLM: Outgoing NTLM Traffic To Remote Servers** → **Audit all**.
5. **Next** through **Scope tags**; **Assignments** → add the **pilot group**; **Review + create** →
   **Create**.

### Step 4. Let it run, then collect NTLM usage
1. Sync the pilot devices (Company Portal → **Sync**, or **Settings → Accounts → Access work or school →
   Info → Sync**).
2. Leave the audit policy in place long enough to capture real usage (a **full business cycle** —
   typically 1–2 weeks — covers month-end jobs, backups, and periodic tasks).
3. On pilot devices, open **Event Viewer → Applications and Services Logs → Microsoft → Windows → NTLM →
   Operational** (R5) and record every source app / target server using NTLM. Where you have central
   collection (WEF / Sentinel / Log Analytics), query fleet-wide instead.
4. Build the **dependency table** (system → protocol → owner → plan) from what you find (R6). For each
   NTLM user: move it to Kerberos (fix SPN/DNS, use FQDN — R8), replace it, or scope it out **before**
   enforcing.

---

## Phase 3 — Configure the hardening policy

### Step 5. Create the Settings Catalog policy
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **Windows 10 and later**; **Profile type** = **Settings catalog** → **Create**.
3. **Basics → Name:** **`NTLM-SMB Hardening - Pilot`**. Description, e.g. *Refuse LM/NTLMv1, require NTLM
   SSP session security + SMB signing (both ends), disable insecure guest logons, restrict
   unauthenticated RPC.* Click **Next**.

### Step 6. Add the seven legacy-auth settings
On **Configuration settings → Add settings**, use the search box to find each control by name. Add and
set each as follows (category → setting → value). **Verify the exact display string in your tenant** —
the stable identity of each control is its registry value, given in parentheses.

**From "Local Policies Security Options":**
1. **Network Security: LAN Manager Authentication Level** → **Send NTLMv2 responses only. Refuse LM &
   NTLM** *(`LmCompatibilityLevel = 5`)*.
2. **Network Security: Minimum Session Security For NTLM SSP Based (Including Secure RPC) Clients** →
   enable **Require NTLMv2 session security** **and** **Require 128-bit encryption**
   *(`NtlmMinClientSec = 0x20080000`)*.
3. **Network Security: Minimum Session Security For NTLM SSP Based (Including Secure RPC) Servers** →
   enable **Require NTLMv2 session security** **and** **Require 128-bit encryption**
   *(`NtlmMinServerSec = 0x20080000`)*.
4. **Microsoft Network Client: Digitally Sign Communications (Always)** → **Enable**
   *(client-side `RequireSecuritySignature = 1`)*.
5. **Microsoft Network Server: Digitally Sign Communications (Always)** → **Enable**
   *(server-side `RequireSecuritySignature = 1`)*.

**From "Administrative Templates → Network → Lanman Workstation":**
6. **Enable Insecure Guest Logons** → **Disabled** *(`AllowInsecureGuestAuth = 0`)*.

**From "Administrative Templates → System → Remote Procedure Call":**
7. **Restrict Unauthenticated RPC Clients** → **Enabled**, RPC Runtime Unauthenticated Client Restriction
   = **Authenticated** *(`RestrictRemoteClients = 1`)*.

> These are the Microsoft-documented Local Security Options / ADMX controls for NTLM and SMB hardening.
> Add only these; leave everything else at default. **Verify current display names and CSP node casing
> in your tenant** — Microsoft occasionally revises them, but the registry values above are the anchor.

### Step 7. Scope tags, assignment, review
1. **Next** through **Scope tags** (set if you use them).
2. **Assignments:** add the **pilot group**. Click **Next**.
3. **Review + create** → **Create**.

> Prefer automation? Use **`NTLMHARD-Remediation.ps1`** (Microsoft Graph) to scaffold the policy and
> **`NTLMHARD-Set-ScopeTargeting.ps1`** to set/adjust the assignment (both default to **-WhatIf** —
> preview first, then re-run to apply), and **`NTLMHARD-Discovery.ps1`** to confirm the settings are
> present.

---

## Phase 4 — Pilot

### Step 8. Push and confirm the policy
1. On the pilot device, force a sync (**Settings → Accounts → Access work or school → Info → Sync**, or
   Company Portal → **Sync**).
2. In Intune → **Devices → Configuration → `NTLM-SMB Hardening - Pilot` → Device status**, confirm the
   pilot device shows **Succeeded**.

### Step 9. Validate real workloads still work
1. From the pilot device, open the file shares, apps, and services users actually use.
2. Confirm SMB access to signing-capable servers/NAS still works (R7); confirm apps that used NTLM now
   authenticate over Kerberos (R8) or were remediated in Phase 2.
3. Re-check the **NTLM Operational** log: with enforcement on, remaining NTLM attempts to weak levels are
   now **refused** — confirm nothing business-critical is failing.

### Step 10. Confirm the hardening is effective
1. On the pilot device confirm the settings applied (Testing, Test 3): `LmCompatibilityLevel = 5`,
   SMB signing required, guest logons disabled, `RestrictRemoteClients = 1`.
2. Confirm a deliberate weak-auth attempt (e.g. an unsigned SMB session or an LM/NTLMv1 client) is now
   **rejected**, while Kerberos/signed-SMB access succeeds.

---

## Phase 5 — Validate and expand

### Step 11. Validate with the scripts
1. Run **`NTLMHARD-Discovery.ps1`** (tenant readiness: the hardening policy is present with the correct
   settings).
2. Run **`NTLMHARD-Validation.ps1`** to confirm the policy is **assigned** to the intended group and the
   pilot device reports the policy **applied**.
3. Run **`NTLMHARD-Report.ps1`** to produce a coverage report (which Windows devices have the hardening
   policy applied).

### Step 12. Remediate gaps (safe by default)
1. If devices are missing or mis-scoped, run **`NTLMHARD-Remediation.ps1`** — it **defaults to `-WhatIf`**
   and prints exactly what it would create/assign. Review, then re-run with `-WhatIf:$false` to apply.

### Step 13. Expand in waves
1. Once the pilot passes (Testing gate) **and** the dependency table (R6) is cleared for the next group,
   broaden the `NTLM-SMB Hardening - Pilot` assignment to the next wave — or make it the standard Windows
   legacy-auth hardening policy for the fleet.
2. Keep the **`NTLM Audit - Pilot`** policy running on newly added waves first, so you catch any
   dependencies unique to that population before enforcing.
3. Roll out in waves, validating each wave with `NTLMHARD-Report.ps1` before widening. Retire the audit
   policy only when a population is fully enforced and stable.

> **Cross-reference, don't duplicate.** For the full Windows hardening baseline (dozens more controls),
> deploy the **CIS Windows 11** and/or **DISA STIG Windows 10/11** solutions. This product deliberately
> owns only the NTLM-elimination + SMB-signing slice so the two do not collide — if you run a full
> baseline that already sets these values, align on one owning policy to avoid a Settings Catalog
> conflict (Troubleshooting).
