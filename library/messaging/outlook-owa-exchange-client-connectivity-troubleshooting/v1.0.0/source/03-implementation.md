# Diagnostic Playbook — symptom → root cause

This is the core of the toolkit: a **layered decision tree** for Outlook / OWA / mobile
client-connectivity problems on Exchange Online and hybrid. Work it the house way —
**Assess → Design → Configure → Pilot → Validate → Expand** for *adopting* the method
(see below) — but for an individual ticket you **enter at the reported symptom** (§B) and
walk down the layers, running the **one exact test named at each node** and following its
**pass/fail branch**.

> **Golden rules (apply at every node):**
> 1. **Reproduce, isolate, resolve.** Confirm the symptom, then localize the failing *layer*
>    before changing anything.
> 2. **Walk layers in order:** Discovery (Autodiscover) → Protocol → Auth → Client. An early
>    failure masquerades as a later one.
> 3. **Compare against known-good:** the **`ConnTest`** mailbox (§Requirements 2) and a
>    known-good client / **OWA**. `<affected user on affected client>` vs `ConnTest on same
>    client` vs `affected user in OWA` triangulates server-vs-client instantly.
> 4. **Read-only first.** Every diagnostic here is read-only. Any *change* goes through change
>    control and the remediation script's `-Commit` gate.

---

## A. Adopting the method (Assess → Configure), do once

Before the tree is your standard runbook, stand it up:

1. **Assess** the estate: Outlook builds and cached-vs-online mode, mobile client mix
   (Outlook mobile/Graph vs legacy EAS), cloud-only vs hybrid, and Conditional Access posture.
   Pull the top client-connectivity ticket categories from the last 90 days.
2. **Configure** the toolkit:
   - Install the modules: `Install-Module ExchangeOnlineManagement`,
     `Install-Module Microsoft.Graph`.
   - Grant the least-privilege diagnostic role (Requirement 1) and provision **`ConnTest`**
     (Requirement 2).
   - Dry-run all five scripts against `ConnTest` (all read-only / `-WhatIf`) to confirm access.
3. **Pilot** the tree on a named pilot group and a batch of live tickets; **Validate** against
   the gates in `05-testing.md`; then **Expand** to the full service desk.

---

## B. Entry — pick the symptom

| # | Reported symptom | Go to |
|---|------------------|-------|
| 1 | New profile won't set up / "can't connect to the server" on setup | **Node D1 (Discovery)** |
| 2 | Outlook was working, now disconnects / repeating password prompts | **Node D3 (Auth)** first, then D2/D4 |
| 3 | Credential prompt never accepts the password (auth loop) | **Node D3 (Auth)** |
| 4 | Free/busy shows hash marks (`/////`) — especially hybrid | **Node D5 (Free/busy)** |
| 5 | OWA works but Outlook desktop doesn't (or vice-versa) | **Node D2 (Protocol)** |
| 6 | Mobile mail (iOS/Android) won't sync | **Node D6 (Mobile)** |
| 7 | Only one user; everyone else is fine | Start at **D0**, expect a **per-mailbox** cause |
| 8 | Many users at once | Start at **D0**, expect a **DNS / CA / service** cause |

---

## C. D0 — Scope the blast radius (always first)

**Test:** Is it one user, one client, one site, or everyone?
- Run the health helper script (`Get-ClientConnectivityScope.ps1`) or check the **service
  health** dashboard (M365 admin center → **Health → Service health**, Exchange Online).
- Compare the affected user in **OWA** (browser, off-network if possible) vs Outlook desktop.

**Branch:**
- **Everyone / many** and **OWA also fails** → suspect a **service incident** or a **tenant-wide
  DNS / Conditional Access** change → jump to **D1** (DNS) and **D3** (CA), skip client work.
- **One user, OWA works, Outlook fails** → **per-mailbox / client** cause → **D1 → D2 → D3 → D4**.
- **One client, all mailboxes fail on it, fine elsewhere** → **client machine** cause → **D4**.

