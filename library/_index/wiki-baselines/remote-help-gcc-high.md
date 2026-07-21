# Remote Help — Government (GCC High) Edition

> **Version 1.0.0** · Category: Intune · Solution code: RHELPG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Remote Help — Government (GCC High) Edition

**White-label · Intune Solutions · US Sovereign Cloud (GCC / GCC High / DoD)**

Ad-hoc remote-support tools are a security liability: unverified helpers, no role controls, no audit
trail, and third-party software you don't fully trust. **Remote Help** is Microsoft's cloud
remote-assistance service built into Intune — Entra-authenticated helpers, gated by **RBAC**, shown
device **compliance**, with consent-based, **audited** sessions.

But a government tenant cannot assume a commercial feature works — or exists — in the sovereign cloud.
**This edition's first and governing step is to establish, against current Microsoft documentation,
whether Remote Help is available in your specific tier.** That answer is **not uniform**: at authoring
time Microsoft documents Remote Help as **supported in GCC** (which, for Intune, is the *commercial*
service instance) and **not supported on GCC High or DoD** — where it is listed among "features
**planned** for GCC High and DoD," with no ETA. This package therefore does the honest thing rather
than the convenient one: it resolves the availability gate first, then either deploys Remote Help on
the correct plane **or** — where the feature isn't offered — states that plainly and gives a compliant
alternative. **It never fabricates a `*.us` Remote Help deployment or asserts commercial parity.**

This is a complete, **assess-before-you-build** package for a competent administrator with no prior
Remote Help experience: the availability gate, every screen, every object name, every gate.

## What you get
- A **Solution Overview** stating the availability-first principle and the two honest branches (deploy vs alternative).
- A **Requirements Guide** whose first requirement is the **availability gate**, with the correct cloud plane per tier (commercial for GCC; `*.us` for GCC High / DoD) and every sovereign specific flagged **verify against current Microsoft documentation**.
- An **Implementation Guide** with **STEP 1 = establish availability (a hard gate)**, then Path A (deploy on GCC) or Path B (the compliant alternative for GCC High / DoD).
- A cited **GCC High Parity Notes** reference — the availability finding, an endpoint/feature parity table, and the compliant alternative for the gap.
- Five **PowerShell scripts** (US Gov Graph aware, `-Environment USGov`/`USGovDoD`) for sovereign discovery, PASS/FAIL validation, deployment/role reporting, endpoint confirmation, and a `-WhatIf`-gated RBAC role/scope setter.
- **Testing** and **Troubleshooting** guides with explicit pass/fail gates for both branches.

## What this delivers
An **honest, correct decision and outcome for your tier**: on **GCC**, Remote Help enabled, the app
deployed, least-privilege RBAC assigned, and a governed session piloted then expanded — on the
**commercial** plane GCC actually uses. On **GCC High / DoD**, a clear statement that Remote Help is
not available, plus a compliant, authorized alternative validated to the same authenticated,
least-privilege, consent-based, audited standard — and a plan to adopt Remote Help when Microsoft ships
it for your tier.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — where **Assess** explicitly includes the Remote
Help **availability gate**.

## Outcome
Governed remote assistance for your government tenant done right: availability verified for the
sovereign cloud rather than assumed from commercial, deployed on the correct plane where available, and
replaced with a compliant alternative where it is not — proven on a pilot before you scale, deployable
by a single administrator.


---


# 1. Solution Overview — Remote Help — Government (GCC High) Edition

> This is the **Government (GCC High)** edition. It does **not** assume the commercial Remote Help
> deployment works — or is even available — in the US sovereign cloud. It adapts the commercial
> Remote Help solution's deployment discipline, but its **first and governing step is to establish,
> against current Microsoft documentation, whether Remote Help is available in your sovereign cloud
> tier** (GCC vs GCC High vs DoD). Where it is available, deploy it with the correct national-cloud
> plane. Where it is **not** available, this document says so plainly and gives the compliant
> alternative — it does **not** fabricate a deployment or assert commercial parity.

## The availability-first principle (read this first)

Government tenants cannot assume a commercial-cloud feature behaves the same way — or exists at all —
in the sovereign cloud. Remote Help is a case where the answer is **not uniform across the government
tiers**. Therefore **Step 1 of the Implementation Guide is a gate**: confirm availability for *your*
specific tier before configuring anything. Never deploy "Remote Help for GCC High" by copying the
commercial steps; that path silently authenticates against the wrong cloud and, on GCC High / DoD,
targets a feature that is not there.

