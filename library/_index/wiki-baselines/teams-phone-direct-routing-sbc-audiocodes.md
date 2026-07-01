# Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

> **Version 1.0.0** · Category: Azure Solutions · Solution code: TEAMSSBC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

## The outcome

Your people place and receive normal phone calls — to mobiles, landlines, and emergency services — directly from Microsoft Teams, using your own carrier and your own AudioCodes Session Border Controller (SBC). One application (Teams) replaces separate desk-phone and calling systems, while you keep full control of your telephone numbers, carrier contracts, and call routing.

## What we deliver

This solution productizes the complete **Microsoft Teams Phone Direct Routing** build with an **AudioCodes SBC**:

- **Pair the SBC** to your Microsoft tenant as a Direct Routing gateway, with healthy, monitored signaling.
- **Build the voice routing stack** — phone-number normalization, call routes, usages, and a routing policy — using clear, self-documenting, named objects.
- **Enable users** with the right licensing, calling policy, and phone numbers.
- **Pilot, validate, and expand** against explicit pass/fail quality gates, including a controlled emergency-calling check.
- **Hand over operable tooling** — five PowerShell scripts for discovery, validation, reporting, safe remediation, and configuration — so your team can run and grow the deployment with confidence.

The Microsoft side is delivered concretely and correctly. The AudioCodes device configuration is specified as a precise requirements checklist (public FQDN, public CA certificate, encrypted TLS signaling and SRTP media, SIP keep-alive) and handed to your network/voice team with vendor documentation, so nothing about the appliance is guessed.

## Why it matters

- **Cost and choice.** Keep your existing SIP trunk and negotiated rates instead of per-user calling plans, and serve regions where calling plans are unavailable.
- **Continuity and control.** Own your numbers and routing; add a second SBC for failover; interconnect existing telephony where needed.
- **Safety and compliance.** Emergency calling is designed, routed, and validated deliberately — not left to chance — because under Direct Routing that responsibility is yours.
- **Low risk.** A phased, gated rollout (Assess → Pair SBC → Configure Voice Routing → Assign Users → Pilot → Validate → Expand) with read-only discovery, dry-run-by-default changes, and documented rollback keeps a critical service safe.

## The result

Pilot users calling through your SBC on day one, an SBC that reports healthy with correct caller ID and validated emergency routing, and a repeatable, documented process to extend calling across the organization.


---


# 1. Solution Overview — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

## What this solution delivers

This solution delivers Public Switched Telephone Network (PSTN) calling inside **Microsoft Teams Phone** by way of **Direct Routing**, using a customer-owned or partner-owned **Session Border Controller (SBC)** — an **AudioCodes** appliance (for example, the Mediant family) — as the bridge between Microsoft Phone System and a SIP trunk or carrier. Users place and receive ordinary phone calls (to mobiles, landlines, and emergency services) from the Teams client on desktop, mobile, and web, while the organization keeps full control of its carrier contracts, number ranges, and call routing.