---

## D1 — Discovery layer (Autodiscover)

**Symptom fit:** can't set up a profile; "can't connect to server" on first launch; hybrid
free/busy failing at the discovery step.

### D1.1 — Does Autodiscover resolve to the right endpoint?
**Test (external, authoritative):** Remote Connectivity Analyzer → **Outlook Autodiscover**
test for the affected user (`testconnectivity.microsoft.com`; **verify the sovereign RCA host
for GCC High/DoD**). Also:
- DNS: `Resolve-DnsName autodiscover.<domain> -Type CNAME` — cloud-only expects
  `autodiscover.outlook.com` (**Commercial**; verify sovereign host).
- Autodiscover v2 JSON:
  `Invoke-RestMethod "https://autodiscover.<domain>/autodiscover/autodiscover.json?Email=<user>&Protocol=Autodiscoverv1"`
- The endpoint-test script (`Test-AutodiscoverEndpoints.ps1`) runs these together per user.

**Branch:**
- **RCA Autodiscover PASS** → discovery is healthy → go to **D2 (Protocol)**.
- **RCA Autodiscover FAIL, DNS wrong/missing** → **root cause: Autodiscover DNS**. Remediate:
  stage the correct `autodiscover.<domain>` record (cloud-only → `autodiscover.outlook.com`;
  hybrid → per coexistence design) with the DNS owner **under change control**; re-test RCA.
- **RCA PASS but domain-joined Outlook still misbehaves** → suspect a stale **SCP** or client
  cache → **D1.2**.

### D1.2 — Client-side discovery (domain-joined Outlook)
**Test:** On the client, hold **Ctrl** + right-click the Outlook tray icon → **Test E-mail
AutoConfiguration** (uncheck Guessmart; check "Use AutoDiscover") and read the returned URLs /
log. Check the SCP (hybrid/on-prem): `Get-ClientAccessService | Select
Name,AutoDiscoverServiceInternalUri`.

**Branch:**
- Returns the **correct** EXO/hybrid endpoints → discovery fine on this client → **D2**.
- Returns a **stale/wrong** URL or errors → clear the local **autodiscover cache** (delete the
  cached `Autodiscover*.xml` under the Outlook profile and any stale registry Autodiscover
  overrides — **verify current per Outlook build**), then re-run. In hybrid, correct the SCP
  `AutoDiscoverServiceInternalUri` if it points at a decommissioned server (change control).

---

## D2 — Protocol layer (MAPI/HTTP · EWS · OWA · EAS)

**Symptom fit:** "OWA works but Outlook doesn't" (or the reverse); a specific feature
(free/busy, OOF, add-in) fails while mail flows.

### D2.1 — Is the protocol enabled on the mailbox?
**Test:** `Get-CASMailbox <user> | Format-List
MapiEnabled,EwsEnabled,OWAEnabled,ActiveSyncEnabled,*Enabled` and compare against `ConnTest`.
Also check the plan default: `Get-CASMailboxPlan | Format-List`. The assessment script
(`Get-ClientConnectivityAssessment.ps1`) reports this per user.

**Branch:**
- The failing client's protocol is **`False`** (e.g. `MapiEnabled : False` while OWA works)
  → **root cause: protocol disabled on mailbox**. Remediate via the remediation script
  (`Set-MailboxProtocolAccess.ps1`, dry-run by default; `-Commit` gated) or
  `Set-CASMailbox <user> -MapiEnabled $true` under change control; re-test.
- All required protocols **`True`** → protocol is enabled → the fault is **transport/auth**,
  not enablement → **D2.2**.

### D2.2 — Does the protocol actually connect (server-authoritative)?
**Test:** Server-side connectivity cmdlets and RCA:
- `Test-OutlookConnectivity -MailboxId <user>` (MAPI/HTTP path health).
- `Test-OutlookWebServices -Identity <user>` (Autodiscover + EWS + OOF + free/busy provider
  reachability). *Note: availability of these cmdlets/parameters is version-dependent —
  verify in your tenant/on-prem build.*