## What Remote Help is (the capability being evaluated)

Remote Help is Microsoft's cloud-based remote-assistance application, integrated with Microsoft
Intune. A help-desk technician (the **helper**) can view and, with consent, control an enrolled
user's device (the **sharer**) — authenticated through Microsoft Entra, governed by **role-based
access control (RBAC)**, shown the device's **compliance** state, and recorded in an **audit** trail.
The service brokers sessions over port 443 to a Microsoft cloud endpoint. This overview describes the
capability; the sovereign-cloud availability of that capability is established in Step 1 and detailed
in `gcc-high-parity-notes.md`.

## The sovereign-cloud finding that drives this solution (verify against current Microsoft documentation)

At authoring time, current Microsoft documentation states the following. **Treat availability as the
gating item and re-verify it against current Microsoft docs at deployment time — sovereign-cloud
availability changes over time.**

- **GCC:** Remote Help is **supported** in Government Community Cloud (GCC) environments (except in
  Azure Virtual Desktop). Note that, for Intune, **GCC is the commercial service instance** — there
  is no separate Intune "GCC" datacenter — so a GCC deployment uses the **commercial** endpoints, not
  the `*.us` sovereign endpoints. *(Source: Microsoft Learn, "Plan for Remote Help with Microsoft
  Intune"; "Microsoft Intune Government Service overview." Verify against current Microsoft
  documentation.)*
- **GCC High / DoD:** Remote Help **is not supported** on GCC High or DoD tenants. Microsoft lists
  Remote Help under **"Intune features planned for GCC High and DoD"** — planning has started, and no
  ETA is published. There is currently **no** sovereign Remote Help service to deploy on the `*.us`
  plane. *(Source: Microsoft Learn, "Plan for Remote Help with Microsoft Intune"; "Microsoft Intune
  Government Service overview." Verify against current Microsoft documentation — this is the item most
  likely to change.)*

So this edition resolves into **two honest branches**, decided by the availability gate in Step 1:

| Your tier | Availability (verify) | What this solution does |
|---|---|---|
| **GCC** | Supported (commercial instance; not AVD) | Deploy Remote Help using the **commercial** endpoints and the platform limits below. |
| **GCC High / DoD** | **Not supported** (planned, no ETA) | **Do not** deploy Remote Help. Select a **compliant alternative** for governed remote assistance within your authorization boundary, and monitor the Microsoft roadmap. |

## What this adapts from the commercial solution

The commercial Remote Help solution's discipline is preserved and re-verified for the sovereign
cloud: name every object you create, enable least-privilege RBAC, deploy the app as Required, pilot a
real session before expanding, and validate with scripts against pass/fail gates. What changes here
is the **cloud plane** (sovereign `*.us` admin portals and US Gov Graph for GCC High / DoD, versus
commercial for GCC) and, above all, the **availability gate** that decides whether a Remote Help
deployment is even the right work — or whether the compliant alternative is.

## Security model (where Remote Help is available)

- **Entra-authenticated** helpers and sharers — no anonymous access; all participants in the **same tenant**.
- **RBAC** — least-privilege built-in or custom Intune roles (e.g. **Help Desk Operator**) control view / full control / elevation / unattended.
- **Compliance visibility** — helpers see the device compliance state before connecting.
- **Consent** — sessions are consensual and visibly indicated on the sharer's screen; no session recordings are stored by the service.
- **Audited** — who helped whom, when, and features used are logged (retained ~30 days by Microsoft — verify against current Microsoft documentation).

## Benefits

- **Honest** — you learn *before* you build whether Remote Help is available for your tier, so you don't burn a rollout on a feature that isn't in GCC High / DoD.
- **Sovereign-correct** — where you administer on the `*.us` plane, you do so deliberately (GCC High / DoD), and where GCC uses the commercial instance, the document says so instead of forcing a wrong `*.us` path.
- **Compliant fallback** — if Remote Help is unavailable for your tier, you get a decision framework and a compliant alternative, not a fabricated deployment.
- **Least privilege + audited** — the same governed, consent-based assistance model the commercial edition delivers, where the feature exists.

## Limitations (be honest with buyers)

