# Runbook Library

This is the heart of the solution: the categorized runbooks a technician follows to **manage and
support Intune-managed Macs**. Each runbook uses the fixed anatomy from the Solution Overview —
**Scope / symptoms**, **Triage tree**, **Checks**, **Resolution**, **Escalation gate**,
**Evidence to collect** — so you always know where to look next. Some runbooks are *setup* tasks
(enrollment, SSO, app deployment, BYOD) and some are *support/incident* tasks (compliance,
incident response); the anatomy is the same for both — for a setup runbook the "resolution" is the
step-by-step configuration.

**How to use this library:** From the ticket or task, pick the runbook whose *symptoms/scope*
match. Work the *triage tree* to land on a branch, run the *checks* in order until one identifies
the cause (or confirms readiness for a setup step), apply the matching *resolution/steps*, or stop
at the *escalation gate*. Attach the *evidence* regardless of outcome. Always prefer the
least-disruptive path first (Sync before Restart, targeted change before re-enroll, and **never**
an action that risks FileVault data without approval and a confirmed recovery key).

Three conventions used throughout:

- **Intune** = Microsoft Intune admin center, `https://intune.microsoft.com`.
- **Entra** = Microsoft Entra admin center, `https://entra.microsoft.com`.
- **ABM** = Apple Business Manager, `https://business.apple.com`.

> **Menu-path caveat (applies to every runbook):** Apple and Microsoft rename and move console
> menus periodically. Where a path is given, confirm the current label in the console if it has
> moved. macOS Terminal commands (`profiles`, `fdesetup`, `dsmemberutil`, `sysadminctl`) are run
> in **Terminal.app** and several require `sudo`; run them read-only first.

---

## Runbook 1 — ADE / enrollment

### Scope / symptoms
Setting up or fixing Automated Device Enrollment (ADE) for Macs: a new Mac should enroll
automatically through Setup Assistant but doesn't; a Mac is missing from Intune; enrollment fails
or the enrollment profile isn't offered; a Mac enrolled but shows no management profile.
**Not covered:** the Mac is enrolled but non-compliant (Runbook 6); user-driven Company Portal
enrollment for BYOD (Runbook 5).

### Triage tree
```
Is this a NEW device setup, or an EXISTING Mac that lost/failed enrollment?
├─ New setup   → is the serial assigned to the Intune MDM server in ABM?
│   ├─ No  → ABM assignment/token problem            → Checks C1–C2
│   └─ Yes → enrollment profile / Setup Assistant     → Checks C3–C4
└─ Existing    → is the management profile present on the Mac?
    ├─ No  → profile removed / never installed         → Checks C4–C5
    └─ Yes → visible in Intune but stale               → Check C5
```

### Checks
- **C1 — ABM device assignment (ABM):** ABM → **Devices** → search the **serial** → confirm it is
  assigned to the **MDM Server** that represents Intune. Unhealthy: serial not present, or assigned
  to a different/none MDM server.
- **C2 — ADE token / sync (Intune):** Intune → **Devices → macOS → macOS enrollment →
  Enrollment program tokens** → the token → confirm it is **valid/not expired** and **Sync**;
  check the associated **enrollment profile**. Unhealthy: token expired, or no default profile
  assigned.
- **C3 — Enrollment profile assignment (Intune):** Intune → **Devices → macOS → macOS enrollment →
  Enrollment program tokens → (token) → Profiles / Devices** — confirm an ADE enrollment profile
  is assigned to this serial. Unhealthy: device has no profile assigned.
- **C4 — Management profile on the Mac (device):** run `profiles status -type enrollment` and open
  **System Settings → General → Device Management**. Unhealthy: "no configuration installed" / no
  MDM profile.
- **C5 — Presence & check-in (Intune):** Intune → **Devices → All devices** (OS = macOS) — is the
  Mac there? Note **Last check-in**. Stale last check-in → not syncing (see Runbook 6 C-sync).

### Resolution
- **Not in ABM / wrong MDM server (C1):** in ABM, assign the serial to the Intune MDM server
  (**Devices → Edit MDM Server**), then in Intune **Sync** the token. If the Mac was bought outside
  Apple's reseller channel, it may need manual addition via **Apple Configurator** — hand to the
  team that owns ABM.
