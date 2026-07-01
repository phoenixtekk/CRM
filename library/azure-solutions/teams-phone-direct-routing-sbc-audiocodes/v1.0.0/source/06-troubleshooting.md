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
