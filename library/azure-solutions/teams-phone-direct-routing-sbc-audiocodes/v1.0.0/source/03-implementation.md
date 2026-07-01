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