Direct Routing is the connectivity model in which **you** (not Microsoft) own the PSTN breakout. Microsoft Phone System provides the cloud calling control plane; the SBC terminates Microsoft's certified SIP signaling on one side and the carrier's trunk on the other. This solution productizes the entire Microsoft-side build — pairing the SBC, constructing the voice routing stack, assigning users, piloting, and validating — and gives you a concept-level checklist for the AudioCodes device so your network/voice team (or AudioCodes' own documentation) can complete the appliance configuration accurately.

## Why Direct Routing with an SBC

- **Carrier choice and cost control.** Keep your existing SIP trunk provider, negotiated rates, and number inventory instead of buying Microsoft Calling Plans per user.
- **Global and hybrid reach.** Serve countries and regions where Microsoft Calling Plans are unavailable, and interconnect legacy PBX, analog devices, contact-center, or paging systems behind the same SBC.
- **Granular routing.** Express least-cost routing, failover trunks, branch-specific breakout, and number-manipulation rules in the Teams voice routing stack and on the SBC.
- **Single client.** Users get one app (Teams) for chat, meetings, and PSTN calling — no separate desk phone deployment required (though certified phones are supported).

## Scope of this engagement

In scope (Microsoft side, built and validated here):

1. **Pair the SBC** to the tenant as a Direct Routing PSTN gateway (`New-CsOnlinePSTNGateway`) using its public Fully Qualified Domain Name (FQDN) under a verified SIP domain.
2. **Build the voice routing stack**: PSTN usages, voice routes (with carrier dial patterns), a voice routing policy, and a tenant dial plan with named normalization rules.
3. **Assign Phone System and voice** to pilot users: license check, voice routing policy grant, and phone-number assignment (`Set-CsPhoneNumberAssignment`).
4. **Pilot, validate, and expand**: confirm SIP OPTIONS health, outbound/inbound calling, caller ID, and emergency-call routing, then roll out by ring.

At the concept/checklist level (deferred to AudioCodes documentation and your network team):

- AudioCodes SBC device configuration — SIP interfaces, TLS contexts/certificates, IP Profiles, Proxy Sets, IP-to-IP routing rules, media (SRTP) handling, and NAT traversal. This solution specifies **what** the SBC must satisfy to interoperate with Teams (FQDN, public CA certificate, TLS 5061 signaling, SRTP media, SIP OPTIONS keep-alive) but does **not** invent AudioCodes menu paths.

Out of scope: carrier/SIP-trunk procurement and provisioning, PBX migration cutover engineering, contact-center platform integration, and analog/paging gateway design (these are referenced where they affect routing but are separate engagements).

## Phase model

This solution follows a disciplined phase model, reused verbatim across the implementation, testing, and best-practice documents:

**Assess → Pair SBC → Configure Voice Routing → Assign Users → Pilot → Validate → Expand**

- **Assess** — inventory licensing, domains, network, SBC readiness, and emergency-calling obligations; never assume a prerequisite is already in place.
- **Pair SBC** — register the SBC FQDN as a PSTN gateway and confirm Microsoft sees it.
- **Configure Voice Routing** — create the named PSTN usages, voice routes, voice routing policy, and dial plan.
- **Assign Users** — license, grant the routing policy, and assign numbers to pilot users.
- **Pilot** — controlled calling with a small ring of real users.
- **Validate** — pass explicit gates (OPTIONS healthy/Active, outbound, inbound, caller ID, emergency).
- **Expand** — widen rings, add routes/trunks, and operationalize monitoring.

## Object naming convention

Every object you create is named with the pattern `<Purpose> – <Scope> – <Stage>` and reused verbatim across documents and scripts so the configuration is self-documenting and auditable. The canonical names used throughout this solution are:

| Object | Name |
| --- | --- |
| PSTN gateway (SBC FQDN) | `sbc01.<verified-sip-domain>` (registered as `PSTN Gateway – Primary SBC – Production`) |
| PSTN usage | `PSTN Usage – Domestic – Production` |
| PSTN usage (emergency) | `PSTN Usage – Emergency – Production` |
| Voice route | `Voice Route – Domestic Outbound – Production` |
| Voice route (emergency) | `Voice Route – Emergency – Production` |
| Voice routing policy | `Voice Routing Policy – Standard User – Production` |
| Tenant dial plan | `Dial Plan – Standard User – Production` |
| Pilot ring | `Pilot Ring – Voice Users – Stage 1` |

## Outcome

At the end of the engagement, pilot users place and receive PSTN calls in Teams through your AudioCodes SBC, the SBC shows **Active** with healthy SIP OPTIONS in the Teams admin center, caller ID presents correctly, emergency calling routes per your plan, and you have repeatable scripts (discovery, validation, reporting, remediation, and configuration) to operate and expand the deployment.


---


# 2. Requirements — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

This document enumerates every prerequisite for the engagement. Treat each requirement with the four-part discipline used throughout this solution: **Description** (what it is), **Why** (why it matters), **Verify** (how to confirm it exists), and **Implement if missing** (how to put it in place). Never assume a prerequisite is already satisfied — confirm each one in the **Assess** phase before pairing the SBC.

Category-wide prerequisites common to all Azure Solutions products (tenant, admin roles, licensing baseline, network reachability, change control, test users, rollback) are documented in `global-requirements-azure-solutions.md`. The requirements below are specific to Teams Phone Direct Routing with an AudioCodes SBC.

---

## R1 — Microsoft Teams Phone (Phone System) licensing

- **Description.** Every voice-enabled user needs the Phone System capability, included in Microsoft Teams Phone (standalone or within Microsoft 365 E5 / Office 365 E5) or added as the **Microsoft Teams Phone Standard** add-on to lower SKUs (for example E1/E3).
- **Why.** Phone System is the cloud control plane for Direct Routing. Without it, a user cannot be assigned a voice routing policy or a phone number, and calls will not route to the SBC.
- **Verify.** Microsoft 365 admin center → **Billing → Licenses**, confirm available Teams Phone / Phone System seats; or in Teams PowerShell run `Get-CsOnlineUser -Identity <user> | Select-Object FeatureTypes` and confirm `PhoneSystem` is present.
- **Implement if missing.** Purchase Teams Phone seats (or the Teams Phone Standard add-on) and assign them in Microsoft 365 admin center → **Users → Active users → (user) → Licenses and apps**, or via group-based licensing.

## R2 — AudioCodes SBC reachable on a public FQDN

- **Description.** A supported AudioCodes SBC (for example a Mediant CE/VE/appliance) that is on Microsoft's list of certified Direct Routing SBCs, reachable from the internet on a public, resolvable **FQDN** (for example `sbc01.<verified-sip-domain>`).
- **Why.** Microsoft pairs Direct Routing to the SBC by FQDN, not IP. The FQDN must resolve publicly and the SBC must be reachable by Microsoft's SIP proxy for signaling and OPTIONS keep-alive.
- **Verify.** From an external host, `nslookup sbc01.<verified-sip-domain>` resolves to the SBC's public IP; confirm the model/firmware is on Microsoft's certified SBC list with your AudioCodes documentation.
- **Implement if missing.** Provision the AudioCodes SBC, publish a public DNS A record for its FQDN, and ensure its firmware meets the certified version per AudioCodes' Direct Routing documentation.

## R3 — Public CA certificate on the SBC

- **Description.** A TLS server certificate on the SBC issued by a **public Certificate Authority** trusted by Microsoft, whose subject (or a Subject Alternative Name) matches the SBC FQDN and whose root chains to a CA in Microsoft's trusted list.
- **Why.** Direct Routing signaling is TLS-only. Microsoft validates the SBC certificate; a self-signed or private-CA certificate, an FQDN mismatch, or an expired certificate causes the SBC to show **Inactive** and all calls to fail.
- **Verify.** Inspect the certificate served on TCP 5061 (for example `openssl s_client -connect sbc01.<verified-sip-domain>:5061`) and confirm the CN/SAN matches the FQDN, the chain is complete (intermediate included), and it is not expired.
- **Implement if missing.** Obtain a certificate from a public CA on Microsoft's accepted list, install it with the full intermediate chain on the SBC's TLS context per AudioCodes documentation, and schedule renewal monitoring.

## R4 — Verified SIP domain in the tenant

- **Description.** The DNS domain used in the SBC FQDN (the portion after the host label) must be a **verified domain** in the Microsoft 365 tenant (for example `<verified-sip-domain>`).
- **Why.** `New-CsOnlinePSTNGateway` will only register an FQDN whose parent domain is verified in the tenant; otherwise pairing is rejected.
- **Verify.** Microsoft 365 admin center → **Settings → Domains** shows the domain as **Healthy/Verified**; or `Get-CsTenant | Select-Object -ExpandProperty Domains` lists it.
- **Implement if missing.** Add the domain in **Settings → Domains → Add domain** and complete the TXT verification, then ensure at least one user/object carries that domain so it is fully provisioned for Teams.

## R5 — SIP trunk / carrier or PSTN connectivity behind the SBC

- **Description.** A SIP trunk from a carrier (or other PSTN connectivity — for example an ISDN/PRI gateway) terminating on the SBC, with assigned Direct Inward Dialing (DID) numbers and outbound calling enabled.
- **Why.** The SBC bridges Teams to the actual telephone network; without a working trunk and number range there is no PSTN to reach or be reached from.
- **Verify.** Confirm the carrier trunk registers/establishes on the SBC and a test call completes carrier-side (independent of Teams); confirm the DID range is documented.
- **Implement if missing.** Procure/activate the SIP trunk, configure it on the SBC per the carrier's interop guide and AudioCodes documentation, and obtain the DID number block.

## R6 — Teams administrator role and Teams PowerShell module

- **Description.** An account with **Teams Administrator** (or Global Administrator) role, plus the **MicrosoftTeams** PowerShell module installed for cmdlet-based configuration.
- **Why.** Pairing the SBC, building voice routes, and assigning policies/numbers are performed with Teams PowerShell cmdlets that require this role.
- **Verify.** In Microsoft Entra → **Roles and administrators**, confirm the role assignment; in PowerShell run `Get-Module -ListAvailable MicrosoftTeams` and `Connect-MicrosoftTeams` succeeds.
- **Implement if missing.** Assign the Teams Administrator role in Entra, then `Install-Module MicrosoftTeams -Scope CurrentUser` (or update with `Update-Module MicrosoftTeams`).

## R7 — Firewall and ports for SIP TLS signaling

- **Description.** Network rules permitting **SIP over TLS on TCP 5061** between Microsoft's Direct Routing SIP proxy FQDNs and the SBC (bidirectional as required), to Microsoft's published Direct Routing signaling IP ranges.
- **Why.** Signaling and the SIP OPTIONS keep-alive that drives the SBC **Active/Inactive** status traverse TCP 5061; if blocked, the SBC never shows healthy.
- **Verify.** Confirm firewall policy allows TCP 5061 to/from Microsoft's Direct Routing signaling ranges, and that OPTIONS exchanges are seen on the SBC.
- **Implement if missing.** Add firewall rules permitting TCP 5061 to Microsoft's documented Direct Routing signaling IP ranges; do not rely on a single hard-coded IP — use the published ranges.

## R8 — Firewall and ports for media (SRTP)

- **Description.** Network rules permitting **media over UDP** (RTP/SRTP) across Microsoft's published media port ranges to/from Microsoft's media/Transport Relay IP ranges and the SBC's media interface.
- **Why.** Audio (the media plane) is separate from signaling. Even with signaling healthy, blocked or NATed media causes **one-way or no audio**.
- **Verify.** Confirm the firewall permits the published media UDP ranges to Microsoft's media IP ranges, and that the SBC's public media address/NAT is correctly advertised.
- **Implement if missing.** Open the published media UDP port ranges to Microsoft's media IP ranges, configure the SBC's media interface and NAT (public IP advertisement) per AudioCodes documentation, and enable SRTP.

## R9 — SRTP / media encryption interop

- **Description.** The SBC must negotiate **SRTP** with Teams (Microsoft requires encrypted media for Direct Routing) and support the codecs/transcoding Teams expects.
- **Why.** Mismatched media security (for example SBC offering RTP-only) or unsupported codecs produces call setup failures or no audio.
- **Verify.** Confirm the SBC's media security/IP Profile is set for SRTP toward Teams and codec negotiation succeeds on a test call.
- **Implement if missing.** Configure the SBC IP Profile/media security for SRTP toward the Teams side and enable required codec/transcoding per AudioCodes documentation.

## R10 — Emergency calling plan

- **Description.** A documented plan for emergency (for example 911/112/999 and regional equivalents) calling: how emergency numbers are dialed, normalized, routed (typically via a dedicated PSTN usage/route), and how location/callback information is provided per local regulation.
- **Why.** Direct Routing emergency calling is **your** responsibility, not Microsoft's. Misrouted or location-less emergency calls are a safety and compliance failure. Emergency routing and dynamic location handling differ materially from ordinary calls and from Calling Plans.
- **Verify.** Confirm there is a written emergency-calling design (dialed strings, normalization, route, trunk, location/callback policy) reviewed against local regulatory requirements, and a safe way to test routing without dispatching responders.
- **Implement if missing.** Define the emergency dialing strings and normalization, create a dedicated emergency PSTN usage and voice route to the appropriate trunk, configure callback number/location handling per regulation, and arrange a controlled test path with the carrier (for example a test/echo number) before go-live.

## R11 — Pilot users

- **Description.** A small, representative set of real users (ideally across the relevant sites/number ranges) designated as the pilot ring `Pilot Ring – Voice Users – Stage 1`, who consent to early calling and will report results.
- **Why.** Piloting surfaces routing, caller-ID, and audio issues with low blast radius before broad rollout.
- **Verify.** Confirm a named list of pilot users exists, each with R1 licensing and an assigned DID, and that they are briefed on the test scenarios.
- **Implement if missing.** Select pilot users, ensure licensing/numbers, and document the pilot ring membership.

## R12 — Change control and rollback path

- **Description.** An approved change window and a documented rollback for each phase (for example removing a voice routing policy grant, unassigning a number, or unregistering the PSTN gateway).
- **Why.** Voice is a critical service; changes must be reversible and scheduled to limit user impact.
- **Verify.** Confirm a change ticket/window exists and that each step's reverse cmdlet is recorded (see `06-troubleshooting.md` and the remediation script).
- **Implement if missing.** Create the change record, list the reverse operation for every forward step, and confirm approvers before the **Pair SBC** phase.

## R13 — Number inventory and caller-ID policy

- **Description.** A documented mapping of which DID numbers are assigned to which users, the main/site numbers, and the desired outbound caller-ID presentation.
- **Why.** Correct caller ID is an explicit validation gate; it depends on coherent number assignment in Teams and on the SBC/carrier presenting the right calling number.
- **Verify.** Confirm a number-to-user spreadsheet exists and the carrier supports presenting the chosen calling numbers.
- **Implement if missing.** Build the inventory, agree caller-ID presentation with the carrier, and configure any required calling-line-ID policy in Teams and number manipulation on the SBC.


---


# Global Requirements — Azure Solutions

These are the category-wide prerequisites shared by every solution in the **Azure Solutions** catalog. They are generic and apply regardless of the specific technology being deployed. Each solution's own `02-requirements.md` adds the requirements specific to that product; this document covers the baseline that must be true for any Azure/Microsoft 365 cloud engagement. Apply the same discipline to each: **Description / Why / Verify / Implement if missing** — never assume a baseline is already in place.

---

## G1 — A Microsoft 365 / Azure tenant

- **Description.** An active Microsoft 365 (and/or Azure) tenant that will host the workload.
- **Why.** All configuration objects (users, policies, services) live in the tenant; without it there is nothing to configure.
- **Verify.** Sign in to the Microsoft 365 admin center (admin.microsoft.com) and confirm the tenant is active and the organization name/initial domain are correct.
- **Implement if missing.** Provision a Microsoft 365 tenant (or Azure subscription) and complete initial tenant setup.

## G2 — Administrative roles (least privilege)

- **Description.** Accounts holding the specific administrative roles the work requires (for example Teams Administrator, User Administrator), scoped to least privilege rather than blanket Global Administrator where possible.
- **Why.** Each configuration action requires an appropriate role; over-privileged accounts increase risk.
- **Verify.** Microsoft Entra admin center → **Roles and administrators** lists the role holders; confirm the executing account has exactly the roles needed.
- **Implement if missing.** Assign the required roles in Entra (consider Privileged Identity Management for just-in-time elevation), and use a dedicated admin account, not a daily-driver identity.

## G3 — Licensing baseline

- **Description.** The base Microsoft 365 / Azure licensing that the solution's specific SKUs build upon (for example user licenses that the workload's add-ons attach to).
- **Why.** Most workloads require a base license plus feature-specific entitlements; missing base licensing blocks assignment of the workload's capabilities.
- **Verify.** Microsoft 365 admin center → **Billing → Licenses** shows owned and available SKUs and assignment counts.
- **Implement if missing.** Acquire the base licenses and assign them (directly or via group-based licensing) before assigning workload-specific entitlements.

