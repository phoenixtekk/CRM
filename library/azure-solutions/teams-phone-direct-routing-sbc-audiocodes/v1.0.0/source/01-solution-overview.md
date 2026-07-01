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
