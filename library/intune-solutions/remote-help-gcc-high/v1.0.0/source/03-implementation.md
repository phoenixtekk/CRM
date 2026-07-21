# 3. Implementation Guide — Remote Help — Government (GCC High) Edition

Follow these steps **in order**. This is the Government (GCC High) edition — **Step 1 is a gate**. Do
not skip it, and do not start configuring Remote Help until it passes for your tier. Every portal path,
endpoint, licensing detail, and blade name below is flagged **verify against current Microsoft
documentation** — sovereign-cloud specifics change over time.

> **Model:** Establish availability (gate) → [available] correct cloud plane → licensing → security /
> consent + RBAC → deploy the app → pilot a governed session → validate → expand. [Not available] →
> select and validate the compliant alternative.
>
> **Naming convention** — every object uses `<Purpose> – <Scope> – <Stage>`. Create these and reuse the
> names verbatim:
> - Group (helpers + pilot sharers): `RemoteHelp – GCCH – Pilot`
> - Group (production): `RemoteHelp – GCCH – Production`
> - Custom RBAC role (if used): `RemoteHelp – GCCH – HelpDesk`
> - Conditional Access (helpers): `RemoteHelp – GCCH – Helper-Protect`

## STEP 1 — Establish availability for your sovereign tier (THE GATE)

1. Read **Microsoft Learn — "Plan for Remote Help with Microsoft Intune"** and **"Microsoft Intune
   Government Service overview."** Determine your tier and Remote Help's status. At authoring time:
   - **GCC** → Remote Help **supported** (except Azure Virtual Desktop). *(Intune GCC = the commercial
     instance — you will use the **commercial** endpoints.)*
   - **GCC High / DoD** → Remote Help **not supported**; listed under **"features planned for GCC High
     and DoD"**, no ETA published.
2. Run `RHELPG-Test-Endpoints.ps1` and `RHELPG-Discovery.ps1` to confirm which cloud your tenant
   resolves and whether a Remote Help configuration is present.
3. **Decide:**
   - **If Remote Help IS available for your tier (GCC)** → continue to **Step 2**.
   - **If Remote Help is NOT available for your tier (GCC High / DoD)** → **STOP the Remote Help build.
     Go to Step 6 (the compliant alternative).** Do not attempt to force a `*.us` Remote Help
     deployment — there is nothing there to configure. Record the finding, monitor the roadmap, and
     re-verify at a later date.

> **This gate is the whole point of the Government edition.** Confirm availability **against current
> Microsoft documentation** every time — it is the single item most likely to have changed since
> authoring.

---

## PATH A — Remote Help IS available for your tier (GCC)

> For GCC, Intune is the **commercial** instance: administer at the **commercial** portals
> (`intune.microsoft.com`, `entra.microsoft.com`) and script with `-Environment Global`. Do **not** use
> the `*.us` endpoints for a GCC Intune tenant. Verify against current Microsoft documentation.

### Step 2 — Confirm the cloud plane and create the pilot group
1. Sign in to **`https://intune.microsoft.com`** (GCC = commercial). If your portal is a `*.us` URL you
   are on GCC High / DoD — return to Step 1.
2. Entra (`entra.microsoft.com`) → **Groups → New group** → **Security** → name `RemoteHelp – GCCH – Pilot`;
   add help-desk staff (helpers) and a few pilot sharer users. **Create.**
   *(Or build it with `RHELPG-Set-RoleScope.ps1` — default `-WhatIf`.)*

### Step 3 — Confirm licensing
1. M365 admin center (`https://admin.microsoft.com`) → **Billing → Licenses** — confirm a **Remote Help**
   add-on (or Intune Suite) license is assigned to **every** helper **and** sharer. **Verify the exact
   government SKU against current Microsoft documentation.**

### Step 4 — Enable Remote Help and set the security / consent options
1. Intune → **Tenant administration → Remote Help**.
2. Set **Enable Remote Help** = **Enabled**; review and accept the terms.
3. Configure options (each: verify against current Microsoft documentation):
   - **Allow Remote Help to unenrolled devices** = **No** (tighter control; enable only if you must
     support Entra-registered-only devices — it reduces oversight).
   - **Allow full control** = per policy (default to **view only** for least privilege; grant full
     control by role).
   - **Disable chat** = as preferred.
4. **Save.** These options set the tenant-wide consent/control posture; RBAC (Step 5) decides *who* gets
   which capability.

