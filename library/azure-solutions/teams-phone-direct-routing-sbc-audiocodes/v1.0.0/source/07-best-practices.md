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
