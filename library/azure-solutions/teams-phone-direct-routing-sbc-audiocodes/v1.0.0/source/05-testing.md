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