- **Token/profile (C2/C3):** if the token is expired, renew it (download a new token from ABM →
  **Preferences → MDM Server → Download Token**, upload in Intune) — this is usually an admin task
  (see gate). Assign a **default enrollment profile** to the token so new serials receive it.
- **Setup Assistant didn't offer enrollment (C4):** the Mac must be **erased and reset** to re-run
  Setup Assistant for ADE (data-loss — see gate) *or* enrolled user-driven via Company Portal as a
  fallback (Runbook 5). Do not erase without approval and backup.
- **Missing/stale profile (C4/C5):** for a Mac still in Intune, trigger **Sync** (Intune → device →
  **Sync**) and on the Mac **System Settings → Device Management** to confirm the profile
  reinstalls; if the MDM profile was removed by the user, re-enroll via Company Portal.

### Escalation gate
Escalate to **endpoint engineering / the ABM owner** when: the ADE token is expired and must be
renewed; a serial isn't in ABM and needs Apple Configurator or reseller action; enrollment fails
repeatedly with the same error; or the fix requires **erasing the Mac** (owner approval + confirmed
data backup, and confirm you have the FileVault recovery key before any erase).

### Evidence to collect
Serial number; ABM assignment (which MDM server) screenshot; token validity + assigned enrollment
profile; `profiles status -type enrollment` output; **Device Management** screenshot; Intune
Overview (Last check-in); exact enrollment error text.

---

## Runbook 2 — SSO setup (Platform SSO / Enterprise SSO)

### Scope / symptoms
Setting up or fixing single sign-on to Microsoft Entra on Macs: deploying the **Microsoft
Enterprise SSO plug-in** (Company Portal-based) or **Platform SSO**; SSO to Microsoft 365 apps
fails; repeated Entra sign-in/MFA prompts on a Mac; Platform SSO registration doesn't complete.
**Not covered:** the account itself is disabled/locked in Entra (Runbook 7 identity paths); app
install issues (Runbook 3).

### Triage tree
```
Is this INITIAL setup or a BROKEN existing SSO?
├─ Setup   → which mode? Enterprise SSO plug-in (baseline) or Platform SSO (device-bound)
│            → follow the matching Resolution steps
└─ Broken  → is the SSO configuration profile installed and Company Portal present?
    ├─ No  → profile/app not delivered → Checks C1–C2
    └─ Yes → registration/token issue  → Checks C3–C4
```

### Checks
- **C1 — SSO profile assigned (Intune):** Intune → **Devices → macOS → Configuration** → the SSO
  extension profile → **Properties → Assignments** — is the Mac's group targeted? Unhealthy: device
  not in the assigned group (fix via Set-ScopeTargeting).
- **C2 — Company Portal present (device):** confirm **Company Portal** is installed (the Enterprise
  SSO plug-in ships with it) and the user has signed in once. Unhealthy: Company Portal missing or
  never signed in.
- **C3 — Profile installed on Mac (device):** **System Settings → General → Device Management** →
  confirm the **Single Sign-On Extension** / **Platform SSO** payload is present; run
  `app-sso platform -s` (Platform SSO state) if using Platform SSO. Unhealthy: payload missing, or
  Platform SSO shows **not registered**.
- **C4 — Sign-in evidence (Entra):** Entra → **Users → (user) → Sign-in logs** — read the most
  recent failure's **Failure reason** and **Conditional Access** tab. Unhealthy: token/MFA failing,
  or a CA policy blocking.

### Resolution
- **Deploy Enterprise SSO plug-in (baseline):** Intune → **Devices → macOS → Configuration →
  Create → Templates → Device features** (or **Settings catalog → Single Sign-On Extension**),
  add the **Microsoft Enterprise SSO plug-in** (extension identifier for the Microsoft SSO
  extension), set the required Entra values, assign to the Mac group. Ensure **Company Portal** is
  deployed (Runbook 3). Sign in to Company Portal once to activate it.
