# Runbook Library

This is the heart of the solution: the categorized runbooks a Tier-1/Tier-2 technician follows.
Each runbook uses the fixed anatomy from the Solution Overview — **Scope / symptoms**,
**Triage tree**, **Checks**, **Resolution**, **Escalation gate**, **Evidence to collect** — so you
always know where to look next.

**How to use this library:** From the ticket, pick the runbook whose *symptoms* match. Work the
*triage tree* to land on a branch, run the *checks* in order until one identifies the cause, apply
the matching *resolution*, or stop at the *escalation gate*. Attach the *evidence* regardless of
outcome. Always prefer the least-disruptive fix first (Sync before Restart, Restart before
re-enroll, targeted change before wipe).

Two conventions used throughout:

- **Intune** = Microsoft Intune admin center, `https://intune.microsoft.com`.
- **Entra** = Microsoft Entra admin center, `https://entra.microsoft.com`.

---

## Runbook 1 — Sign-in and user profile

### Scope / symptoms
User cannot sign in to Windows or to work resources; "your account has been locked / needs
attention"; wrong or temporary profile ("We can't sign you in with this profile"); repeated
password/MFA prompts; SSO to Microsoft 365 apps fails. **Not covered:** the device itself is
unenrolled or non-compliant (use Runbook 6); an app opens but errors (use Runbook 4).

### Triage tree
```
Can the user sign in at https://portal.office.com from ANOTHER device?
├─ No  → identity-side issue (account, password, MFA, conditional access) → Checks C1–C3
└─ Yes → device/profile-side issue on THIS device                        → Checks C4–C5
```

### Checks
- **C1 — Account state (Entra):** Entra → **Users** → the user → confirm **Account enabled** = Yes,
  not blocked, and sign-in not marked risky. Unhealthy: account disabled or blocked.
- **C2 — Sign-in logs (Entra):** Entra → **Users** → the user → **Sign-in logs**. Read the most
  recent failure's **Failure reason** and the **Conditional Access** tab. Unhealthy: a Conditional
  Access policy is blocking, or MFA is failing.
- **C3 — MFA methods (Entra):** Entra → **Users** → the user → **Authentication methods**. Unhealthy:
  no usable method, or the user lost their device.
- **C4 — Profile type (device, via Remote Help):** **Settings → Accounts → Your info** and
  **Event Viewer → Applications and Services Logs → Microsoft → Windows → User Profile Service**.
  Unhealthy: "temporary profile" event (User Profile Service event ID 1511/1515).
- **C5 — Cached credentials / join state (device):** run `dsregcmd /status`. Confirm
  `AzureAdJoined : YES` and `SSO State` shows a valid PRT (`AzureAdPrt : YES`). Unhealthy:
  `AzureAdPrt : NO` → SSO/token problem.

### Resolution
- **Locked/disabled account (C1):** if within your rights, re-enable in Entra → **Users** → user →
  **Account enabled**. If it was disabled deliberately, escalate.
- **MFA lost/broken (C3):** if permitted, have the user re-register a method, or request a
  Temporary Access Pass from an identity admin. Do **not** disable MFA.
- **Temporary profile (C4):** confirm free disk space, then reboot. If it persists, the profile is
  corrupt — escalate (profile rebuild affects user data; see gate).
- **Missing PRT (C5):** run `dsregcmd /status`, have the user lock/unlock or sign out and back in
  to re-acquire the PRT; confirm the device time/date is correct (token errors are often clock
  skew).

### Escalation gate
Escalate to the **identity/security team** when: a Conditional Access policy must be changed (C2);
an account was disabled on purpose; MFA reset requires elevated identity rights; or a profile is
corrupt and must be rebuilt (data-loss risk — never delete a profile without the user's data backed
up and owner approval).

### Evidence to collect
Screenshot of the sign-in log failure reason and Conditional Access result; `dsregcmd /status`
output; User Profile Service event IDs with timestamps; the exact error text shown to the user.

---

## Runbook 2 — OS and Windows Update

### Scope / symptoms
Windows won't boot or is slow/unstable; update stuck, failing, or looping; a feature update won't
install; blue-screen (bugcheck). **Not covered:** a single app crashing (Runbook 4); hardware
faults (Runbook 3).

### Triage tree
```
Does the device boot to the desktop?
├─ No  → boot/stability issue                → Checks C1–C2 (then likely escalate)
└─ Yes → is it an UPDATE problem or PERF/stability?
         ├─ Update    → Checks C3–C4
         └─ Perf      → Check C5
```

