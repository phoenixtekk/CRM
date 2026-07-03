# Implementation — Hybrid Identity (Government / GCC High)

Follow these steps in order. Each step names the **exact GCC High portal or endpoint** and, where it
matters, an inline **GCC-High caveat**. Do not skip the gates. If a step says "verify for GCC High,"
Microsoft has not published a definitive statement — validate it in a lab first.

> Before you start: confirm the break-glass accounts `bg-admin1@<yourtenant>.onmicrosoft.us` and
> `bg-admin2@<yourtenant>.onmicrosoft.us` exist and can sign in at
> **`https://login.microsoftonline.us`**. If you lock yourself out during an auth-method change,
> these are how you get back in.

## Stage 1 — Assess

### Step 1.1 Run discovery
On `SVR-ENTRACONNECT01`, run the read-only discovery script:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Discovery.ps1
```

It checks AD health, the Connect host prerequisites, UPN/domain hygiene, and connects to
**Microsoft Graph US Gov** (`-Environment USGov`) to read tenant/domain state. Resolve every failure
before continuing.

### Step 1.2 Confirm the tenant in the Gov portal
Sign in to **`https://entra.microsoft.us`**. Confirm you see **your GCC High tenant** (not a
Commercial tenant). Under `Identity → Settings → Domain names`, confirm your public domain shows
**Verified**.

**GATE:** Discovery clean, break-glass confirmed, correct Gov tenant visible.

## Stage 2 — Configure

### Step 2.1 Choose the sign-in method
All three are available in Azure for US Government
([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)):

- **Password Hash Synchronization (PHS)** — simplest, most resilient; recommended default.
- **Pass-through Authentication (PTA)** — validates passwords on-prem via agents; needs the Gov
  agent endpoints open (R8).
- **Federation (AD FS)** — most complex; only if a hard requirement (e.g. smart-card/PIV at the STS)
  demands it.

**GCC-High caveat:** for PTA and Seamless SSO, the authentication agent must register against the
**US Gov** instance. Verify the agent picks the Gov cloud during install (the `*.microsoftonline.us`
/ `*.gov.us.microsoftonline.com` allow-list from R8 must be open). **Verify for GCC High** with your
specific agent version in a lab before production.

### Step 2.2 Download and start Entra Connect — but stop at the EULA
Download the current **Microsoft Entra Connect** from Microsoft. Start the installer. **When you
reach the first page (the EULA), do not accept it yet** — leave the wizard open.

### Step 2.3 Select the US Government cloud (the critical GCC High step)
This is the step that makes Entra Connect target the sovereign cloud instead of Commercial.

Microsoft supports two mechanisms
([Entra Connect: Sync service instances — Microsoft Azure Government](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)):

1. **Automatic detection (preferred, Connect ≥ 1.1.647.0):** if **`*.windows.net` is open** on your
   proxy, Connect auto-detects the Azure Government tenant. No registry edit is needed.
2. **Manual configuration (when Internet egress from the Connect host is restricted):**
   - With the wizard paused at the EULA, open **`regedit`**.
   - Set `HKLM\SOFTWARE\Microsoft\Azure AD Connect\AzureInstance` to the value **`4`**
     (4 = Azure US Government).
   - Return to the wizard, accept the EULA, and continue using the **Custom** (not Express)
     installation path.

> **Why this matters:** without `*.windows.net` open **and** without `AzureInstance=4`, Connect
> assumes Commercial and its sync engine cannot reach the Gov service instance. Symptom: sign-in /
> connectivity errors at the "Connect to Microsoft Entra ID" page even with correct Gov credentials.

### Step 2.4 Complete the Custom install and connect to the GCC High tenant
Continue the **Custom** path:

- **Connect to Microsoft Entra ID:** sign in with a **Global Administrator of the GCC High tenant**.
  The sign-in prompt should route through **`login.microsoftonline.us`**. If it shows the Commercial
  `login.microsoftonline.com`, stop — cloud selection (Step 2.3) did not take.
- **Connect your directories:** add your on-premises AD forest with an appropriate service account.
- **Sign-in method:** choose the method from Step 2.1 (PHS recommended). Enable **Seamless SSO** if
  desired.
- **Domain and OU filtering:** at first, select **only the pilot OU** (`OU=HybridPilot`) or use
  group filtering with `sg-HybridIdentity-Pilot`. Do **not** sync the whole directory yet.
- **Optional features:** enable **Password writeback** if you will use SSPR writeback (available in
  Azure for US Government).
- **Start the synchronization** and let the initial sync complete.

### Step 2.5 Verify the install targeted Gov
Run:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Validation.ps1
```

It connects with `-Environment USGov` and asserts the tenant, verified domain, sync status, and
sign-in method are consistent with a GCC High deployment.

**GATE:** Connect installed against **US Gov** endpoints, no wrong-cloud detection, initial sync of
the pilot scope succeeded.

## Stage 3 — Pilot

### Step 3.1 Sync a small named scope
Confirm the pilot scope (`OU=HybridPilot` or `sg-HybridIdentity-Pilot`) is the **only** scope in
sync. Use the scope-targeting helper to build/confirm the target group safely:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Set-ScopeTargeting.ps1 -GroupName "sg-HybridIdentity-Pilot"
```

It defaults to **`-WhatIf`** — it shows what it would change and makes no change until you re-run
with `-WhatIf:$false`.

### Step 3.2 Confirm pilot users in the Gov tenant
In **`https://entra.microsoft.us`** → `Users`, confirm the pilot users appear with the correct UPNs
and are **synced from on-premises** (not cloud-only).

**GATE:** Pilot users present in GCC High tenant and able to sign in at `login.microsoftonline.us`.

## Stage 4 — Validate

Run the reporting script and work through `05-testing.md`:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Report.ps1
```

Test: pilot user sign-in, SSPR + password writeback (if enabled), Seamless SSO (if enabled), and —
for PTA/Federation — agent/STS failover. Confirm **no unexpected deletions** occurred (the sync
engine's deletion threshold should have held).

**GATE:** All `05-testing.md` cases pass; no unexpected object deletions.

## Stage 5 — Expand

### Step 5.1 Widen scope in waves
Move from pilot to production in controlled waves using **group-based targeting**
(`sg-HybridIdentity-InScope`). Add each wave's users to the group, let sync run, validate, then
proceed to the next wave. Re-run `HYBIDG-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview each
change.

### Step 5.2 Remediate drift safely
If validation finds drift (e.g. sync disabled, wrong domain, threshold too low), use:

```
powershell -ExecutionPolicy Bypass -File .\HYBIDG-Remediation.ps1
```

It defaults to **`-WhatIf`** and only applies changes when you re-run with `-WhatIf:$false`.

### Step 5.3 Ongoing operations
- Keep **Connect Health** reporting on (available in Azure for US Government) to watch sync health.
- Re-run `HYBIDG-Report.ps1` on a schedule and after any change.
- Keep the Gov endpoint allow-list (R8) current from the monthly
  [GCC High endpoints web service](https://endpoints.office.com/endpoints/USGOVGCCHigh).

**GATE:** Each wave validates before the next; production fully in scope and healthy.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