- **Deploy Platform SSO (device-bound):** create a **Platform SSO** configuration (Settings catalog)
  choosing the authentication method (e.g. Secure Enclave key or password sync per your design),
  assign it, then have the user complete the **registration prompt** at login. **Flagged as
  uncertain:** Platform SSO options and prerequisites change across macOS releases — confirm the
  current supported settings before rollout, and pilot first.
- **Targeting/app missing (C1/C2):** add the Mac to the assigned group (Set-ScopeTargeting) or
  deploy Company Portal; re-sync.
- **Registration/token (C3/C4):** have the user sign out/in or re-run the Platform SSO
  registration; confirm device time is correct (token failures are often clock skew); if a CA
  policy blocks, that's an identity decision (gate).

### Escalation gate
Escalate to the **identity/security team** when a Conditional Access policy must change, Platform
SSO design decisions are needed (auth method, key type), or SSO fails tenant-wide after the profile
and Company Portal are confirmed present.

### Evidence to collect
SSO profile name + assignment; Company Portal present/signed-in yes/no; **Device Management**
screenshot showing the SSO payload; `app-sso platform -s` output (if Platform SSO); sign-in log
failure reason + CA result; device date/time.

---

## Runbook 3 — App deployment (VPP / line-of-business)

### Scope / symptoms
Deploying or fixing Mac apps via Intune: a **VPP (Apps and Books)** store app or a
line-of-business `.pkg`/`.dmg` won't install, is missing, or fails; a required app (Company Portal,
a browser, an LOB app) didn't reach the Mac. **Not covered:** the app installs but can't sign in
(Runbook 2 / Runbook 7); the app can't reach its server (network — outside this library's scope,
hand to the network team).

### Triage tree
```
Is the app a VPP (store) app or a line-of-business package?
├─ VPP       → are licenses available and the token valid?
│   ├─ No  → VPP token / license problem → Checks C1–C2
│   └─ Yes → assignment/targeting        → Checks C3–C4
└─ LOB pkg   → is it assigned and installing?
    ├─ No  → targeting/assignment        → Check C3
    └─ Yes but failing → package/detection → Check C4
```

### Checks
- **C1 — VPP token (Intune):** Intune → **Tenant administration → Connectors and tokens → Apple
  VPP tokens** — confirm the token is **valid/not expired** and **synced**. Unhealthy: expired or
  errored token.
- **C2 — License availability (Intune/ABM):** the VPP app → confirm **available licenses > 0**
  (ABM → **Apps and Books** shows purchased quantity). Unhealthy: licenses exhausted.
- **C3 — Assignment/targeting (Intune/Entra):** Intune → **Apps → macOS → (app) → Properties →
  Assignments** — is the Mac/user in the assigned group? Read **Device/User install status**.
  "Not applicable" almost always means the target isn't in the group.
- **C4 — Install status / detection (Intune/device):** the app → **Device install status** →
  read the state and error; on the Mac confirm whether the app is in **/Applications** and its
  version (matches the LOB detection rule?). Unhealthy: install failed, or detection rule doesn't
  match the delivered version.

### Resolution
- **VPP token/licenses (C1/C2):** renew/re-sync the VPP token (admin task — see gate); buy more
  licenses in ABM → **Apps and Books** if exhausted; re-sync in Intune.
- **Deploy a VPP app:** Intune → **Apps → macOS → Add → macOS app (Apple VPP)** → pick the app →
  choose **device** or **user** licensing → assign to the Mac group. Sync.
- **Deploy an LOB app:** Intune → **Apps → macOS → Add → macOS app (PKG)** (or line-of-business
  format), upload the signed package, set the **detection/version** info, assign to the group. For
  unmanaged formats, prefer a signed `.pkg`. Sync.
- **Targeting miss (C3):** add the Mac to the assigned group (Set-ScopeTargeting) — do **not**
  sideload around the deployment.
- **Failed install / detection (C4):** trigger **Sync**; if it still fails, read the error; fix the
  detection rule to match the delivered version; for a product-internal install error, hand off to
  that app vendor's documentation with the evidence attached.

