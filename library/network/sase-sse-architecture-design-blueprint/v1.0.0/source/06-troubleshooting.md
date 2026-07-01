# 6. Troubleshooting Guide — SASE / SSE Architecture & Design Blueprint

Failure modes and fixes, grouped by area. Most SASE/SSE problems trace back to a few root causes:
**the decryption certificate isn't trusted**, **policy isn't keyed off identity**, **steering isn't
active or has the wrong scope**, or **a phase was expanded before its pilot gate passed**.

> Use `SASE-Discovery.ps1` / `SASE-Validation.ps1` (read-only) for current-state and readiness, and
> `SASE-Report.ps1` for capability coverage + gaps. Use `SASE-Remediation.ps1` (default `-WhatIf`) to
> preview fixes. **Exact Netskope console steps are deferred to the official Netskope documentation
> and your tenant** — these fixes name *what* to correct.

---

## A. Steering / client not active

| Symptom | Cause | Remediation |
|---|---|---|
| Endpoint traffic not visible in the edge | Client/steering not deployed, or device outside the phase scope | Confirm the client + steering config deployed via endpoint management (R4); confirm the device is in `SASE Phase Scope – <Phase> – Pilot/Broad`; `SASE-Validation.ps1` checks scope membership |
| Steering active but no identity on traffic | SSO/identity not wired, or device not signed in with the Entra identity | Confirm Entra SSO to the edge (R3); confirm the user is signed in; check identity attribution in `SASE-Discovery.ps1` output |
| Only some users steered | Targeting group membership incomplete | Add members with `SASE-Set-PhaseScopeTargeting.ps1 -Apply`; re-check with `SASE-Validation.ps1` |

## B. SSL inspection / certificate trust

| Symptom | Cause | Remediation |
|---|---|---|
| Browser TLS / certificate warnings on inspected sites | Decryption root not trusted on the endpoint | Deploy the root certificate via endpoint management (R4); confirm it is in the trusted store before enabling inline inspection (R9, T2.1) |
| A pinned-cert / regulated app breaks when inspection is on | App is being decrypted but does not tolerate inspection | Add the destination to the governed SSL-inspection **exception list** in `SASE Reference Architecture – Edge – Design`; confirm the exception is honored (T2.3) |
| Inspection coverage looks low | Too many exceptions, or traffic bypassing steering | Review the exception register (retire stale entries); confirm steering scope; track coverage/exception-rate via `SASE-Report.ps1` — do not chase 100% |

## C. Identity / policy not behaving as designed

| Symptom | Cause | Remediation |
|---|---|---|
| Same action applied to everyone regardless of group | Policy not written identity-first | Rewrite per the policy model (identity → destination → content → action); target named Entra groups, not IP/all-users |
| Wrong allow/block decision | Policy order or destination matching incorrect | Verify the layered evaluation order in `SASE Policy Model – Edge – Design`; re-test the category/app (T2.4) |
| Policy inconsistent between SWG and CASB | Two policy logics drifted apart | Re-align both to the single `SASE Policy Model – Edge – Design`; the whole point is one model across services |

## D. CASB / cloud-app control

| Symptom | Cause | Remediation |
|---|---|---|
| No shadow-IT discovery | Inline visibility not established (Phase 1) or traffic not steered | Confirm Phase 0/1 steering + inspection are active; cloud-app visibility rides the inline path (T3.1) |
| Cloud-app control action wrong | App not classified, or policy not identity-scoped | Classify sanctioned/tolerated/unsanctioned first; write identity-first CASB policy (T3.2–T3.3) |

## E. ZTNA / VPN displacement

| Symptom | Cause | Remediation |
|---|---|---|
| User can't reach an entitled private app | App not published, or user not in the access group | Confirm the app is published and mapped to the user's Entra group (R10); re-check group membership; (connector specifics deferred to Netskope docs) |
| User can reach apps they shouldn't | Over-broad publishing (network-range instead of per-app/least-privilege) | Re-scope publishing to per-app + entitled group; verify non-entitled apps are unreachable (T4.2) |
| Removing VPN broke access | VPN displaced before ZTNA validated | Roll back per R11 (re-enable VPN path); validate ZTNA for the apps first (T4.1–T4.3), then displace |

## F. Phasing / gate violations

| Symptom | Cause | Remediation |
|---|---|---|
| Broad rollout caused widespread breakage | A phase expanded before its pilot gate passed | Roll back the phase (R11); return to pilot scope; do not expand until the pilot acceptance gate is PASS (§05) |
| Coverage/gaps unclear mid-program | No coverage report being run | Run `SASE-Report.ps1` each phase preflight; track the gap matrix and KPIs |

## G. Design / operating-model issues

| Symptom | Cause | Remediation |
|---|---|---|
| Program drifting back to point-tool config | No owner / artifacts not maintained | Assign `SASE Architecture Owner – Edge – Run` (R2); keep the three design artifacts current as living documents (Best Practices §07) |
| Exceptions accumulating unreviewed | No exception-review cadence | Institute the regular exception review in the operating model (§03 Part B3); re-justify or retire each (T6.2) |
| KPIs not measured | Operating model not stood up | Capture the baseline (R12) and keep `SASE-Report.ps1` running (T6.1) |

## H. Tooling / script issues

| Symptom | Cause | Remediation |
|---|---|---|
| A script fails to connect to Graph | Microsoft Graph PowerShell module not installed or not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in with the required read scopes when prompted |
| Remediation made no change | `-WhatIf` is the default (by design) | Re-run with `-Apply` once the preview is correct |
| Netskope-specific automation expected | Netskope module specifics are intentionally deferred | Use Netskope's official API/module documentation for tenant automation; this kit's scripts cover the Graph/identity/edge-readiness side |

---

## When to escalate

If steering is active and correctly scoped, the decryption root is trusted, policy is written
identity-first per the policy model, the exception list is current, and a capability still misbehaves —
collect the `SASE-Discovery.ps1` and `SASE-Validation.ps1` output and the relevant phase's
`Validation Results – <Phase> – Pilot`, and open a support case with your Netskope vendor referencing
the specific capability and policy object.
