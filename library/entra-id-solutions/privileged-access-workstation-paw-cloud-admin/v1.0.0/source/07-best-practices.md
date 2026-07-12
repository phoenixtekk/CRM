# 7. Best Practices — Privileged Access Workstation (PAW) for Cloud Administration

- Enforce clean source, both device and credential. A PAW protects the device; separate cloud admin accounts protect the credential. Use both — a dedicated PAW and dedicated admin accounts held eligibly in PIM — not one without the other.
- Keep the PAW truly dedicated. No general-purpose email, no open web browsing, no personal apps. The moment a PAW does double duty as a productivity machine, it stops being a PAW. Give admins a separate device for everyday work.
- Always start report-only. Create the device-filter enforcement policy in report-only, read the "would allow / would block" data, and confirm PAW sign-ins pass and non-PAW privileged sign-ins would block before you flip to On.
- Keep break-glass out of enforcement. Exclude `CA Break-Glass Exclusion` from the device-filter policy, always — a marking or compliance mistake must never lock out every administrator. Protect break-glass with strong stored credentials and sign-in alerts.
- Start App Control in audit, then enforce. Application allow-listing is powerful and disruptive; run it in audit on the pilot, tune the allow-list against real admin tooling, then move to enforced during expansion.
- Reserve the device marker for PAWs only. Whatever marks a PAW (extension attribute, category, or group) must be set only on PAWs and never reused for another purpose, or the device filter will admit the wrong devices. Set it with the preview-first tagging script.
- Grant privilege just-in-time from the PAW. Hold admin roles eligible in PIM and activate them from the PAW with MFA, justification, and approval — so privilege is time-bound and only ever exercised from the clean device.
- Layer step-up for the highest-value actions. Optionally require the sensitive authentication context (from the Identity Protection & Advanced Conditional Access solution) on PIM activation for defence in depth.
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for groups, profiles, compliance, and policies so audits, rollbacks, and expansion stay repeatable. Drop `(Report-Only)` only when actually enforced.
- Monitor for non-PAW privileged access. Run `ENTPAW-Report.ps1` on a schedule so any attempt to use privileged access from a non-PAW device is surfaced and closed.
- Verify licensing and preview facts. Intune and Entra ID P2 are required; App Control and some device-filter behaviours may have platform/preview constraints — verify current availability in your tenant rather than assuming.

## Where to go next (adjacent catalog areas)
- **Privileged Identity Management (PIM)** — make the roles operated from the PAW just-in-time and approval-gated; this solution assumes it.
- **Entra Identity Protection & Advanced Conditional Access** — add risk-based access and require a step-up authentication context on PIM activation from the PAW.
- **Conditional Access baseline** — the require-MFA / block-legacy-auth foundation the device-filter policy layers on.
- **Intune endpoint security** (security baselines, ASR, App Control, compliance) — the device-hardening program the PAW build draws on; deepen it for the wider fleet.
- **Passwordless / passkey (FIDO2) rollout** — register phishing-resistant sign-in for the PAW admin accounts.
