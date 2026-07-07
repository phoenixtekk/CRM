# Best Practices

Durable practices for running the client-connectivity toolkit and reducing the volume of
Outlook / OWA / mobile connectivity tickets over time.

## Diagnose by layer, always in order

- **Discovery → Protocol → Auth → Client.** Resist jumping to "recreate the profile" — that is
  a *client-layer* fix and it wastes the ticket when the fault is Autodiscover or Conditional
  Access. Walk the layers; the playbook's D-nodes enforce the order.
- **Reproduce before you remediate.** A fix applied to an unreproduced symptom can't be
  validated and often masks the real cause.

## Make `ConnTest` and OWA your instruments

- Keep a healthy **`ConnTest`** baseline mailbox and use it in *every* isolation: affected user
  vs `ConnTest` on the same client localizes server-vs-client in seconds.
- **OWA is your protocol-independent oracle.** "Works in OWA, fails in Outlook" instantly rules
  the mailbox/auth healthy and points at the desktop protocol/client layer.

## Prefer server-authoritative and external tests

- Trust `Get-CASMailbox`, `Test-OutlookConnectivity`, `Test-OutlookWebServices`, and the Remote
  Connectivity Analyzer over client symptoms — they are authoritative.
- Run **RCA off-network** (or a hotspot) to expose SSL-inspecting proxies / CASB that break
  Autodiscover or the OAuth handshake internally.

## Treat auth loops as policy, not passwords

- A repeating credential prompt is almost never a wrong password — it is a **Conditional Access
  grant the device/app can't satisfy** or an incomplete MFA registration. Read the **Entra
  sign-in logs** (client app + CA result) before touching the client.
- **Never weaken a Conditional Access policy to "fix" a user.** Resolve the *device/app*
  condition (enroll/comply, approved client). If a policy is genuinely misscoped, correct scope
  through the CA owner under change control.

## Respect the version/plan/cloud boundaries

- Autodiscover hosts, RCA endpoints, and some endpoint availability **differ on GCC High / DoD**
  — verify the sovereign values per tenant, never assume Commercial paths.
- `Test-*` cmdlet and parameter availability, OST path/behavior, and mobile client type are
  **version-dependent** — verify in your tenant/build rather than hardcoding.

## Steer clients toward the supported path

- **MAPI over HTTP** is the only supported Outlook desktop transport to Exchange Online
  (Outlook Anywhere/RPC is retired) — treat "enable RPC" requests as out of date.
- **Modern auth only** — Basic Auth is retired; migrate any lingering Basic-Auth client.
- **Outlook mobile (Graph)** over legacy EAS for mobile — fewer connectivity and policy
  failure modes.

## Change safely

- Diagnostics are read-only; the remediation script defaults to a **dry-run** that records the
  prior value. Only `-Commit` after approval, and keep the recorded prior value as the rollback.
- DNS / Autodiscover / SCP / connector-adjacent changes are **high-impact to production mail** —
  stage them under change control with the pass/fail gates in `05-testing.md`.

## Reduce future volume (close the loop)

- Tag every closed ticket with its **root-cause node (D1–D6)**; feed the reporting script's
  output into a monthly trend.
- A cluster on one node is a **systemic fix**: recurring Autodiscover DNS → fix the record and
  documentation; recurring CA auth loops → fix onboarding (device enrollment / approved-app
  guidance); recurring protocol-disabled → fix the mailbox plan / provisioning default.
- Keep the playbook current as Outlook builds, mobile clients, and Conditional Access posture
  change — it is a living runbook, not a one-time document.