- **The headline limitation:** Remote Help is **not available on GCC High / DoD** at authoring time. If that is your tier, this solution guides you to the compliant alternative rather than a Remote Help deployment. Re-verify against current Microsoft documentation.
- Requires a **Remote Help license** (an add-on to Intune Plan 1/2) for **every** helper and sharer — where the feature is available.
- In GCC, Remote Help is **not** supported in **Azure Virtual Desktop (AVD)**, and platform support is a subset (see the parity notes).
- **Conditional Access for Remote Help helpers is supported only on Windows and macOS** (verify against current Microsoft documentation).
- Sessions require the Remote Help **service endpoint** to be reachable; do not SSL-inspect that traffic.
- Cross-tenant assistance is not supported — all participants must be in the same tenant.

## The standard deployment model

> **Establish availability (gate) → [if available] configure the correct national-cloud plane →
> licensing → security/consent + RBAC → deploy the app → pilot a governed session → validate → expand;
> [if unavailable] select the compliant alternative and validate it.**
> Pattern: **Assess → Configure → Pilot → Validate → Expand.** Assessment here explicitly includes the
> availability gate.


---


# 2. Requirements Guide — Remote Help — Government (GCC High) Edition

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

This edition targets the **US sovereign cloud**. The **first requirement is availability** — it is the
gate that decides whether the rest of this guide applies to a Remote Help deployment (GCC) or to the
compliant alternative (GCC High / DoD). Every sovereign-specific fact below is flagged **verify
against current Microsoft documentation** — availability, endpoints, and licensing in the government
clouds change over time.

## 2.0 THE GATING REQUIREMENT — Remote Help availability for your sovereign tier

**Description:** Confirm, against current Microsoft documentation, whether Remote Help is available in
*your* government cloud tier before doing anything else.
**Why:** Remote Help availability is **not uniform** across GCC / GCC High / DoD. Building a "Remote
Help for GCC High" rollout is wasted (and misdirected) effort if the feature is not there.
**Verify:** Read **Microsoft Learn — "Plan for Remote Help with Microsoft Intune"** and **"Microsoft
Intune Government Service overview."** At authoring time these state:
- **GCC** — Remote Help **supported** (except AVD). *(Intune GCC = the commercial instance.)*
- **GCC High / DoD** — Remote Help **not supported**; listed under **"features planned for GCC High and
  DoD"**, no ETA.
**Implement:**
- If **GCC** → proceed with this guide's deployment path, using the **commercial** endpoints (2.1a).
- If **GCC High / DoD** → **stop the Remote Help build**; go to the **compliant alternative**
  (Implementation Step 6 and `gcc-high-parity-notes.md` §4). Re-verify availability at deployment time
  and monitor the roadmap. **Verify against current Microsoft documentation.**

## 2.1 Correct cloud plane / national-cloud endpoints (verify against current Microsoft documentation)

**Description:** Administer on the plane that matches your tier. GCC High / DoD use the `*.us`
sovereign portals and US Gov Graph; **GCC uses the commercial `*.com` portals** because Intune GCC is
the commercial instance.
**Why:** Signing in or scripting against the wrong cloud fails or silently targets the wrong tenant.
**Verify:** You can sign in at the correct admin portal for your tier; `RHELPG-Test-Endpoints.ps1`
confirms the tenant resolves the expected endpoints; `RHELPG-Discovery.ps1` connects with the matching
`-Environment`.

| Purpose | GCC (commercial instance) | GCC High | DoD |
|---|---|---|---|
| Intune admin center | `https://intune.microsoft.com` | `https://intune.microsoft.us` | `https://intune.microsoft.us` |
| Entra admin center | `https://entra.microsoft.com` | `https://entra.microsoft.us` | `https://entra.microsoft.us` |
| Azure portal | `https://portal.azure.com` | `https://portal.azure.us` | `https://portal.azure.us` |
| Microsoft 365 admin center | `https://admin.microsoft.com` | `https://portal.office365.us` | `https://portal.office365.us` |
| Defender / security portal | `https://security.microsoft.com` | `https://security.microsoft.us` | `https://security.microsoft.us` |
| Sign-in / authentication | `https://login.microsoftonline.com` | `https://login.microsoftonline.us` | `https://login.microsoftonline.us` |
| Microsoft Graph | `https://graph.microsoft.com` | `https://graph.microsoft.us` | `https://dod-graph.microsoft.us` |
| Graph PowerShell `-Environment` | `Global` | `USGov` | `USGovDoD` |