### Escalation gate
Escalate to the **app owner / packaging team** when an app install fails fleet-wide, a package or
detection rule is wrong, or a VPP token/licensing/entitlement issue needs an admin. Escalate to the
**application vendor** for product-internal install faults beyond reinstall/repair.

### Evidence to collect
App name + version; VPP token state and license count (if VPP); Intune install status + error
code; whether the target is in the assigned group; whether the app is present in `/Applications`
and its version; steps already tried.

---

## Runbook 4 — Passwordless / FileVault procedures

### Scope / symptoms
Configuring and supporting FileVault encryption and modern sign-in on Macs: enabling/enforcing
FileVault via Intune, **escrowing and rotating the recovery key**, confirming **SecureToken** and
the **bootstrap token**, and standing up passwordless sign-in (Platform SSO device-bound
authentication). **Not covered:** a Mac is *locked out* or FileVault is *broken* (Runbook 7 —
incident response); Platform SSO *setup* details (Runbook 2).

> **Safety first (read before touching FileVault):** FileVault protects user data with encryption.
> Any action that could change the encryption state, the unlock account, or the recovery key can
> **lock a user out of their data permanently** if the recovery key isn't escrowed. Confirm the
> recovery key is escrowed in Intune **before** any FileVault change, and treat the key as a
> secret (never paste it into a ticket).

### Triage tree
```
Is FileVault being ENABLED/ENFORCED, or is this KEY/TOKEN maintenance?
├─ Enable/enforce → is a FileVault policy assigned and is the key escrowing?
│   ├─ No policy  → deploy FileVault policy → Resolution "Enable FileVault"
│   └─ Policy on  → key not escrowed        → Checks C1–C2
└─ Key/token maint → rotate key OR verify SecureToken/bootstrap token → Checks C2–C4
```

### Checks
- **C1 — FileVault policy assigned (Intune):** Intune → **Devices → macOS → Configuration** →
  the FileVault (disk encryption) profile → **Assignments** — targeted at the Mac's group?
  Unhealthy: not assigned.
- **C2 — Recovery key escrowed (Intune):** Intune → **Devices → (the Mac) → Recovery keys** (or
  **Monitor → Encryption report**) — is a **personal recovery key** stored? Unhealthy: no key
  escrowed (do not change FileVault until this is resolved).
- **C3 — FileVault state (device):** run `fdesetup status` — "FileVault is On/Off" and any
  in-progress encryption. Unhealthy: mismatch with policy (policy says On, device Off).
- **C4 — SecureToken / bootstrap token (device):** `sysadminctl -secureTokenStatus <user>`
  (SecureToken for the account) and `profiles status -type bootstraptoken` (bootstrap token
  escrowed to MDM). Unhealthy: user has **no SecureToken**, or **no bootstrap token** escrowed —
  future FileVault-enabled operations may fail.

### Resolution
- **Enable FileVault (deploy):** Intune → **Devices → macOS → Configuration → Create → Templates →
  Endpoint protection → FileVault** (or **Settings catalog → FileVault**): turn on **Enable
  FileVault**, set **key type = Personal recovery key**, enable **Escrow recovery key**, choose the
  deferral behavior, and assign to the Mac group. FileVault engages at the user's next sign-in.
- **Escrow missing key (C2):** trigger **Sync**; if the key still doesn't escrow, use the Intune
  device action **Rotate FileVault key** (this generates and escrows a new key) — confirm the new
  key appears under **Recovery keys**. If FileVault was enabled outside policy, the key may need to
  be rotated to capture it.
- **Rotate the recovery key (maintenance / after exposure):** Intune → **Devices → (the Mac) →
  Rotate FileVault key** (or the Remediation script), then confirm the new key escrows. Rotate any
  time a key may have been exposed.
- **SecureToken / bootstrap token (C4):** ensure the **bootstrap token** is escrowed (on ADE-enrolled
  Apple silicon Macs it is captured automatically at first admin sign-in; confirm with
  `profiles status -type bootstraptoken`). If a user account lacks SecureToken, an admin account
  that has one can grant it with `sysadminctl -secureTokenOn <user> ...` — **flagged as uncertain
  and sensitive:** SecureToken grants are hardware/OS-version dependent and can affect who can
  unlock FileVault; do this deliberately on a pilot and escalate if unsure (see gate).