### Checks
- **C1 — Recent change (Intune):** Intune → **Devices** → device → **Recent activity** and
  **Managed apps** — did a policy, feature update, or app deploy just before the failure?
- **C2 — Bugcheck history (device):** **Event Viewer → Windows Logs → System**, filter Source
  `BugCheck`. Note the stop code. Recurring identical stop code → likely driver/hardware
  (cross-check Runbook 3).
- **C3 — Update ring / status (Intune):** Intune → **Devices → Windows → Update rings** (or
  **Feature updates**) → confirm the device's ring and **deferral/pause** settings; open the
  device's **Windows 10 and later updates** report for the failing update and its error code.
- **C4 — Update error (device):** **Settings → Windows Update → Update history**; note the
  `0x…` error code. Check free disk space (feature updates need headroom).
- **C5 — Performance (Intune):** if endpoint analytics is licensed, Intune →
  **Reports → Endpoint analytics → Startup performance** for this device; otherwise Task Manager /
  Resource Monitor via Remote Help.

### Resolution
- **Stuck/failed quality update:** trigger **Sync** (Intune → device → **Sync**), then on the
  device run `Settings → Windows Update → Retry`. If it fails again, note the error code for the
  gate.
- **Low disk blocking update (C4):** run **Storage Sense** / **Disk Cleanup** (incl. Windows
  Update cleanup) via Remote Help, then retry.
- **Paused/deferred by policy (C3):** confirm the ring is intended; if the device is wrongly
  excluded from an update ring, fix group membership (see Runbook 6 / Set-ScopeTargeting) rather
  than forcing updates locally.
- **Performance (C5):** identify the top CPU/disk/memory consumer; if it's a known app, apply
  Runbook 4; if startup is slow, review startup apps.

### Escalation gate
Escalate to the **desktop engineering / platform team** when: the device does not boot (C1/C2);
a recurring bugcheck points to driver/firmware; a feature update fails with the same error after
disk and retry are cleared; or an update-ring policy needs to change. **Never** re-image or reset a
device without owner approval and confirmed data backup.

### Evidence to collect
Windows Update error code(s); relevant System-log bugcheck stop codes with timestamps; free-disk
figure; the device's update ring name; endpoint-analytics startup score if available.

---

## Runbook 3 — Hardware and peripherals

### Scope / symptoms
Device won't power on / battery/charging issue; display, keyboard, touchpad, camera, audio, or
docking-station peripheral not working; external monitor not detected; recurring
device-driver errors. **Not covered:** the peripheral is fine but the app can't use it (Runbook 4);
network hardware/reachability (Runbook 5).

### Triage tree
```
Is the failing part INTERNAL (screen, keyboard, battery) or a PERIPHERAL (monitor, dock, USB, headset)?
├─ Internal   → likely physical → Checks C1–C2 → often escalate to hardware/warranty
└─ Peripheral → Checks C2–C4 (driver, connection, another port/device)
```

### Checks
- **C1 — Warranty / model context (Intune):** Intune → **Devices** → device → **Hardware** — note
  model, serial, and (if recorded) warranty. This tells you the escalation path for physical repair.
- **C2 — Device Manager (device, via Remote Help):** open **Device Manager**; look for a yellow
  bang / "Unknown device" / disabled device. Note the device name and any error code (e.g. Code 43,
  Code 10).
- **C3 — Isolate the peripheral:** try another port, another cable, and the same peripheral on a
  second machine (or a different peripheral on this machine). This separates "device fault" from
  "peripheral fault."
- **C4 — Driver source (Intune):** confirm whether the driver is delivered by an Intune app/driver
  policy or Windows Update; check **Update history** for a recent driver change that lines up with
  the failure.

### Resolution
- **Peripheral driver (C2/C4):** via Remote Help, in Device Manager **Uninstall device** (leave
  "delete driver" unchecked unless the driver is known-bad) and **Scan for hardware changes**, or
  let Windows Update re-provision it; reconnect.
- **Docking/monitor not detected (C3):** reseat the dock, update the dock firmware per the *dock
  vendor's documentation*, try the port directly; confirm the correct display input.
- **Peripheral confirmed faulty (C3):** arrange replacement of the peripheral.
- **Internal fault confirmed (C1/C3):** escalate to hardware/warranty (see gate).