## G4 — Network reachability to Microsoft / Azure endpoints

- **Description.** Network egress (and any required inbound rules) permitting traffic to the Microsoft 365 / Azure service endpoints the workload depends on, per Microsoft's published URL/IP ranges.
- **Why.** Cloud workloads fail silently or intermittently when required endpoints are blocked, proxied incorrectly, or TLS-inspected.
- **Verify.** Confirm firewall/proxy policy allows the workload's documented endpoints and that TLS inspection is excluded where Microsoft requires it.
- **Implement if missing.** Update firewall/proxy rules to permit Microsoft's published endpoint ranges for the workload and exclude them from break-and-inspect where directed.

## G5 — Administration tooling (PowerShell / portals)

- **Description.** The management surfaces the solution uses — the relevant admin center(s) and any required PowerShell modules at a supported version.
- **Why.** Configuration steps reference specific portals and cmdlets; outdated or missing modules cause command failures.
- **Verify.** Confirm portal access for the admin account and that the required modules import successfully at a current version.
- **Implement if missing.** Install/update the required PowerShell modules and confirm portal access before starting implementation.

## G6 — Change control

- **Description.** An approved change process — scheduled window, documented steps, named approvers, and a communication plan for affected users.
- **Why.** Tenant-wide changes can affect production services; controlled change limits risk and provides an audit trail.
- **Verify.** A change ticket exists with scope, schedule, approvers, and back-out criteria.
- **Implement if missing.** Create the change record and obtain approvals before making production changes.