- **Passwordless (Platform SSO):** stand up device-bound Platform SSO per Runbook 2 so the user
  authenticates with a Secure Enclave key rather than a password where your design supports it.

### Escalation gate
Escalate to **endpoint engineering** when: the recovery key **cannot** be escrowed after rotation;
`fdesetup`/SecureToken/bootstrap-token state can't be reconciled with policy; or any FileVault
change is contemplated **without** a confirmed escrowed key (stop — data-loss risk). Never disable
FileVault or reset an account's password in a way that could orphan the encryption without owner
approval and a verified recovery key.

### Evidence to collect
FileVault policy name + assignment; `fdesetup status` output; escrowed-key present yes/no (never
the key value); `sysadminctl -secureTokenStatus` and `profiles status -type bootstraptoken`
results; rotation confirmation (new key escrowed).

---

## Runbook 5 — BYOD (user-driven / Company Portal enrollment)

### Scope / symptoms
Onboarding a personally owned Mac (BYOD) or a Mac that must enroll user-driven rather than via ADE:
enrolling through **Company Portal**, applying the lighter BYOD profile/app set, and confirming
compliance without ADE. **Not covered:** corporate ADE devices (Runbook 1); the Mac won't sign in
to SSO afterward (Runbook 2).

### Triage tree
```
Is this a NEW BYOD enrollment or a BYOD Mac with a PROBLEM?
├─ New   → is Company Portal installed and enrollment allowed for this user?
│   ├─ No  → enrollment restriction / app missing → Checks C1–C2
│   └─ Yes → walk the user through enrollment      → Resolution "Enroll via Company Portal"
└─ Problem → enrolled but not compliant / not getting apps → Checks C2–C3 (then Runbook 6)
```

### Checks
- **C1 — Enrollment restrictions (Intune):** Intune → **Devices → Enrollment → Enrollment device
  platform restrictions → macOS** — is personally owned macOS enrollment **allowed**? Unhealthy:
  personal macOS blocked, or the user isn't licensed for Intune.
- **C2 — Company Portal (device):** confirm the user downloaded **Company Portal** (Mac) from the
  documented source and can sign in. Unhealthy: app missing or sign-in fails.
- **C3 — Assignments for BYOD (Intune/Entra):** confirm the BYOD Entra group (and its assigned
  profiles/apps) targets this user/device. Unhealthy: user not in the BYOD group.

### Resolution
- **Allow BYOD (C1):** Intune → **Devices → Enrollment → Enrollment device platform restrictions →
  macOS** → set **Personally owned** to **Allow** for the intended users; confirm Intune licensing.
- **Enroll via Company Portal:** have the user install **Company Portal** for Mac, sign in with
  their work account, and follow the prompts to install the **management profile** (approve it in
  **System Settings → Device Management**). Confirm the Mac appears in Intune with
  **Ownership = Personal**.
- **BYOD targeting (C3):** add the user/device to the BYOD Entra group (Set-ScopeTargeting) so the
  BYOD profile/app set applies. Keep BYOD policy lighter than corporate (respect the user's
  personal data — do not apply full-wipe or intrusive controls to personal devices).
- **Not compliant after enrollment:** switch to **Runbook 6** to identify the failing compliance
  setting.

### Escalation gate
Escalate to **endpoint engineering / policy owners** when BYOD enrollment must be enabled or the
BYOD policy set needs to change, or when a personal-device data-boundary question arises (what the
org may and may not manage on a personal Mac). Never apply a corporate wipe to a personal device.

### Evidence to collect
Enrollment restriction state (personal macOS allow/block); Company Portal installed + signed-in
yes/no; **Device Management** screenshot; Intune Ownership = Personal confirmation; BYOD group
membership.

---

## Runbook 6 — Compliance & Conditional Access

### Scope / symptoms
A Mac shows **non-compliant**; the user is **blocked from resources** by Conditional Access
("your device needs attention"); a Mac isn't receiving a policy/app it should. **Not covered:** the
Mac isn't enrolled at all (Runbook 1/5); the account itself is locked (Runbook 7).

