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