- RCA → **Outlook Connectivity**, **Exchange ActiveSync**, and **EWS** tests.

**Branch:**
- Cmdlet / RCA **PASS** → protocol connects server-side; the client can't → **client layer D4**.
- **EWS fails** specifically → an EWS-only feature (free/busy/OOF/add-in) breaks while MAPI
  mail works → check `EwsEnabled`, `EwsAllowOutlook`, and any **EWS application access policy**
  (`Get-CASMailbox <user> | Select Ews*`); for cross-org free/busy go to **D5**.
- **PASS server-side but user still fails and OWA is fine** → strongly implies **auth** or
  **client** → **D3**, then **D4**.

---

## D3 — Authentication layer (modern auth · Conditional Access · MFA)

**Symptom fit:** repeating credential prompts; auth loop; "your organization needs more
information"; worked yesterday, blocked today (policy change).

### D3.1 — Modern auth in effect and no legacy-auth block?
**Test:** `Get-OrganizationConfig | Select OAuth*`;
`Get-CASMailbox <user> | Select *AuthenticationPolicy*`; the auth/CA checker script
(`Test-ModernAuthConditionalAccess.ps1`) summarizes org + per-user auth posture.

**Branch:**
- Modern auth **on**, no restrictive auth policy → **D3.2**.
- A **Basic-Auth-only** legacy client or an authentication policy blocking the app → **root
  cause: unsupported/blocked legacy auth** → move the user/app to a modern-auth client
  (change control).

### D3.2 — Is Conditional Access blocking this client/device?
**Test (authoritative):** Entra **sign-in logs** for the user → filter by the failing **client
app** and read **Status / failure reason** and the **Conditional Access** tab (which policy,
Success/Failure/Not applied). Cross-reference **Entra → Protection → Conditional Access**
policies (device compliance, Hybrid Azure AD Join, app-based / Intune app protection, location).