### Triage tree
```
Is the Mac ENROLLED and visible in Intune?
├─ No  → enrollment problem → Runbook 1 (ADE) or Runbook 5 (BYOD)
└─ Yes → is it COMPLIANT?
         ├─ No       → which setting fails? → Check C2
         └─ Yes      → getting blocked or missing a policy/app → Checks C3–C4
```

### Checks
- **C1 — Presence & check-in (Intune):** Intune → **Devices → All devices** (OS = macOS) — note
  **Compliance**, **Ownership**, **Last check-in**. Stale check-in → not syncing (C-sync below).
- **C2 — Compliance detail (Intune):** Intune → **Devices → (the Mac) → Device compliance** — open
  the failing policy and read exactly which setting is non-compliant (common on Mac: **FileVault
  not on**, **minimum macOS version**, **Gatekeeper/System Integrity**, **firewall**, **password**).
  Cross-reference: FileVault failures → Runbook 4; OS-version failures → deploy the update.
- **C3 — Conditional Access (Entra):** Entra → **Users → (user) → Sign-in logs → Conditional
  Access** tab — is a CA policy blocking because the device is non-compliant or unregistered?
  Unhealthy: CA "Failure" citing device compliance/state.
- **C4 — Targeting (Entra/Intune):** confirm the Mac (or its primary user) is in the Entra group
  the compliance policy / config profile / app is assigned to. Missing membership = missing policy.

### Checks → Resolution
- **Not syncing (C1):** Intune → device → **Sync**; on the Mac open **System Settings → Device
  Management → (profile) → refresh**, or Company Portal → **Check status**. Confirm network.
- **Compliance setting (C2):** remediate the specific setting — enable FileVault (Runbook 4),
  install the pending macOS update to meet minimum version, enable the firewall/Gatekeeper via
  the assigned profile — then re-run compliance evaluation (**Sync**).
- **CA block (C3):** once the device is compliant/registered and re-synced, the CA block clears.
  If the CA policy itself must change (e.g. an exclusion is needed), that's an identity decision
  (gate) — do not attempt to bypass CA from the endpoint.
- **Wrong group (C4):** add the Mac/user to the correct Entra group (Set-ScopeTargeting, default
  `-WhatIf`), or request the change if you lack rights.