### Escalation gate
Escalate to **hardware / warranty (or the OEM per the device vendor's documentation)** when an
internal component is confirmed faulty, the device won't power on, or a repair is needed. Escalate
to **desktop engineering** if a bad driver is being delivered fleet-wide by policy.

### Evidence to collect
Model + serial from Hardware; Device Manager error code and device name; isolation results (which
port/cable/second machine was tried and the outcome); any recent driver version change.

---

## Runbook 4 — Application

### Scope / symptoms
An app won't install, won't open, crashes, or errors on launch; an Intune-deployed app is missing;
a line-of-business app misbehaves. **Not covered:** the app is fine but sign-in to it fails
(Runbook 1); the app can't reach its server (Runbook 5).

### Triage tree
```
Is the app DEPLOYED by Intune, or user/manually installed?
├─ Intune-deployed → is it INSTALLED on the device?
│   ├─ No  → deployment/targeting issue → Checks C1–C2
│   └─ Yes → runtime issue              → Checks C3–C4
└─ User-installed  → runtime/support issue → Checks C3–C4 (+ vendor docs)
```

### Checks
- **C1 — App assignment (Intune):** Intune → **Apps → All apps** → the app → **Device install
  status** / **User install status**; find the device/user and read the status (Installed, Failed,
  Not applicable) and any error code.
- **C2 — Targeting (Entra/Intune):** confirm the device or user is in the Entra group the app is
  **assigned** to (App → **Properties → Assignments**). "Not applicable" almost always means the
  target isn't in the group.
- **C3 — App crash (device):** **Event Viewer → Windows Logs → Application**, filter Source
  `Application Error` / `.NET Runtime`; note the faulting module and event time.
- **C4 — Version / dependency (device):** confirm installed version (**Settings → Apps →
  Installed apps**) against the expected version; confirm prerequisites/runtimes are present.

### Resolution
- **Failed/missing deploy (C1):** trigger **Sync** on the device; if still failing, read the
  install error code; if targeting is wrong (C2), fix group membership (Runbook 6 /
  Set-ScopeTargeting) — do not sideload around the deployment.
- **Crashing app (C3):** repair or reinstall the app (via Company Portal for Intune apps),
  update to the supported version, install the missing runtime/dependency (C4).
- **Vendor-specific fault:** if the app's own logs point to a product-internal error, hand off to
  that application vendor's documentation/support with the evidence attached.

### Escalation gate
Escalate to the **app owner / packaging team** when an Intune app install fails fleet-wide, the
package or detection rule is wrong, or a licensing/entitlement issue is involved. Escalate to the
**application vendor** for product-internal faults beyond reinstall/repair.

### Evidence to collect
App name and version; Intune install status + error code; whether the target is in the assigned
group; Application-log faulting module/event with timestamp; steps already tried (sync, reinstall,
repair).

---

## Runbook 5 — Network reachability

### Scope / symptoms
No internet or intranet; can't reach a specific server, share, or SaaS site; VPN won't connect;
Wi-Fi drops; "you're offline"; slow connectivity. **Not covered:** the network is fine but sign-in
fails (Runbook 1); an app-internal error (Runbook 4).

### Triage tree
```
Is EVERYTHING unreachable, or just ONE destination?
├─ Everything → local network/adapter/Wi-Fi → Checks C1–C2
└─ One target → name resolution / route / that service → Checks C3–C4
```

### Checks
- **C1 — Adapter / link (device, via Remote Help):** **Settings → Network & internet**; confirm
  connected SSID/Ethernet, and run `ipconfig /all` — valid IP (not 169.254.x.x), gateway, DNS.
- **C2 — Basic reachability:** `ping` the gateway, then `ping 8.8.8.8` (raw IP) — isolates
  local vs. upstream.
- **C3 — Name resolution:** `nslookup <the-failing-hostname>` — does it resolve? Compare a
  working host. DNS failure vs. reachable-but-refused are different problems.
- **C4 — Path / VPN / proxy:** `Test-NetConnection <host> -Port <port>` for the specific service;
  if VPN, check the VPN client state and the VPN profile in Intune (**Devices → Configuration** →
  VPN profile → assignment). Confirm proxy settings aren't misdirecting traffic.

### Resolution
- **No IP / 169.254 (C1):** reconnect Wi-Fi or reseat Ethernet; `ipconfig /release` +
  `/renew`; forget/rejoin the Wi-Fi profile if corrupt.
- **DNS (C3):** `ipconfig /flushdns`; confirm the device is using the expected DNS servers (from
  DHCP or policy), not a stale/manual entry.
- **VPN (C4):** reconnect; confirm credentials/cert; confirm the VPN profile is assigned to the
  device's group (Runbook 6 if not); update the VPN client per the *VPN vendor's documentation*.
- **One SaaS/site only:** confirm it's reachable from another network — if it's down for everyone,
  it's a service outage, not this device.

### Escalation gate
Escalate to the **network team** when the fault is upstream (gateway/DNS/firewall/proxy serving
the whole location), a VPN gateway is down, or a firewall rule must change. Escalate to the
**service owner** for a confirmed SaaS/service outage. Do not change firewall or DNS
infrastructure from the endpoint.

### Evidence to collect
`ipconfig /all` output; ping/`Test-NetConnection` results (which target, which port, pass/fail);
`nslookup` result for the failing host; VPN profile name and assignment; whether the target is
reachable from another network.

---

## Runbook 6 — Enrollment and compliance

### Scope / symptoms
Device shows non-compliant; "your device needs attention" / blocked from resources by Conditional
Access; device missing from Intune or not receiving policies/apps; enrollment failed; the device
isn't in the group it should be. **Not covered:** the device is enrolled and compliant but a single
app failed (Runbook 4).

### Triage tree
```
Is the device ENROLLED and visible in Intune?
├─ No  → enrollment/join problem → Checks C1–C2
└─ Yes → is it COMPLIANT?
         ├─ No       → which setting fails? → Check C3
         └─ Yes      → not getting a policy/app → Check C4 (targeting)
```

### Checks
- **C1 — Presence (Intune):** Intune → **Devices → All devices** — is the device there? Note
  **Managed by**, **Ownership**, **Last check-in**. Stale last check-in → the device isn't syncing.
- **C2 — Join state (device):** `dsregcmd /status` — `AzureAdJoined : YES`,
  `EnterpriseJoined`/`DomainJoined` as expected, and `MDMUrl` present (enrolled). Unhealthy:
  joined but not MDM-enrolled.
- **C3 — Compliance detail (Intune):** Intune → **Devices** → device → **Device compliance** —
  open the failing policy and read exactly which setting is non-compliant (e.g. BitLocker,
  Defender, minimum OS, password).
- **C4 — Targeting (Entra/Intune):** confirm the device (or its primary user) is in the Entra
  group that the policy/app is assigned to. Missing membership = missing policy.

### Checks → Resolution
- **Not syncing (C1):** Intune → device → **Sync**; on the device open **Settings → Accounts →
  Access work or school** → the account → **Info → Sync**. Confirm network (Runbook 5).
- **Joined but not enrolled (C2):** confirm auto-enrollment; have the user
  **Access work or school → Connect / re-connect** the work account; if it fails, note the error.
- **Compliance setting (C3):** remediate the specific setting — e.g. turn on BitLocker/Defender,
  set a compliant password, install the pending update (Runbook 2). Re-run compliance evaluation
  (**Sync**).
- **Wrong group (C4):** add the device/user to the correct Entra group (see
  **DESKSUP-Set-ScopeTargeting.ps1**, default `-WhatIf`), or request the change if you lack rights.

### Escalation gate
Escalate to **endpoint engineering** when: enrollment repeatedly fails with the same error; a
compliance policy setting can't be remediated on the endpoint (e.g. hardware doesn't support a
required feature); the device must be retired/re-enrolled/wiped (owner approval + data backup
required); or a Conditional Access block requires an identity/security decision (also Runbook 1).

### Evidence to collect
`dsregcmd /status` output; device Overview (Managed by / Ownership / Last check-in); the exact
non-compliant setting and its policy name; the group(s) the device is/should be in; enrollment
error text if any.

---

## Cross-runbook notes

- **Least-disruptive first, always:** Sync → local retry → targeted config change → reinstall →
  (only with approval) re-enroll/reset. Never jump to a destructive action to save a step.
- **Scope before cause:** one user, one device, one location, or the whole fleet — establish this
  in intake; a fleet-wide symptom almost always means policy/targeting or a service outage, not the
  single device in front of you.
- **The scripts support the runbooks:** use **DESKSUP-Discovery** and **DESKSUP-Validation** during
  *Checks* to read device state at scale, **DESKSUP-Report** to see trends for the *Document* stage,
  **DESKSUP-Remediation** for the safe common fixes above (default `-WhatIf`), and
  **DESKSUP-Set-ScopeTargeting** for the group-membership fixes (default `-WhatIf`).