**Branch:**
- A CA policy shows **Failure** for this sign-in (e.g. "device not compliant", "require
  approved client app") → **root cause: Conditional Access grant unmet**. Resolve the *device/
  app* condition (enroll/comply, use an approved client) — **do not** weaken the CA policy as a
  fix; if the policy is misscoped, correct scope via the CA owner under change control.
- **MFA registration incomplete** ("more information required") → complete MFA registration.
- CA **Not applied / Success** but client still loops → **stale token / cached credential** →
  **D4** (Credential Manager / re-auth).

---

## D4 — Client / profile / OST layer (isolate last)

**Symptom fit:** server layers all PASS; one client or one profile misbehaves; corrupt data
file; add-in interference.

### D4.1 — Is it the mailbox or the client? (substitution test)
**Test:** (a) Set up **`ConnTest`** on the *affected* client; (b) set up the *affected user* on
a *known-good* client (or confirm the affected user works in **OWA**).

**Branch:**
- **`ConnTest` also fails on this client** → **client machine** cause (proxy/SSL-inspection,
  credential store, Office build) → D4.2/D4.3.
- **Affected user works elsewhere / in OWA** → **local profile / OST / cache** cause → D4.2.

### D4.2 — Profile / OST / autodiscover-cache reset
**Test/Remediate (client-side, low-risk, reversible):**
- Recreate the **Outlook profile** (Control Panel → Mail → **Show Profiles** → add a new
  profile; keep the old one until validated).
- For a suspected corrupt **OST**, close Outlook and let cached mode rebuild the OST from the
  server (rename, don't delete, until confirmed) — **verify current OST path/behavior for the
  Outlook build**.
- Clear the stale **Autodiscover cache** (D1.2) and any machine-wide entries in **Windows
  Credential Manager** for `MicrosoftOffice*` / the mail host, then re-auth.
- Run **SARA** (Support and Recovery Assistant) → Outlook scenario for automated fixes.

### D4.3 — Machine / network interference
**Test:** Compare RCA (external, off-network) vs on-network behavior (from **D0**).
**Branch:**
- **Works off-network, fails on-network** → an **SSL-inspecting proxy / firewall / CASB** is
  breaking Autodiscover or the OAuth flow → engage network owner; defer the security appliance's
  console to its vendor docs.
- Add-in suspected → start Outlook in **safe mode** (`outlook /safe`); if it connects, disable
  add-ins to isolate.

---

## D5 — Hybrid free/busy (cross-org availability)

**Symptom fit:** free/busy shows **hash marks** (`/////`) between on-prem and Exchange Online
mailboxes.

**Test (on-prem Exchange Management Shell + RCA):**
- `Get-OrganizationRelationship | Format-List`; `Get-FederationTrust`;
  `Test-OrganizationRelationship -Identity <rel> -UserIdentity <on-prem user>`.
- RCA → **Free/Busy** test (target the cross-org user).
- Confirm **Autodiscover of the *target* org** (D1) and **EWS** reachability (D2.2) both ways.

**Branch:**
- `Test-OrganizationRelationship` **FAIL** → fix the relationship / OAuth (or legacy federation)
  config with the hybrid owner (change control).
- Relationship OK but **EWS/Autodiscover of the other org fails** → resolve that org's D1/D2
  first — free/busy inherits their health.
- Both OK, still hash marks for **one user** → check that user's **`EwsEnabled`** and any EWS
  application access policy (**D2.2**).

---

## D6 — Mobile (Outlook mobile / Graph vs legacy EAS)

**Symptom fit:** iOS/Android mail won't sync or set up.

**Test:**
- Identify the client: **Outlook for iOS/Android / new Outlook** use Microsoft sync
  technology / **Graph** (not EAS); native/older mail apps use **Exchange ActiveSync**.
- `Get-CASMailbox <user> | Select ActiveSyncEnabled`; `Get-MobileDevice -Mailbox <user>`;
  `Get-MobileDeviceStatistics`; the OWA/EAS mailbox policy (`Get-CASMailbox` /
  `Get-MobileDeviceMailboxPolicy`). RCA → **Exchange ActiveSync** test.

**Branch:**
- **`ActiveSyncEnabled : False`** and the client uses EAS → enable EAS (remediation script /
  `Set-CASMailbox -ActiveSyncEnabled $true`, change control) — or move the user to **Outlook
  mobile** (Graph), the recommended client.
- Device is **quarantined / blocked** by mobile device policy or a **Conditional Access
  app-protection** grant → the fault is **auth/policy (D3)**, resolve there (enroll in Intune /
  approved app), not by disabling the policy.
- Autodiscover for the mobile setup fails → **D1**.

---

## E. Pass/fail gates & rollback (for any change made during triage)

Any remediation triggered above (DNS Autodiscover fix, protocol re-enable, SCP correction,
relationship fix) is a **production change** — apply it under change control with these gates
and rollbacks:

| Change | PASS gate | Rollback |
|--------|-----------|----------|
| Autodiscover DNS corrected | RCA **Autodiscover** PASS; new profile sets up for `ConnTest` + affected user | Restore prior DNS record (kept as pre-change note) |
| Protocol re-enabled (`Set-CASMailbox`) | `Get-CASMailbox` shows `True`; `Test-OutlookConnectivity` PASS; client connects | `Set-CASMailbox … $false` (prior value recorded by the remediation script's dry-run) |
| SCP `AutoDiscoverServiceInternalUri` corrected | `Test E-mail AutoConfiguration` returns correct URL | Restore prior URI |
| Org relationship / federation fix | `Test-OrganizationRelationship` PASS; RCA free/busy PASS | Revert relationship config to recorded prior state |

**Rule:** the remediation script defaults to a **dry-run report** that records the *current*
value before any change; you `-Commit` only after the change is approved, and you keep the
recorded prior value as the rollback.