### Escalation gate
Escalate to **endpoint engineering** when a compliance setting can't be remediated on the endpoint
(e.g. hardware/OS can't meet a required minimum), or the device must be retired/re-enrolled/wiped
(owner approval + data backup + confirmed FileVault key). Escalate to **identity/security** when a
Conditional Access policy must change.

### Evidence to collect
Device Overview (Compliance / Ownership / Last check-in); the exact non-compliant setting and its
policy name; sign-in log Conditional Access result; the group(s) the device is/should be in.

---

## Runbook 7 — Incident response (encryption / SecureToken / lock-out)

### Scope / symptoms
A Mac is in a **broken or locked state**: user can't unlock FileVault / forgot their password and
needs the recovery key; a local account is locked out or lost its **SecureToken** (can't unlock
FileVault even with the right password); the **bootstrap token** wasn't escrowed and MDM
FileVault operations fail; the Mac is stuck at the FileVault login screen. **Not covered:** normal
FileVault *setup/maintenance* (Runbook 4); a compliance flag with a working Mac (Runbook 6).

> **This is the highest-risk runbook — read the Runbook 4 safety note first.** Data-loss is on the
> table. Every branch either resolves safely or escalates *before* a destructive step. **Never
> erase or reset a Mac in this runbook without owner approval and a confirmed recovery key.**

### Triage tree
```
Can the user reach the desktop at all?
├─ No (stuck at FileVault/login) → they need the recovery key or a token fix → Checks C1–C2
└─ Yes but degraded → account locked / SecureToken / bootstrap token issue   → Checks C2–C4
```

### Checks
- **C1 — Recovery key available (Intune):** Intune → **Devices → (the Mac) → Recovery keys** —
  is the **personal recovery key** escrowed? This is what unlocks a Mac when the password fails.
  Unhealthy: **no key escrowed** → escalate immediately (the Mac may not be recoverable without
  it).
- **C2 — Account / lock state (device, if reachable):** `dsmemberutil` / **System Settings →
  Users & Groups** — is the account disabled or locked? Note repeated failed unlocks.
- **C3 — SecureToken (device):** `sysadminctl -secureTokenStatus <user>` — does the account have a
  SecureToken? An account **without** SecureToken can't unlock FileVault even with the correct
  password. Unhealthy: SecureToken **DISABLED** for the affected user.
- **C4 — Bootstrap token (device/Intune):** `profiles status -type bootstraptoken` — is it escrowed
  to MDM? Without it, MDM-driven FileVault/account operations may fail. Unhealthy: not escrowed.

### Resolution
- **Locked at FileVault, password forgotten (C1):** retrieve the escrowed **personal recovery key**
  from Intune → **Recovery keys**, have the user enter it at the FileVault unlock screen to boot,
  then reset the account password. **After** recovery, **rotate the FileVault key** (Runbook 4) so
  the exposed key is retired, and confirm the new key escrows. Treat the retrieved key as a secret.
- **SecureToken missing (C3):** if an admin account **with** SecureToken exists, it can grant
  SecureToken to the affected user (`sysadminctl -secureTokenOn <user> ...`). **Flagged as
  uncertain / sensitive:** behavior varies by macOS version and Apple silicon vs. Intel — verify
  against Apple's documentation and do it on a pilot before production. If no admin has SecureToken,
  escalate (the account may need rebuild).
- **Bootstrap token not escrowed (C4):** on an ADE Apple silicon Mac, signing in as an
  SecureToken-holding admin usually escrows it; then MDM FileVault operations work. Confirm with
  `profiles status -type bootstraptoken`. If it still won't escrow, escalate.
- **Account locked (C2):** if within your rights and the account is intact, unlock/reset per
  organization policy; confirm the reset doesn't orphan FileVault (SecureToken/key state above).
- **Unrecoverable (no key, no token path):** stop. Escalate — the safe outcome may be an
  owner-approved erase/re-enroll *only after* confirming what data can be recovered.

### Escalation gate
Escalate to **endpoint engineering / security** immediately when: **no recovery key is escrowed**
for a locked Mac; SecureToken can't be granted (no admin token-holder); the bootstrap token won't
escrow; or the only remaining path is **erase/re-enroll** (owner approval + confirmed backup +
confirmed key required). Any destructive step in this runbook is a gate, not a technician decision.

### Evidence to collect
Recovery-key escrowed yes/no (never the key value); `sysadminctl -secureTokenStatus` result;
`profiles status -type bootstraptoken` result; account lock state; exact screen/error the user
sees; what was tried and the timestamp; confirmation that the key was rotated after any exposure.

---

## Cross-runbook notes

- **Least-disruptive first, always:** Sync → local retry / re-sign-in → targeted config/group
  change → reinstall → (only with approval + confirmed FileVault key + backup) erase/re-enroll.
  Never jump to a destructive action to save a step — on a Mac that means data loss.
- **FileVault key before any FileVault-adjacent action.** If a fix could touch encryption, the
  unlock account, or the recovery key, confirm the key is escrowed **first** (Runbook 4/7 C1).
- **Scope before cause:** one user, one Mac, one location, or the whole fleet — establish this in
  intake; a fleet-wide symptom almost always means policy/targeting, an expired token (ADE/VPP), or
  a service issue, not the single Mac in front of you.
- **The scripts support the runbooks:** use **MACRUN-Discovery** and **MACRUN-Validation** during
  *Checks* to read Mac state at scale (enrollment, compliance, FileVault escrow, SSO/config
  profiles), **MACRUN-Report** to see trends for the *Document* stage, **MACRUN-Remediation** for
  the safe fixes (Sync / Rotate FileVault key, default `-WhatIf`), and **MACRUN-Set-ScopeTargeting**
  for the group-membership fixes (default `-WhatIf`).