## G7 — Test users and pilot scope

- **Description.** Non-critical test users (and a defined pilot group) used to validate configuration before broad rollout.
- **Why.** Testing on real-but-low-impact accounts catches issues without affecting the whole organization.
- **Verify.** A named set of test/pilot users exists with appropriate licensing.
- **Implement if missing.** Designate test users, license them, and document the pilot membership.

## G8 — Rollback plan

- **Description.** A documented way to reverse each change (the inverse operation for every forward step) and restore the prior state.
- **Why.** Any production change must be reversible to recover quickly from unexpected impact.
- **Verify.** Each forward step in the implementation has a recorded reverse operation and the team has rehearsed/confirmed it.
- **Implement if missing.** Document the reverse of each step (and any export/backup of current configuration) before applying changes.

## G9 — Documentation and audit trail

- **Description.** A record of what was configured (object names, values, dates, executing admin) and where it lives.
- **Why.** Operability, troubleshooting, and audits all depend on knowing the as-built state.
- **Verify.** Configuration is captured (for example via the solution's discovery/report scripts) and stored with the change record.
- **Implement if missing.** Run the solution's discovery/report tooling and retain the output as the as-built baseline.


---


# 3. Implementation — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

This document is the step-by-step build, following the phase model **Assess → Pair SBC → Configure Voice Routing → Assign Users → Pilot → Validate → Expand**. Every object you create uses the `<Purpose> – <Scope> – <Stage>` naming convention from `01-solution-overview.md` and is reused verbatim. Full navigation paths are given for the Microsoft Teams admin center, and exact Microsoft Teams PowerShell cmdlets (MicrosoftTeams module) are given for each action. The AudioCodes SBC device configuration is provided as a concept-level checklist; exact device Web UI/INI/CLI paths are deferred to AudioCodes' documentation.

> **Conventions used below**
> - `<verified-sip-domain>` = your tenant-verified SIP domain (R4).
> - SBC FQDN = `sbc01.<verified-sip-domain>`, registered as the PSTN gateway named `PSTN Gateway – Primary SBC – Production`.
> - All PowerShell assumes you have run `Connect-MicrosoftTeams` as a Teams Administrator (R6).
> - Run discovery (`TEAMSSBC-Discovery.ps1`) **before** you change anything, and keep its output as your baseline.

---

## Phase 1 — Assess

1. **Confirm prerequisites.** Walk `02-requirements.md` (R1–R13) and `global-requirements-azure-solutions.md` end to end. Do not proceed until each is **Verified** or **Implemented**.
2. **Capture the current state.** Run the discovery script to record any existing PSTN gateways, voice routes, PSTN usages, voice routing policies, dial plans, and voice-enabled users:

   ```powershell
   .\TEAMSSBC-Discovery.ps1 -OutputPath .\baseline
   ```

   Teams admin center equivalent for spot checks: **Teams admin center → Voice → Direct Routing** (SBCs), **Voice → Voice routing policies**, and **Voice → Dial plans**.
3. **Confirm SBC readiness (concept-level).** With your network/voice team confirm the SBC FQDN resolves publicly (R2), the public CA certificate is installed with full chain and matches the FQDN (R3), and TCP 5061 + media ranges are open (R7–R8). Defer the device-side specifics to AudioCodes documentation.

## Phase 2 — Pair SBC

> Goal: register the AudioCodes SBC as a Direct Routing PSTN gateway and confirm Microsoft sees it as **Active** with healthy SIP OPTIONS.

4. **Register the PSTN gateway.** Pair the SBC by FQDN. Use the canonical signaling port (TLS 5061), enable SIP OPTIONS keep-alive, set media bypass per your design (start **disabled** for the pilot to simplify troubleshooting), and forward the calling party (PAI) as your caller-ID design requires:

   ```powershell
   New-CsOnlinePSTNGateway `
     -Fqdn "sbc01.<verified-sip-domain>" `
     -SipSignalingPort 5061 `
     -Enabled $true `
     -SendSipOptions $true `
     -MaxConcurrentSessions 100 `
     -MediaBypass $false `
     -ForwardCallHistory $true `
     -ForwardPai $true
   ```

   > Name reference: this gateway is referred to throughout as `PSTN Gateway – Primary SBC – Production` (its identity in Teams is the FQDN `sbc01.<verified-sip-domain>`).

5. **Confirm registration in the portal.** Navigate **Teams admin center → Voice → Direct Routing → SBCs**. Confirm `sbc01.<verified-sip-domain>` is listed and **Enabled**.
6. **Verify SIP OPTIONS health.** On the same SBCs page, confirm the SBC status is **Active** (driven by SIP OPTIONS exchanged over TCP 5061). If it shows **Inactive**, stop and resolve before continuing (see `06-troubleshooting.md`: certificate/TLS, FQDN mismatch, firewall 5061).

   PowerShell verification:

   ```powershell
   Get-CsOnlinePSTNGateway -Identity "sbc01.<verified-sip-domain>"
   ```

7. **AudioCodes SBC-side checklist (concept-level — defer exact paths to AudioCodes docs).** Confirm on the device that:
   - A **TLS context** holds the public CA certificate (with intermediate chain) bound to the Teams-facing SIP interface, and the trusted-root store includes Microsoft's CA chain.
   - A **SIP interface** listens on **TLS 5061** for the Teams side.
   - A **Proxy Set** points to Microsoft's Direct Routing SIP proxy FQDNs (the three regional FQDNs Microsoft publishes), with TLS transport.
   - An **IP Profile** for the Teams side enforces **SRTP** media security and the supported codecs.
   - **SIP OPTIONS** keep-alive is enabled toward Microsoft so the gateway reports **Active**.
   - **IP-to-IP routing rules** connect the Teams-facing interface to the carrier/PSTN-facing interface (and vice versa), with any number-manipulation rules for caller-ID and DID normalization.
   - The **media interface** advertises the correct public IP (NAT) for SRTP.

   The exact Web UI menus, INI parameters, and CLI for the above live in AudioCodes' Teams Direct Routing configuration guide; do not substitute invented menu paths.

## Phase 3 — Configure Voice Routing

> Goal: build the named routing stack that decides which dialed numbers leave through the SBC. Order matters — create usages, then routes that reference them, then the policy that references the usages, then the dial plan.

8. **Create the PSTN usages.** Usages are the link between routes and policies. Create a domestic usage and a dedicated emergency usage:

   ```powershell
   Set-CsOnlinePstnUsage -Identity Global -Usage @{Add="PSTN Usage – Domestic – Production"}
   Set-CsOnlinePstnUsage -Identity Global -Usage @{Add="PSTN Usage – Emergency – Production"}
   ```

   > PSTN usages are stored on the **Global** usage list; the named strings above are the usages you will reference from routes and the policy.

9. **Create the emergency voice route first (most specific, highest priority).** Match your emergency dialed/normalized string(s) and send them out the SBC via the emergency usage. Replace the pattern with your jurisdiction's emergency number(s):

   ```powershell
   New-CsOnlineVoiceRoute `
     -Identity "Voice Route – Emergency – Production" `
     -Priority 0 `
     -NumberPattern "^\+?(911|112|999)$" `
     -OnlinePstnGatewayList "sbc01.<verified-sip-domain>" `
     -OnlinePstnUsages "PSTN Usage – Emergency – Production"
   ```

   > Emergency routing is **your** responsibility under Direct Routing (R10). Keep it a dedicated, highest-priority route so it can never be shadowed by a broader domestic pattern, and validate it (controlled) before go-live.

10. **Create the domestic outbound voice route.** Match normalized E.164 domestic/international patterns and send them out the SBC via the domestic usage:

    ```powershell
    New-CsOnlineVoiceRoute `
      -Identity "Voice Route – Domestic Outbound – Production" `
      -Priority 1 `
      -NumberPattern "^\+\d{7,15}$" `
      -OnlinePstnGatewayList "sbc01.<verified-sip-domain>" `
      -OnlinePstnUsages "PSTN Usage – Domestic – Production"
    ```

    > Tighten `NumberPattern` to your actual dialing plan (country/area codes) rather than a broad catch-all in production. Carrier-specific digit manipulation (for example stripping/adding a national prefix) is done on the SBC, not here.

11. **Create the voice routing policy and attach the usages.** The policy is what you grant to users; it references the usages (and therefore the routes):

    ```powershell
    New-CsOnlineVoiceRoutingPolicy `
      -Identity "Voice Routing Policy – Standard User – Production" `
      -OnlinePstnUsages @("PSTN Usage – Emergency – Production","PSTN Usage – Domestic – Production")
    ```

12. **Create the tenant dial plan with named normalization rules.** A dial plan normalizes user-dialed strings (extensions, local dialing) into E.164 so routes match. Create the dial plan, build named normalization rules, and attach them. Example: normalize a 4-digit extension and a local 10-digit number (adjust to your numbering):

    ```powershell
    New-CsTenantDialPlan -Identity "Dial Plan – Standard User – Production" `
      -Description "Normalizes extension and local dialing to E.164 for standard users"

    $extRule = New-CsVoiceNormalizationRule -Identity "Global/NormRule – 4-Digit Extension – Production" `
      -Pattern '^(\d{4})$' -Translation '+1206555$1' -InMemory
    $localRule = New-CsVoiceNormalizationRule -Identity "Global/NormRule – Local 10-Digit – Production" `
      -Pattern '^(\d{10})$' -Translation '+1$1' -InMemory

    Set-CsTenantDialPlan -Identity "Dial Plan – Standard User – Production" `
      -NormalizationRules @{Add=$extRule,$localRule}
    ```

    > Replace the example country/area digits (`+1206555…`, `+1…`) with your real ranges. Keep rule names in the `<Purpose> – <Scope> – <Stage>` form so the dial plan is self-documenting.

13. **Portal cross-check.** Confirm the objects in **Teams admin center → Voice**: **Direct routing → Voice routes**, **Voice routing policies**, and **Dial plans**. The named objects from steps 8–12 should all appear.

    > You can also build steps 8–12 from parameters in one pass with `TEAMSSBC-Set-VoiceRouting.ps1 -WhatIf` to preview, then `-Apply`.

## Phase 4 — Assign Users

> Goal: make pilot users callable. For each pilot user: confirm Phone System, grant the voice routing policy, assign a number, and (optionally) assign the dial plan.

14. **Confirm Phone System on the user (R1).**

    ```powershell
    Get-CsOnlineUser -Identity "user@<verified-sip-domain>" | Select-Object UserPrincipalName,FeatureTypes
    ```

15. **Grant the voice routing policy.**

    ```powershell
    Grant-CsOnlineVoiceRoutingPolicy `
      -Identity "user@<verified-sip-domain>" `
      -PolicyName "Voice Routing Policy – Standard User – Production"
    ```

16. **Assign the dial plan (if using extension/local dialing).**

    ```powershell
    Grant-CsTenantDialPlan `
      -Identity "user@<verified-sip-domain>" `
      -PolicyName "Dial Plan – Standard User – Production"
    ```

17. **Assign the phone number and enable Direct Routing calling.** Use `Set-CsPhoneNumberAssignment` with `-PhoneNumberType DirectRouting`:

    ```powershell
    Set-CsPhoneNumberAssignment `
      -Identity "user@<verified-sip-domain>" `
      -PhoneNumber "+12065550123" `
      -PhoneNumberType DirectRouting
    ```

    > Use the DID assigned to the user from your number inventory (R13). The number must be in E.164. (Enterprise-voice enablement is set as part of number assignment; confirm `EnterpriseVoiceEnabled` is `True` afterward.)

18. **Portal cross-check.** **Teams admin center → Users → (user) → Account** shows the assigned number and policies; **Voice → Phone numbers** reflects the assignment.

## Phase 5 — Pilot

19. **Brief the pilot ring `Pilot Ring – Voice Users – Stage 1`** (R11) on the test matrix in `05-testing.md`: outbound to mobile/landline, inbound to their DID, internal Teams call, caller-ID check, and the controlled emergency-routing test.
20. **Have each pilot user sign out and back into Teams** so the new calling configuration loads, then place a test outbound call.

## Phase 6 — Validate

21. **Run the validation script** to confirm the gateway, routing chain, and user assignments are consistent, then walk the explicit gates in `05-testing.md`:

    ```powershell
    .\TEAMSSBC-Validation.ps1 -GatewayFqdn "sbc01.<verified-sip-domain>" `
      -VoiceRoutingPolicy "Voice Routing Policy – Standard User – Production" `
      -PilotUsers user1@<verified-sip-domain>,user2@<verified-sip-domain>
    ```

    Gates (all must PASS): SBC **Active** / SIP OPTIONS healthy; outbound call connects; inbound DID routes to the user; caller ID correct; emergency-call routing validated (controlled).
22. **Produce the as-built report** for the change record:

    ```powershell
    .\TEAMSSBC-Report.ps1 -OutputPath .\reports
    ```

## Phase 7 — Expand

23. **Widen the rings.** Add the next user group, reusing the same `Voice Routing Policy – Standard User – Production` and dial plan, assigning numbers from inventory.
24. **Add capacity/resilience as needed.** Register a secondary SBC FQDN as an additional PSTN gateway, add it to route gateway lists for failover, and raise `MaxConcurrentSessions` to match licensed/trunk capacity. Re-run discovery, validation, and reporting after each material change.
25. **Operationalize.** Schedule periodic `TEAMSSBC-Validation.ps1` and `TEAMSSBC-Report.ps1` runs, monitor certificate expiry (R3), and keep the emergency-calling design under review.


---


# 5. Testing & Validation — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

Validation happens in the **Validate** phase, after **Pilot**, and is repeated after every material change in **Expand**. Each gate below is pass/fail: do **not** widen the rollout until every gate passes for the pilot ring `Pilot Ring – Voice Users – Stage 1`. Use `TEAMSSBC-Validation.ps1` for the configuration-consistency checks and the manual call tests for the call-path gates.

> Run order: configuration gates (G1–G3) first — they are read-only and prove the build is coherent — then the live call gates (G4–G8).

---

## Gate G1 — SBC paired and SIP OPTIONS healthy (Active)

- **What to check.** The PSTN gateway `sbc01.<verified-sip-domain>` (`PSTN Gateway – Primary SBC – Production`) is registered, enabled, and shows **Active** in the Teams admin center, driven by healthy SIP OPTIONS over TCP 5061.
- **How.**
  - Portal: **Teams admin center → Voice → Direct Routing → SBCs** → status is **Active**.
  - PowerShell: `Get-CsOnlinePSTNGateway -Identity "sbc01.<verified-sip-domain>"` returns `Enabled = True` and `SendSipOptions = True`.
  - Script: `TEAMSSBC-Validation.ps1` reports **PASS** for the gateway existence/health check.
- **Pass.** Status **Active** and gateway enabled with OPTIONS on.
- **Fail.** Status **Inactive** → go to `06-troubleshooting.md` (TLS/cert, FQDN mismatch, firewall 5061, OPTIONS).

## Gate G2 — Voice routing chain is consistent

- **What to check.** The usages, routes, policy, and dial plan reference each other correctly: the policy `Voice Routing Policy – Standard User – Production` includes both `PSTN Usage – Emergency – Production` and `PSTN Usage – Domestic – Production`; each route points at the SBC FQDN and a usage; the emergency route is highest priority.
- **How.**
  - PowerShell: `Get-CsOnlineVoiceRoutingPolicy -Identity "Voice Routing Policy – Standard User – Production"`; `Get-CsOnlineVoiceRoute`; `Get-CsOnlinePstnUsage`.
  - Script: `TEAMSSBC-Validation.ps1` reports **PASS** for "routing chain consistent" (usages exist, routes reference an existing gateway + usage, policy references existing usages, emergency route priority is highest).
- **Pass.** All references resolve and emergency route is most specific/highest priority.
- **Fail.** A dangling reference or wrong priority → see `06-troubleshooting.md` (voice routing policy not applied / route ordering).

## Gate G3 — Pilot users assigned

- **What to check.** Each pilot user has Phone System, the voice routing policy granted, the dial plan granted (if used), a DID assigned, and `EnterpriseVoiceEnabled = True`.
- **How.**
  - PowerShell: `Get-CsOnlineUser -Identity <user> | Select-Object UserPrincipalName,EnterpriseVoiceEnabled,OnlineVoiceRoutingPolicy,TenantDialPlan,LineUri`.
  - Script: `TEAMSSBC-Validation.ps1 -PilotUsers <list>` reports **PASS** per user.
- **Pass.** Every pilot user shows the policy, a `LineUri`, and Enterprise Voice enabled.
- **Fail.** Missing policy/number → run `TEAMSSBC-Remediation.ps1 -Apply` to (re)grant the policy / assign the number for the named user.

## Gate G4 — Outbound call connects

- **What to check.** A pilot user places an outbound PSTN call (to a mobile and to a landline) and audio is two-way.
- **How.** From the Teams client, dial an external number; confirm the call connects and both parties hear each other.
- **Pass.** Call connects with clear two-way audio.
- **Fail.** Call fails to set up → `06-troubleshooting.md` (route/usage/policy, SBC routing, carrier). One-way/no audio → `06-troubleshooting.md` (media/NAT/SRTP).

## Gate G5 — Inbound DID routes correctly

- **What to check.** Calling a pilot user's DID from an external phone rings that user in Teams and connects with two-way audio.
- **How.** From an external phone, dial the pilot user's assigned number; confirm Teams rings the correct user and audio is two-way.
- **Pass.** Correct user rings; two-way audio.
- **Fail.** No ring / wrong user → `06-troubleshooting.md` (inbound fails: SBC inbound routing/number normalization, `LineUri` mismatch).

## Gate G6 — Caller ID is correct

- **What to check.** Outbound calls present the intended calling number (per R13), and inbound calls show the external caller's number to the Teams user.
- **How.** On the outbound test, confirm the called party sees the expected number; on the inbound test, confirm the Teams user sees the caller's number.
- **Pass.** Both directions present the expected numbers.
- **Fail.** Wrong/blocked caller ID → `06-troubleshooting.md` (PAI/number manipulation on SBC, carrier presentation, calling-line-ID policy).

## Gate G7 — Internal Teams calling unaffected

- **What to check.** Teams-to-Teams (VoIP) calls still work for pilot users (Direct Routing changes must not regress internal calling).
- **How.** Pilot user places a Teams call to another Teams user; confirm connect + two-way audio.
- **Pass.** Internal calling works normally.
- **Fail.** Investigate policy/licensing regressions before expanding.

## Gate G8 — Emergency-call routing validated (controlled)

- **What to check.** A dialed emergency string matches `Voice Route – Emergency – Production` and is sent out the SBC via `PSTN Usage – Emergency – Production`, with the correct callback number/location handling per R10 — **without dispatching emergency responders**.
- **How.**
  - Verify routing **logically** first: confirm the dialed/normalized emergency pattern matches the emergency route (highest priority) and not the domestic route.
  - Validate the call path with a **controlled** method agreed with your carrier (for example a carrier-provided emergency test/echo number or a test environment), per local regulation — never place a real emergency call as a test.
  - Confirm the callback number and any location information presented are correct.
- **Pass.** Emergency dialing matches the dedicated emergency route, routes out the SBC, and presents correct callback/location via the controlled test.
- **Fail.** Emergency string matches the wrong route, fails to route, or presents no/incorrect location → treat as a launch blocker; see `06-troubleshooting.md` (emergency calling).

---

## Exit criteria

All eight gates **PASS** for the pilot ring, the validation script reports no failures, and `TEAMSSBC-Report.ps1` output is attached to the change record. Only then proceed to **Expand**.


---


# 6. Troubleshooting — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

Use this guide symptom-first. Each entry lists likely causes (Microsoft side and SBC side) and the checks/fixes in priority order. Microsoft-side checks are concrete; AudioCodes device specifics are described at the concept level and deferred to AudioCodes' documentation. Re-run `TEAMSSBC-Validation.ps1` after each fix.

---

## Symptom 1 — SBC shows Inactive in the Teams admin center

The SBC status under **Teams admin center → Voice → Direct Routing → SBCs** is **Inactive** (no healthy SIP OPTIONS).

Likely causes and checks, in order:

1. **Certificate / TLS problem (most common).** Confirm the SBC presents a **public CA** certificate whose CN/SAN matches the FQDN, with the **full intermediate chain**, not expired (R3). Check from outside: `openssl s_client -connect sbc01.<verified-sip-domain>:5061`.
2. **FQDN mismatch or DNS.** The paired FQDN must equal the certificate subject and resolve publicly. Verify `nslookup sbc01.<verified-sip-domain>` and `Get-CsOnlinePSTNGateway -Identity "sbc01.<verified-sip-domain>"`.
3. **Firewall blocking TCP 5061.** Signaling/OPTIONS need TCP 5061 open to Microsoft's Direct Routing signaling ranges (R7).
4. **OPTIONS not enabled.** Confirm `SendSipOptions = True` on the gateway and OPTIONS keep-alive is enabled on the SBC toward Microsoft's proxy FQDNs (concept-level; defer device path to AudioCodes docs).
5. **Proxy Set / trusted roots on the SBC.** The SBC must trust Microsoft's CA chain and target Microsoft's Direct Routing SIP proxy FQDNs over TLS (concept-level).

> An **Inactive** SBC fails all calls — resolve before any call testing.

## Symptom 2 — TLS / certificate errors

Handshake failures, "certificate not trusted/expired," or SBC logs showing TLS negotiation errors with Microsoft.

1. **Expired or soon-to-expire certificate** — reissue from a public CA and reinstall with the chain; add expiry monitoring.
2. **Missing intermediate chain** — install the full chain on the SBC's TLS context, not just the leaf.
3. **Name mismatch** — CN/SAN must include the exact paired FQDN.
4. **Untrusted root for inbound from Microsoft** — ensure the SBC's trusted-root store includes Microsoft's CA chain (concept-level; defer to AudioCodes docs).
5. **Wrong port/transport** — confirm TLS on 5061, not TCP/UDP 5060.

## Symptom 3 — One-way audio or no audio (media)

Calls connect (signaling succeeds) but audio is one-way or absent.

1. **Media ports/ranges blocked** — open Microsoft's published media UDP ranges to Microsoft's media IP ranges (R8).
2. **NAT / public IP not advertised** — the SBC must advertise its correct public media IP for SRTP; a private/incorrect address breaks media (concept-level; defer to AudioCodes docs).
3. **SRTP mismatch** — Teams requires encrypted media; ensure the SBC IP Profile offers **SRTP** toward Teams (R9).
4. **Codec mismatch** — ensure supported codecs/transcoding are configured on the SBC.
5. **Media bypass complications** — if media bypass was enabled, disable it to isolate, then re-enable once stable.

## Symptom 4 — Outbound call fails to connect

User dials an external number and the call never sets up.

1. **No matching route** — the normalized dialed string must match a `NumberPattern`. Check the dial plan normalized it to E.164 and a `Get-CsOnlineVoiceRoute` pattern matches.
2. **Usage not in policy** — the route's usage must be in the user's granted policy (`Voice Routing Policy – Standard User – Production`).
3. **Gateway not in route** — the route's `OnlinePstnGatewayList` must include `sbc01.<verified-sip-domain>`.
4. **SBC routing / carrier** — the SBC IP-to-IP rule must send Teams→carrier, and the carrier trunk must be up with outbound enabled (R5; concept-level on the SBC side).
5. **Capacity** — `MaxConcurrentSessions` or trunk channels exhausted.

## Symptom 5 — Inbound DID fails or rings the wrong user

External caller dials a DID and it fails, or reaches the wrong person.

1. **LineUri mismatch** — the user's assigned `LineUri` (E.164) must exactly match the DID the carrier delivers; check `Get-CsOnlineUser -Identity <user> | Select-Object LineUri`.
2. **Inbound number normalization on the SBC** — the SBC must present the called number in the format Teams expects (E.164); fix number manipulation on the SBC (concept-level).
3. **Number not assigned / Enterprise Voice off** — confirm the number is assigned via `Set-CsPhoneNumberAssignment` and `EnterpriseVoiceEnabled = True`.
4. **SBC inbound IP-to-IP routing** — carrier→Teams rule missing or misordered on the SBC (concept-level).

## Symptom 6 — Caller ID wrong or blocked

1. **Outbound presentation** — confirm `ForwardPai = True` on the gateway and the SBC presents the intended calling number (number manipulation/PAI on the SBC; concept-level).
2. **Carrier presentation** — the carrier must permit presenting your chosen calling numbers (R13).
3. **Calling-line-ID policy** — if numbers are masked/replaced unexpectedly, review any calling-line-ID policy in Teams.
4. **Inbound caller number absent** — the SBC must pass the calling number from the carrier to Teams.

## Symptom 7 — Voice routing policy not applied

User cannot place external calls though others can.

1. **Policy not granted** — `Get-CsOnlineUser -Identity <user> | Select-Object OnlineVoiceRoutingPolicy`; if blank, run `Grant-CsOnlineVoiceRoutingPolicy` (or `TEAMSSBC-Remediation.ps1 -Apply`).
2. **Propagation delay** — policy/number changes can take time to apply; have the user sign out/in and retest.
3. **Enterprise Voice not enabled / no number** — confirm `EnterpriseVoiceEnabled = True` and a `LineUri` is set.
4. **Dial plan not granted** — extension/local dialing fails if `Dial Plan – Standard User – Production` isn't granted to the user.

## Symptom 8 — Emergency calling problems

Treat any emergency-calling defect as a **launch blocker**.

1. **Wrong route matched** — the emergency dialed/normalized string must match `Voice Route – Emergency – Production` (highest priority), not the domestic route. Verify priority ordering and patterns.
2. **Emergency usage missing from policy** — `PSTN Usage – Emergency – Production` must be in the user's voice routing policy.
3. **Normalization conflict** — a dial-plan rule may rewrite the emergency string; ensure emergency dialing is preserved/normalized correctly.
4. **Callback number / location not presented** — configure callback number and location handling per local regulation (R10); validate with a **controlled** carrier test path, never a live emergency call.
5. **Carrier emergency support** — confirm the carrier/trunk supports emergency calling for your DIDs and presents the required information.

---

## General diagnostic flow

1. Run `TEAMSSBC-Validation.ps1` — it isolates whether the problem is the gateway, the routing chain, or user assignment.
2. If the gateway is **Inactive**, fix that first (Symptoms 1–2) — nothing else will work.
3. If signaling is healthy but audio fails, suspect media/NAT/SRTP (Symptom 3).
4. If a single user is affected, suspect assignment/policy (Symptoms 7); if everyone is affected, suspect the gateway/routing/SBC/carrier.
5. Capture an as-built with `TEAMSSBC-Report.ps1` before and after changes for comparison.


---


# 7. Best Practices — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

These practices keep a Direct Routing deployment healthy, secure, and operable over time. They are organized by the phase model **Assess → Pair SBC → Configure Voice Routing → Assign Users → Pilot → Validate → Expand**, plus ongoing operations.

---

## Assess

- **Never assume a prerequisite.** Run discovery and walk R1–R13 before touching production. Most Direct Routing failures trace back to an unverified domain, a certificate problem, or a closed port — all caught in Assess.
- **Design emergency calling first, not last.** Because emergency routing is your responsibility under Direct Routing, define dialed strings, normalization, the dedicated route, callback/location handling, and a controlled test path during Assess. Treat it as a launch blocker, not a follow-up.
- **Document the number inventory up front.** A clean DID-to-user map and an agreed caller-ID presentation prevent rework during user assignment and caller-ID validation.

## Pair SBC

- **Pair by FQDN under a verified domain.** Use a stable, public FQDN whose parent domain is verified in the tenant; avoid changing it later (re-pairing churns configuration).
- **Use public CA certificates and monitor expiry.** A self-signed/private-CA certificate, FQDN mismatch, or expiry is the single most common cause of an **Inactive** SBC. Track renewal proactively (see Operations).
- **Keep SIP OPTIONS keep-alive enabled.** It is what drives the Active/Inactive signal you rely on for monitoring.
- **Start with media bypass disabled.** Enable media bypass only after the basic call path is proven; it simplifies pilot troubleshooting by keeping media flow predictable.

## Configure Voice Routing

- **Name everything with `<Purpose> – <Scope> – <Stage>` and reuse names verbatim.** Self-documenting objects make audits, troubleshooting, and handover dramatically easier.
- **Keep the emergency route highest priority and most specific.** It must never be shadowed by a broad domestic pattern.
- **Tighten `NumberPattern` to your real dialing plan.** Avoid catch-all patterns in production; precise patterns prevent mis-routing and toll fraud exposure.
- **Do digit manipulation where it belongs.** Carrier-specific prefix add/strip and caller-ID number manipulation belong on the SBC; E.164 normalization of user-dialed strings belongs in the Teams dial plan.
- **Build incrementally and preview.** Use `TEAMSSBC-Set-VoiceRouting.ps1 -WhatIf` before `-Apply`, and create usages → routes → policy → dial plan in that order so references always resolve.

## Assign Users

- **Assign by ring, not all at once.** Grant the same `Voice Routing Policy – Standard User – Production` and dial plan to each successive ring; consistency reduces variance in troubleshooting.
- **Confirm Enterprise Voice and LineUri after assignment.** A granted policy without a number (or without Enterprise Voice enabled) will not place calls.
- **Have users re-sign-in to Teams** after assignment so the calling configuration loads.

## Pilot & Validate

- **Pilot with representative users across sites/number ranges.** A single-site pilot can hide site-specific routing or caller-ID issues.
- **Gate the rollout.** Do not expand until all eight validation gates pass and the as-built report is filed with the change record.
- **Validate emergency calling with a controlled method only.** Never place a live emergency call as a test; use a carrier test path and confirm callback/location.

## Expand

- **Add a secondary SBC for resilience.** Register a second PSTN gateway FQDN and add both to route gateway lists for failover; size `MaxConcurrentSessions` to licensed/trunk capacity.
- **Re-validate after every material change.** Re-run discovery, validation, and reporting when adding SBCs, routes, trunks, or sites.

## Operations & security

- **Monitor SBC health continuously.** Alert on Active→Inactive transitions and on certificate expiry windows; both predict outages.
- **Practice least privilege.** Use a dedicated Teams Administrator account (consider just-in-time elevation) for voice changes, not a daily-driver identity.
- **Keep change control and rollback current.** Record the reverse operation for every change; the remediation script defaults to `-WhatIf` so dry-runs are the norm.
- **Guard against toll fraud.** Constrain routes to needed destinations, review call detail records for anomalies, and limit international reach to users who need it.
- **Keep the AudioCodes firmware on a certified version.** Track AudioCodes' certified Direct Routing firmware list and patch within maintenance windows.
- **Retain as-built reports.** Periodic `TEAMSSBC-Report.ps1` exports give you a configuration history for audits and faster incident response.


---


# 8. Deliverables Summary — Microsoft Teams Phone Direct Routing with Session Border Controller (AudioCodes) Integration

This solution is delivered as a complete, productized package: a set of customer-facing implementation documents, a suite of Microsoft Teams PowerShell scripts, and a hero image. Everything is white-labeled and uses the consistent `<Purpose> – <Scope> – <Stage>` object naming so the configuration is auditable end to end.

## Documents

| File | Purpose |
| --- | --- |
| `executive-summary.md` | One-page outcome, scope, and value summary for decision-makers. |
| `01-solution-overview.md` | What the solution delivers, why Direct Routing + SBC, scope, phase model, and naming convention. |
| `02-requirements.md` | Requirements R1–R13 (Description / Why / Verify / Implement if missing). |
| `global-requirements-azure-solutions.md` | Category-wide Azure Solutions baseline (tenant, roles, licensing, network, change control, test users, rollback). |
| `03-implementation.md` | Step-by-step build across all seven phases with full navigation paths and exact cmdlets; AudioCodes SBC checklist deferred to vendor docs. |
| `05-testing.md` | Eight pass/fail validation gates (OPTIONS/Active, outbound, inbound, caller ID, emergency, and more). |
| `06-troubleshooting.md` | Symptom-driven diagnosis for the common failure modes. |
| `07-best-practices.md` | Operational, security, and design best practices by phase. |
| `08-deliverables-summary.md` | This inventory. |

## Scripts (Microsoft Teams PowerShell — MicrosoftTeams module)

All scripts carry a standard header block and a neutral `.NOTES` ("Azure Solutions — read-only." where applicable). Discovery, validation, and reporting are read-only; remediation and configuration default to a safe dry-run (`-WhatIf`) and require an explicit `-Apply` to make changes.

| Script | Purpose |
| --- | --- |
| `TEAMSSBC-Discovery.ps1` | Read current PSTN gateways, voice routes, PSTN usages, voice routing policies, and voice-enabled users (read-only baseline). |
| `TEAMSSBC-Validation.ps1` | Verify the named gateway exists and is healthy (SIP OPTIONS/Active), the routing chain is consistent, and pilot users are assigned — PASS/FAIL. |
| `TEAMSSBC-Report.ps1` | Export the voice configuration and per-user assignment report to CSV. |
| `TEAMSSBC-Remediation.ps1` | Safe fixes — (re)grant the voice routing policy or assign a number to a named user; `-WhatIf` by default, `-Apply` to execute. |
| `TEAMSSBC-Set-VoiceRouting.ps1` | Create the PSTN gateway, usages, voice route, and voice routing policy from parameters; `-WhatIf` to preview. |

## Hero image

| Asset | Purpose |
| --- | --- |
| `TEAMSSBC-hero.png` | Product hero image for the marketplace listing. |

## How the deliverables fit together

1. Run **`TEAMSSBC-Discovery.ps1`** in **Assess** to capture the baseline.
2. Use **`TEAMSSBC-Set-VoiceRouting.ps1`** (preview with `-WhatIf`, then `-Apply`) to build the routing stack in **Configure Voice Routing**, following `03-implementation.md`.
3. Assign users per `03-implementation.md`; use **`TEAMSSBC-Remediation.ps1`** to fix any missing grants/numbers.
4. Run **`TEAMSSBC-Validation.ps1`** in **Validate** against the gates in `05-testing.md`.
5. Produce the as-built with **`TEAMSSBC-Report.ps1`** and attach it to the change record.
6. Repeat discovery → validation → report after each change in **Expand**.
