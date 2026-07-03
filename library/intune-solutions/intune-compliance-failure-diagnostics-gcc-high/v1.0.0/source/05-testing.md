# 5. Testing Guide — Compliance-Failure Diagnostics (Government / GCC High)

Every test uses the **`*.us`** portals and US Gov Graph. A test only **passes** when the evidence is
visible in **`intune.microsoft.us`** (and, for Conditional Access, `portal.azure.us`) — not just in a
script's output. Run these on a **pilot device** before expanding any fix.

> Connect scripts with `Connect-MgGraph -Environment USGov` (DoD: `-Environment USGovDoD`).

## Test 1 — You are in the correct (sovereign) cloud
- **Do:** open **`https://intune.microsoft.us`** and confirm your tenant loads. In PowerShell run
  `Connect-MgGraph -Environment USGov -Scopes "DeviceManagementManagedDevices.Read.All"` and then
  `(Get-MgContext).Environment`.
- **Pass:** portal is `intune.microsoft.us` (not `.com`) **and** `(Get-MgContext).Environment` returns
  **USGov** (or **USGovDoD**).
- **Fail:** any `.com` portal, or `Get-MgContext` shows `Global` → you're querying the Commercial
  cloud; reconnect with `-Environment USGov`.

## Test 2 — Endpoint reachability and no TLS interception
- **Do:** from a pilot device, confirm reachability of **`*.manage.microsoft.us`**,
  **`login.microsoftonline.us`**, and (if using Defender/EPM) **`*.dm.microsoft.us`**. Confirm the
  proxy is **not** SSL-inspecting `*.manage.microsoft.us` / `*.dm.microsoft.us`.
- **Pass:** endpoints reachable on 80/443 and the device's **Last check-in** in `intune.microsoft.us`
  is recent (minutes, not days).
- **Fail:** endpoints blocked or TLS intercepted → device stalls at **Not evaluated** (fix per section
  2, R5).

## Test 3 — Discovery snapshot is accurate
- **Do:** run **`INTCOMPDXG-Discovery.ps1`** against a known-failing device.
- **Pass:** the script reports the same failing policy/setting that `intune.microsoft.us` → device →
  **Device compliance** shows.
- **Fail:** empty output usually means Commercial-cloud connection (Test 1) or no Graph scope consented.

## Test 4 — Report matches the portal population
- **Do:** run **`INTCOMPDXG-Report.ps1`** for the affected group.
- **Pass:** the compliant/non-compliant counts match **Devices → Compliance → Overview** (and per-policy
  monitoring) in `intune.microsoft.us`.
- **Fail:** counts differ → check scope filters, the group targeted, and the environment.

## Test 5 — A single fix turns a pilot device Compliant
- **Do:** apply one branch-C fix to one device; force **Sync**; wait for re-evaluation.
- **Pass:** `INTCOMPDXG-Validation.ps1` reports PASS for that setting **and** the device shows
  **Compliant** in `intune.microsoft.us`.
- **Fail:** still failing → confirm the device rebooted (for DHA-backed rules), checked in, and that
  the rule's feature is actually **supported in GCC High** (section 3 ⚑ markers).

## Test 6 — Remediation honors `-WhatIf` by default
- **Do:** run **`INTCOMPDXG-Remediation.ps1`** with no execute flag.
- **Pass:** it **only previews** planned actions and changes nothing; a real change happens **only**
  when you re-run with `-Execute` (or `-WhatIf:$false`).
- **Fail:** if it changes state without an explicit execute flag, stop and review — that violates the
  safety contract.

## Test 7 — Scope targeting preview is safe
- **Do:** run **`INTCOMPDXG-Set-ScopeTargeting.ps1`** with no execute flag.
- **Pass:** it prints the **planned** assignment change (add/remove group on the policy) and makes no
  change until re-run with `-Execute`.
- **Fail:** any assignment change without the execute flag → stop.

## Test 8 — Conditional Access unblocks after Compliant
- **Do:** on a device that is now **Compliant**, have the user sign out/in to a CA-gated app.
- **Pass:** access is granted; `portal.azure.us` → **Sign-in logs** shows the CA policy **satisfied**.
- **Fail:** still blocked → Branch D (propagation lag, platform mismatch, or a different CA policy).

## Test 9 — Parity-gap rules are handled, not "fixed forever"
- **Do:** for any rule tied to an absent/planned GCC High feature (e.g. MTD vendor not in Gov), confirm
  it is **removed or replaced**, not left permanently failing.
- **Pass:** no device is stuck non-compliant on a rule the sovereign cloud cannot evaluate.
- **Fail:** a rule references a Gov-unavailable feature → replace it (section 3 / parity notes).

---
**Exit criteria:** Tests 1–9 pass on the pilot; Discovery/Report match the portal; every scripted
change previewed before execution; no device stuck on a GCC High parity gap. Only then expand the fix
in waves.