### Step 5 — Deploy the app and assign least-privilege RBAC
1. **Deploy the app:** Intune → **Apps → Windows → Add** (and macOS / approved Android as needed) → add
   **Remote Help** → **Assignments → Required →** `RemoteHelp – GCCH – Pilot`. **Create.** Exclude
   **AVD** hosts (unsupported).
2. **Assign RBAC:** Intune → **Tenant administration → Roles → Help Desk Operator** (or create a custom
   role `RemoteHelp – GCCH – HelpDesk` with only the Remote Help permissions you intend: *View screen*,
   optionally *Take full control* / *Elevation* / *Unattended*, plus *Remote Tasks — Offer remote
   assistance* and *Remote Assistance Connector — Read*).
3. **Assignments → Assign →** set the **admin/member** group to your helpers and the **scope** to a
   **user** scope group (the *All Devices* scope excludes unenrolled devices). **Save.** Preview/apply
   with `RHELPG-Set-RoleScope.ps1` (default `-WhatIf`; add `-WhatIf:$false` to apply).
4. *(Optional)* Create a Conditional Access policy `RemoteHelp – GCCH – Helper-Protect` requiring MFA /
   compliant device for the helper group (**Windows/macOS only** — verify against current Microsoft
   documentation).

### Step 5b — Pilot a governed session and validate
1. On a pilot **sharer** device, open **Remote Help → Get help** (or the helper offers assistance).
2. On the pilot **helper** device, open **Remote Help → Give help**, sign in with Entra, join the session.
3. Confirm: the helper sees the device **compliance** state, the sharer **consents** (and sees the
   on-screen session indicator), and the granted capability (view / full control) behaves per the RBAC
   role.
4. Run `RHELPG-Validate.ps1` (PASS/FAIL: correct endpoints, Remote Help enabled, RBAC set) and
   `RHELPG-Report.ps1` (deployment + role status export). Complete the **Testing Guide** (Section 5).

### Step 5c — Expand to production
1. Create `RemoteHelp – GCCH – Production`; add production helpers and sharers to the app assignment and
   the RBAC scope in waves.
2. Confirm app delivery and a successful governed session per wave; re-run `RHELPG-Validate.ps1` /
   `RHELPG-Report.ps1`.

---

## PATH B — Remote Help is NOT available for your tier (GCC High / DoD)

### Step 6 — Select and validate the compliant alternative
Remote Help is **not offered** on GCC High / DoD at authoring time (verify against current Microsoft
documentation). **Do not deploy it.** Instead:

1. **Confirm the gap** with `RHELPG-Discovery.ps1` (`-Environment USGov` / `USGovDoD`) — the Remote Help
   tenant configuration will not be present.
2. **Choose a compliant alternative** for governed remote assistance **within your authorization
   boundary** (see `gcc-high-parity-notes.md` §4 for the options and trade-offs). Candidates, each to
   be **verified for your ATO/impact level against current documentation**:
   - A **third-party remote-support tool with the appropriate government authorization** (e.g. a
     FedRAMP High / DoD IL-authorized remote-support product) integrated within your boundary.
   - **In-boundary Windows tooling** (e.g. Remote Desktop / built-in Windows Remote Assistance) governed
     by your existing controls, where your security posture permits.
   - **Quick Assist** only if your compliance authority confirms it is permitted for your tier — verify;
     do not assume it is authorized for GCC High / DoD.
3. **Do not** substitute an unauthorized consumer/commercial tool to "fill the gap" — that reintroduces
   exactly the ungoverned-access risk Remote Help was meant to remove.
4. **Monitor the Microsoft roadmap** ("Intune features planned for GCC High and DoD") and re-run Step 1
   periodically; when Remote Help ships for your tier, return to **Path A**.
5. **Validate the alternative** to the same standard: authenticated, least-privilege, consent-based,
   audited. Record it and its authorization evidence.

---
### Order of operations
`STEP 1 availability gate → [GCC] confirm commercial plane → pilot group → licensing → enable + security options → deploy app + RBAC → pilot session → validate → expand`
`STEP 1 availability gate → [GCC High/DoD] confirm the gap → select compliant alternative → validate → monitor roadmap`

> If a portal shows `.com` for a GCC High / DoD tenant (or `.us` for a GCC tenant), you are on the wrong
> plane. And if you are searching the GCC High / DoD portal for a Remote Help blade, stop — it is not
> there yet. Verify against current Microsoft documentation.
