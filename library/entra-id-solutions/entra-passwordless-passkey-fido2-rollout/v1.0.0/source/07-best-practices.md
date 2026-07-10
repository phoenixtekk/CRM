# 7. Best Practices — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra

- Enable the safety net before the credential. Turn on Temporary Access Pass *first*, so every user
  always has a supported, password-free way to bootstrap and recover a passwordless credential. A
  rollout without a recovery path becomes a lock-out.
- Retire weak methods last, and only after adoption. Never scope SMS or Voice out for a group before
  that group has registered a stronger method — gate retirement on the adoption number from
  `ENTPASSKEY-Report.ps1`. This is the single most common way passwordless rollouts lock people out.
- Admins and sensitive apps go phishing-resistant first. Privileged accounts are the highest-value
  targets; require the `Phishing-resistant MFA` authentication strength for them before you widen the
  scope, so the blast radius shrinks immediately.
- Always pilot in report-only. Every Conditional Access enforcement starts as `Report-only`; read the
  impact in `Insights and reporting` and confirm it would not block break-glass before you turn it on.
- Keep break-glass excluded, always. Exclude the two cloud-only emergency accounts from every
  phishing-resistant CA policy, monitor their sign-ins, and test that they are never blocked
  (Testing Test 8).
- Prefer FIDO2 keys for admins and shared devices; passkeys for the workforce. A portable hardware
  key suits people who move between machines or use kiosks; a device-bound passkey in Authenticator
  is the lowest-friction option for users who already carry a phone.
- Consider key restrictions deliberately. AAGUID allow-listing lets you accept only vetted key
  models, but maintain the list — an over-tight restriction blocks legitimate new keys. Enforce
  attestation where your policy requires provenance.
- Roll out in waves, not big-bang. Enable -> register (campaign) -> report-only -> validate ->
  enforce for one group, then repeat. Repeat buyers recognize the same pattern each wave, which keeps
  it low-risk.
- Communicate before you nudge. Send each wave a short "you'll be asked to set up a passkey" note and
  a one-page how-to before the registration campaign hits them; clear comms turn adoption into
  self-service instead of help-desk tickets.
- Verify preview/availability before you commit. Passkey behavior in Authenticator has shipped and
  changed on Microsoft's schedule — confirm the method's current state and any preview flag in your
  tenant before committing a wave to a specific passkey type.
- Operate the lost-key runbook consistently. Verify identity -> revoke the lost credential -> issue a
  TAP -> re-register -> record it. A written, repeatable recovery process keeps the help desk fast and
  safe.
- Make it recurring. Re-run `ENTPASSKEY-Discovery.ps1` and `ENTPASSKEY-Report.ps1` on a cadence so
  new users, drifted method settings, and stalled adoption are caught as they appear.

## Where to go next
- **Zero Trust Architecture — Conditional Access Baseline & Rollout** — build the full persona-based
  Conditional Access baseline that this phishing-resistant requirement slots into.
- **Enterprise App & Service Principal Governance** — close the OAuth consent-phishing foothold that
  survives even strong sign-in.
- **Privileged Identity Management (PIM)** and **Identity Protection risk policies** — pair
  passwordless admins with just-in-time elevation and risk-based access for a complete privileged
  access story.