**Implement:** Bookmark the correct portals for your tier; in scripts pass `-Environment USGov`
(GCC High) or `USGovDoD` (DoD), or `Global` for GCC. **Every endpoint in this table is flagged verify
against current Microsoft documentation** (Microsoft Learn — "Microsoft Graph national cloud
deployments" and the US Government endpoint articles). **Note there is no documented sovereign Remote
Help service endpoint for GCC High / DoD** — the commercial service endpoint (`remotehelp.microsoft.com`,
port 443, TLS 1.2) serves GCC; a GCC High / DoD endpoint does not exist because the feature is not
offered there (verify against current Microsoft documentation).

## 2.2 Remote Help licensing (only where available — verify against current Microsoft documentation)

**Description:** A **Remote Help license** — an add-on in addition to Intune Plan 1 or Plan 2 — for
**every** helper *and* sharer.
**Why:** Remote Help is a licensed add-on capability; it won't enable without the license, and both
parties must be licensed.
**Verify:** M365 admin center (correct portal for your tier) → **Billing → Licenses**; Intune →
**Tenant administration → Remote Help**.
**Implement:** Purchase the Remote Help add-on (or the Intune Suite) and assign to helpers and sharers.
**Confirm the exact SKU and its availability in your government tier (the government SKU names and
whether the add-on is offered for your tier) — verify against current Microsoft documentation.** On
GCC High / DoD this requirement is moot until the feature ships.

## 2.3 Intune enrollment + Entra registration

**Description:** Intune subscription with target devices enrolled; enrolled devices registered with
Microsoft Entra.
**Why:** Remote Help is deployed and governed through Intune; participants must be in the same tenant.
**Verify:** Intune → **Devices → All devices** (correct portal for your tier).
**Implement:** Enable automatic enrollment; enroll devices. (See global G4.)

## 2.4 Supported platforms in the government cloud (verify against current Microsoft documentation)

**Description:** In **GCC**, Remote Help supports a **subset** of platforms: Windows, Windows on ARM64,
Windows 365, Samsung and Zebra devices enrolled as Android Enterprise **dedicated** devices, and macOS
13 / 14 / 15. It is **not** supported in **Azure Virtual Desktop (AVD)**.
**Why:** Assigning the app to an unsupported platform (e.g. AVD hosts) will not deliver a working
session.
**Verify:** `winver` / device platform; confirm the platform against Microsoft Learn — "Plan for
Remote Help."
**Implement:** Scope the deployment to supported platforms only; exclude AVD. **Verify the current
supported-platform list against current Microsoft documentation.**

## 2.5 The Remote Help app

**Description:** The Remote Help application installed on participating helper and sharer devices.
**Why:** Both parties run the app (or the web app, per the supported modes) to connect.
**Verify:** App present at `C:\Program Files\Remote help\` on Windows (or run `RHELPG-Discovery.ps1`);
Microsoft AutoUpdate on macOS; Play Store app on supported Android.
**Implement:** Deploy the Remote Help app via Intune as **Required** to the relevant groups (Windows
Store/Win32, macOS, or approved Android app). Keep it auto-updating.

## 2.6 RBAC roles (Remote Help permissions)

**Description:** Intune RBAC granting the Remote Help permissions — **View screen**, **Take full
control**, **Elevation**, **Unattended** (Android dedicated only), plus **Remote Tasks — Offer remote
assistance** and **Remote Assistance Connector — Read**.
**Why:** A helper needs *Offer remote assistance* + *Remote Assistance Connector — Read* + at least one
Remote Help permission. Least privilege keeps view-only for tier-1 and full control for tier-2.
**Verify:** Intune → **Tenant administration → Roles**; the built-in **Help Desk Operator** role
includes the Remote Help permissions.
**Implement:** Assign **Help Desk Operator** (or a custom role with the specific Remote Help
permissions) to help-desk staff, scoped to a **user** scope group (the *All Devices* scope does **not**
include unenrolled devices). Use `RHELPG-Set-RoleScope.ps1` (default `-WhatIf`). **Note:** on GCC High /
DoD the Remote Help permissions may not be present in the role catalog until the feature ships —
verify against current Microsoft documentation.

## 2.7 Conditional Access for helpers (Windows/macOS only — verify against current Microsoft documentation)

**Description:** Optional Conditional Access requiring MFA or a compliant device for helper accounts,
which hold elevated access.
**Why:** A compromised helper account is high-impact; CA reduces the blast radius.
**Verify:** Entra → **Protection → Conditional Access** (correct portal for your tier).
**Implement:** Scope a CA policy to the helper group. **Conditional Access for Remote Help is supported
only on Windows and macOS** — verify against current Microsoft documentation.

## 2.8 Network access to the Remote Help service (verify against current Microsoft documentation)

**Description:** Outbound HTTPS (port 443) from helpers and sharers to the Remote Help service
endpoints; no SSL inspection of that traffic.
**Why:** Sessions are brokered through the cloud service over TLS 1.2 (RDP).
**Verify:** Helpers and sharers can reach the Remote Help endpoints (the app connects).
**Implement:** Allow the published Remote Help / Intune service URLs through proxy/firewall and
**exclude them from SSL inspection**. **Confirm the exact endpoint list for your tier against current
Microsoft documentation** ("Network endpoints for Remote Help").

## 2.9 Pilot group + (GCC High/DoD) compliant-alternative decision

**Description:** An Entra security group for a pilot (helpers + pilot sharers). For GCC High / DoD, a
documented **compliant-alternative** decision instead of a Remote Help build.
**Why:** Every deployment is piloted; and where Remote Help is unavailable, the buyer needs a governed
substitute, not a gap.
**Verify:** Entra → **Groups**; the pilot group exists. For GCC High / DoD, the alternative is chosen
(see `gcc-high-parity-notes.md` §4).
**Implement:** Create `RemoteHelp – GCCH – Pilot` (helpers + pilot sharers). For GCC High / DoD, select
a compliant alternative within your authorization boundary (Implementation Step 6).

---
## Checklist
- [ ] **Availability gate resolved** — Remote Help confirmed available (GCC) or not (GCC High/DoD) per current Microsoft docs
- [ ] Correct cloud plane for your tier (`*.us` for GCC High/DoD; commercial for GCC) — `RHELPG-Test-Endpoints.ps1`
- [ ] Remote Help license (add-on) assigned to helpers **and** sharers (where available)
- [ ] Devices enrolled in Intune and Entra-registered
- [ ] Target platforms supported (not AVD)
- [ ] Remote Help app deployed — `RHELPG-Discovery.ps1`
- [ ] RBAC (Remote Help permissions) assigned via a user scope group — `RHELPG-Set-RoleScope.ps1`
- [ ] Conditional Access for helpers (Windows/macOS) considered
- [ ] Network allows Remote Help endpoints; no SSL inspection
- [ ] Pilot group created — or (GCC High/DoD) compliant alternative selected


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — Remote Help — Government (GCC High) Edition

Run after Implementation. **Test 0 is the gate** — everything after it depends on which branch you are
in. All sovereign specifics are **verify against current Microsoft documentation**.

## Test 0 — Availability gate resolved (do this first)
**Do:** Confirm Remote Help's status for your tier per current Microsoft docs; run
`RHELPG-Test-Endpoints.ps1` and `RHELPG-Discovery.ps1`.
**Expected:**
- **GCC** → Remote Help supported; tenant resolves the **commercial** endpoints; proceed to Path A tests
  (1–7).
- **GCC High / DoD** → Remote Help **not** present; tenant resolves the **`*.us`** endpoints; proceed to
  Path B tests (A1–A3).
**PASS:** the branch is correctly identified and matches the endpoints observed. **FAIL:** a GCC tenant
on `*.us`, a GCC High/DoD tenant on `.com`, or an attempt to configure a Remote Help blade that isn't
there.

---

## Path A — Remote Help available (GCC)

## Test A1 — Correct (commercial) plane
**Do:** Sign in at `https://intune.microsoft.com`; run `RHELPG-Test-Endpoints.ps1`.
**Expected:** Commercial endpoints resolve for the GCC (commercial-instance) tenant.

## Test A2 — Remote Help enabled with chosen options
**Do:** Intune → **Tenant administration → Remote Help**; or `RHELPG-Validate.ps1`.
**Expected:** Remote Help is **Enabled** with your chosen unenrolled / full-control / chat options.

## Test A3 — App deployed
**Do:** On pilot helper and sharer devices run `RHELPG-Discovery.ps1`.
**Expected:** The Remote Help app is present (assignment shows Succeeded in Intune → Apps). AVD hosts
are excluded.

## Test A4 — RBAC gates access (least privilege)
**Do:** A non-help-desk account attempts **Give help**; a view-only helper attempts full control.
**Expected:** Only the RBAC-holding helpers can give help; view-only cannot take full control.

## Test A5 — Governed session with consent
**Do:** Sharer requests help; helper joins and signs in with Entra; sharer consents.
**Expected:** Session connects; the sharer sees the on-screen indicator; the granted capability behaves
per the role.

## Test A6 — Compliance surfaced
**Do:** During the session, observe the compliance indicator shown to the helper.
**Expected:** The helper sees the device compliance state before assisting.

## Test A7 — Session audited
**Do:** `RHELPG-Report.ps1` (or Intune → Tenant administration → Remote Help usage).
**Expected:** The session appears with helper, sharer, and timestamp.

---

## Path B — Remote Help NOT available (GCC High / DoD)

## Test B1 — Sovereign plane confirmed
**Do:** Sign in at `https://intune.microsoft.us`; run `RHELPG-Test-Endpoints.ps1 -Environment USGov`
(or `USGovDoD`).
**Expected:** The tenant resolves the `*.us` (or DoD) endpoints — not commercial.

## Test B2 — Remote Help absence confirmed (expected)
**Do:** Look for the Remote Help tenant blade; run `RHELPG-Discovery.ps1 -Environment USGov`.
**Expected:** **Remote Help is not present** — this is the correct, expected result for GCC High / DoD.
A "missing" Remote Help here is a **PASS** of the availability check, not a failure to fix.

## Test B3 — Compliant alternative validated
**Do:** Exercise the chosen alternative (from `gcc-high-parity-notes.md` §4) end-to-end.
**Expected:** Remote assistance works and is authenticated, least-privilege, consent-based, and audited,
with authorization evidence recorded for your IL/ATO.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Availability** | Test 0 passes — the branch matches the tier and endpoints |
| **Path A pilot pass** | Tests A1–A7 pass for the pilot helpers/sharers |
| **Path A wave pass** | Tests A3, A5, A7 pass before each production wave |
| **Path B pass** | B1–B2 confirm the gap on the sovereign plane; B3 validates the compliant alternative |


---


# 6. Troubleshooting Guide — Remote Help — Government (GCC High) Edition

Use `RHELPG-Discovery.ps1` for tenant/feature/RBAC state, `RHELPG-Test-Endpoints.ps1` for the cloud
plane, `RHELPG-Validate.ps1` for PASS/FAIL, `RHELPG-Report.ps1` for an export, and
`RHELPG-Set-RoleScope.ps1` (default `-WhatIf`) to assign RBAC. All sovereign specifics are **verify
against current Microsoft documentation**.

## A. Feature unavailable in the sovereign cloud (GCC High / DoD — check first)
| Symptom | Cause | Remediation |
|---|---|---|
| No Remote Help blade in the `*.us` Intune portal | Remote Help is **not offered on GCC High / DoD** (planned, no ETA) | **Expected.** Do not try to force it. Use the compliant alternative (`gcc-high-parity-notes.md` §4). Re-verify availability against current Microsoft documentation and monitor the roadmap |
| `RHELPG-Discovery.ps1` reports Remote Help "not present" on GCC High/DoD | Same — feature absent on the tier | This is the correct discovery result, not a fault. Follow Path B |
| `RHELPG-Set-RoleScope.ps1` can't find a Remote Help role | Remote Help RBAC permissions not present in the sovereign tenant | Expected on GCC High/DoD; use the alternative. On GCC, confirm you're on the commercial plane |
| A stakeholder expects "Remote Help for GCC High" | Assumed commercial parity | Show them the availability finding (`gcc-high-parity-notes.md` §0); it is planned, not available. Adopt when it ships |

## B. Wrong / commercial endpoints (plane mismatch)
| Symptom | Cause | Remediation |
|---|---|---|
| GCC High/DoD account not recognized; portal shows `.com` | Signed in to a Commercial portal | Use the sovereign portals: `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`, `portal.office365.us`, `security.microsoft.us` |
| Script auth fails / targets the wrong tenant | `Connect-MgGraph` defaulted to Commercial Graph | Pass **`-Environment USGov`** (GCC High) or **`USGovDoD`** (DoD); confirm with `RHELPG-Test-Endpoints.ps1` |
| You're on `*.us` but the GCC tenant isn't found | **GCC is the commercial Intune instance** | For a GCC tenant use the **commercial** portals and `-Environment Global` — GCC does **not** use `*.us` |
| A blade/menu is missing | Commercial-only or not-yet-in-sovereign feature | Check `gcc-high-parity-notes.md`; verify against current Microsoft documentation |

## C. Licensing mismatch (where Remote Help is available)
| Symptom | Cause | Remediation |
|---|---|---|
| "Enable" greyed out / helper can't start | No Remote Help license, or only one party licensed | Assign the **Remote Help add-on** (or Intune Suite) to **both** helpers **and** sharers; confirm the **government SKU** is offered for your tier (verify against current Microsoft documentation) |
| License present but feature off | Tenant not refreshed | Wait/refresh; re-open **Tenant administration → Remote Help** |

## D. Consent / RBAC differences
| Symptom | Cause | Remediation |
|---|---|---|
| Helper can't **Give help** | Missing Remote Help permissions | Assign **Help Desk Operator** (or a custom role with *Offer remote assistance* + *Remote Assistance Connector — Read* + a Remote Help permission); `RHELPG-Set-RoleScope.ps1` |
| Helper can't see the sharer's device | Sharer not in the helper's **scope**; used *All Devices* scope | Scope to a **user** group — *All Devices* excludes unenrolled devices |
| Helper can view but not control | View-only role, or full control disabled tenant-wide | Grant full control by role, and enable it in **Tenant administration → Remote Help** |
| No on-screen consent indicator expected | Unattended (Android dedicated) or a misconfiguration | Attended sessions require consent + show an indicator; unattended is Android-dedicated only, used sparingly |
| Conditional Access for helpers not applying | CA for Remote Help is **Windows/macOS only** | Verify against current Microsoft documentation; scope the helper CA policy to those platforms |

## E. Session won't connect (where available)
| Symptom | Cause | Remediation |
|---|---|---|
| Connection fails | Network/endpoints blocked, or SSL inspection | Allow the Remote Help service URLs (port 443, TLS 1.2) and **exclude them from SSL inspection**; confirm the endpoint list for your tier (verify against current Microsoft documentation) |
| Cross-tenant help fails | All participants must be in the **same tenant** | Provide in-tenant devices (or Windows 365/AVD joined to the tenant) to outsourced helpdesk |
| AVD session unsupported | Remote Help is **not** supported in AVD (GCC) | Exclude AVD hosts; use it on supported Windows/Windows 365/macOS/Android-dedicated only |

## F. Scripts
```powershell
# Confirm the cloud plane for your tier
.\RHELPG-Test-Endpoints.ps1 -Environment USGov      # GCC High  (USGovDoD = DoD; Global = GCC/Commercial)
# Read-only posture: cloud context, Remote Help presence, RBAC
.\RHELPG-Discovery.ps1 -Environment USGov
# PASS/FAIL readiness (NOT-AVAILABLE is the expected Remote Help result on GCC High/DoD)
.\RHELPG-Validate.ps1 -Environment USGov
# Export status to CSV
.\RHELPG-Report.ps1 -Environment USGov -CsvPath C:\Temp\rhelpg-status.csv
# Assign RBAC role/scope (state change — defaults to -WhatIf; add -WhatIf:$false to apply)
.\RHELPG-Set-RoleScope.ps1 -MembersGroupName "RemoteHelp - GCCH - Pilot" -ScopeGroupName "RemoteHelp - GCCH - Pilot"
```
> All five scripts default to the sovereign plane (`-Environment USGov`; use `USGovDoD` for DoD, or
> `Global` for a GCC/commercial-instance tenant). None require you to edit angle-bracket placeholders.

## G. When to escalate
On a tier where Remote Help **is** available: if licensing is assigned to both parties, Remote Help is
enabled, the app is installed, RBAC and scope are correct, and sessions still fail, capture the app
version and a session error and open a Microsoft Intune support case — **note the government tenant tier
(GCC / GCC High / DoD)** so it routes to the correct support queue. On GCC High / DoD where the feature
is **absent**, there is nothing to escalate as a bug — track the roadmap and use the compliant
alternative. **Re-verify availability against current Microsoft documentation.**


---


# 7. Best Practices — Remote Help — Government (GCC High) Edition

- **Resolve the availability gate before anything else.** Confirm Remote Help's status for *your* tier
  (GCC vs GCC High / DoD) against current Microsoft documentation before you plan a rollout. It is the
  item most likely to have changed.
- **Never assume commercial parity, and never fabricate a `*.us` deployment.** If Remote Help is not
  available for GCC High / DoD, say so and move to the compliant alternative — do not force a
  configuration that isn't there.
- **Know that Intune GCC is the commercial instance.** For GCC, administer at the **commercial** portals
  (`intune.microsoft.com`) and script with `-Environment Global` — not `*.us`. Only GCC High / DoD use
  the `*.us` plane.
- **Verify every sovereign specific.** Endpoints, government SKU names, supported platforms, network
  endpoints, and Conditional Access scope all carry a **verify against current Microsoft documentation**
  flag — honor it.
- **Assign least-privilege RBAC.** View-only for tier-1, full control only where required; scope to a
  **user** scope group (the *All Devices* scope excludes unenrolled devices).
- **Protect helper accounts with Conditional Access** (MFA / compliant device) — supported on
  Windows/macOS only.
- **Deploy the app as Required** to helper and sharer groups; **exclude AVD** (unsupported in GCC).
- **Pilot a real, governed session** — helper + sharer + consent + capability — before broad rollout.
- **Keep the app current** (Windows Update / Microsoft AutoUpdate / Play Store) so features and fixes
  stay in place.
- **Don't SSL-inspect Remote Help traffic;** exclude the service endpoints from inspection.
- **Communicate consent and audit.** Sessions are consensual, on-screen-indicated, and logged (~30 days);
  no recordings are stored — document this to build trust and satisfy privacy stakeholders.
- **For GCC High / DoD, choose an *authorized* alternative.** Match your IL/ATO; never drop in an
  unauthorized consumer/commercial tool to fill the gap.
- **Monitor the roadmap.** Remote Help is *planned* for GCC High / DoD; re-run the availability gate
  periodically and adopt it (Path A) when it ships for your tier.
- **Document the decision.** Record which branch you took, the availability evidence, the RBAC role
  model, and (Path B) the alternative's authorization — for audits.


---


# 8. Deliverables Summary — Remote Help — Government (GCC High) Edition

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The availability-first business case; deploy-vs-alternative branches |
| 1. Solution Overview | The sovereign-cloud problem, the availability-first principle, what this adapts from commercial |
| 2. Requirements Guide | Every prerequisite — starting with the **availability gate** — Verify / Implement-if-missing, per tier |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | **STEP 1 = establish availability (gate)**, then Path A (deploy on GCC) or Path B (compliant alternative for GCC High / DoD) |
| GCC High Parity Notes | Availability finding, endpoint/feature parity table, and the compliant alternative for the gap |
| 5. Testing Guide | Pass/fail gates for both branches |
| 6. Troubleshooting Guide | Sovereign-specific issues and the alternative path |
| 7. Best Practices | Field-proven recommendations for the government context |

## PowerShell scripts (US Gov Graph aware — `-Environment USGov` / `USGovDoD`)
| Script | What it does |
|---|---|
| `RHELPG-Discovery.ps1` | Read-only: sovereign-cloud tenant/endpoint context, Remote Help presence, and Remote Help RBAC roles |
| `RHELPG-Validate.ps1` | PASS/FAIL: correct national-cloud endpoints, Remote Help deployed (if available for the tier), RBAC set |
| `RHELPG-Report.ps1` | Deployment + role status export to CSV |
| `RHELPG-Test-Endpoints.ps1` | Read-only: confirms the tenant resolves the US Gov national-cloud endpoints, not commercial |
| `RHELPG-Set-RoleScope.ps1` | The only state-changer: assigns a Remote Help RBAC role/scope in the sovereign tenant — **defaults to `-WhatIf`** |

## What the buyer receives
- This guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess (incl. availability gate) → Configure → Pilot → Validate → Expand.**

## Outcome
The correct, honest outcome for your government tier — Remote Help deployed on GCC, or a compliant
alternative where it isn't available on GCC High / DoD — governed, least-privilege, consent-based, and
audited, verified against current Microsoft documentation rather than assumed from commercial.
