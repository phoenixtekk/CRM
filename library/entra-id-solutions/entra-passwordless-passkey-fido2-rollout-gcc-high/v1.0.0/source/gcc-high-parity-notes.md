# GCC High Parity & Compliance Notes — Passwordless & Passkey (FIDO2) Rollout

This is the **Government (GCC High)** edition of the passwordless/passkey solution. It mirrors the
commercial phishing-resistant-MFA method exactly, adapted for Microsoft's **US Government national
cloud** (Azure Government / GCC High). This note collects the national-cloud endpoints, the feature-
parity items to verify, and the compliance/data-residency context specific to government tenants.

> Everything here is technical context for your operators and your ISSO/compliance team. Accreditation
> boundary and impact-level (IL) determinations are the **customer's** decision — this note provides the
> technical facts, not the authorization. Never assume commercial parity: **verify every capability
> against current Microsoft Government documentation.**

## National cloud endpoints

The rollout is configured in the GCC High Entra admin center, users register at the GCC High security-
info portal, and the included scripts target the US Gov cloud. Use these hosts in place of the
commercial ones:

| Purpose | Commercial | GCC High (this edition) | DoD (IL5) — verify |
|---|---|---|---|
| Sign-in / token host | `login.microsoftonline.com` | `login.microsoftonline.us` | `login.microsoftonline.us` |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` | `dod-graph.microsoft.us` |
| Microsoft Graph SDK env | `Global` | `-Environment USGov` | `-Environment USGovDoD` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` | `entra.microsoft.us` (*verify*) |
| Security-info / My Sign-Ins (user registration) | `mysignins.microsoft.com` / `aka.ms/mysecurityinfo` | `mysignins.microsoft.us/security-info` | *verify current DoD URL* |
| M365 / admin center | `admin.microsoft.com` | `portal.office365.us` / GCC High admin center | *verify current GCC High URL* |

All five PowerShell scripts (`ENTPASSKEYG-*`) connect with `Connect-MgGraph -Environment USGov`. Note the
`ENTPASSKEYG-Set-ScopeTargeting.ps1` script builds `@odata.id` directory-object references against the
national-cloud Graph host (`https://graph.microsoft.us/...`) — for DoD use `https://dod-graph.microsoft.us/...`.
**Verify the correct cloud and endpoints for your specific tenant** — GCC High and DoD are distinct clouds.

## Feature-parity considerations

GCC High and DoD frequently **lag commercial** on feature rollout, previews, and method availability,
and some capabilities are unavailable. For a passwordless/passkey rollout specifically, confirm the
following in *current Microsoft Government documentation* before relying on them — do **not** assume
commercial parity:

- **Passkey (device-bound) in Microsoft Authenticator** — this is the newest and most likely-to-lag
  capability. Device-bound passkey support, synced-passkey handling, and any preview flags **may be
  delayed or unavailable in GCC High/DoD.** *Verify the Passkey option is available under Authentication
  methods → Microsoft Authenticator in your cloud* before committing a wave to it. If unavailable, fall
  back to **FIDO2 security keys** (broadly supported) for that wave.
- **FIDO2 security keys** — generally available across clouds, but confirm attestation and AAGUID
  key-restriction behavior in your government cloud. *Verify.*
- **Conditional Access authentication strengths** — the built-in **Phishing-resistant MFA** strength is
  the enforcement control; *verify the built-in authentication-strength catalog and any custom-strength
  support in Azure Government.*
- **Registration campaign** — the nudge-to-register feature and its options may differ or lag in the
  government cloud. *Verify availability and behavior.*
- **Temporary Access Pass (TAP)** — confirm TAP is available and its lifetime/one-time options behave as
  documented in your cloud. *Verify.*
- **Graph API shapes / method `@odata.type` values** — how a passkey surfaces (as a `fido2AuthenticationMethod`
  vs. a Microsoft Authenticator method) can vary by tenant, cloud, and API version; the adoption report
  accounts for both but *verify against your tenant.*
- **Entra ID P1/P2 licensing** — Conditional Access enforcement needs P1 (risk conditions need P2).
  Government SKUs, availability, and bundling differ from commercial. *Verify P1/P2 availability for your
  GCC High (or DoD) tenant.*

## Compliance & data-residency context (why GCC High)

GCC High exists so US public-sector and defense-industrial-base organizations can meet federal data-
handling obligations that commercial Microsoft 365/Azure cannot. Phishing-resistant, passwordless
authentication is not just good hygiene here — it is a **mandated control**:

- **OMB Memorandum M-22-09 — federal Zero Trust mandate.** *Moving the U.S. Government Toward Zero Trust
  Cybersecurity Principles* **requires** agencies to enforce **phishing-resistant MFA** for staff,
  contractors, and partners, explicitly naming **FIDO2 / WebAuthn** and PIV as the acceptable methods.
  This rollout — FIDO2 security keys and passkeys enforced via the Conditional Access phishing-resistant
  authentication strength — is the direct technical implementation of that requirement. (M-22-09 is the
  primary government driver for this solution.)
- **FedRAMP High** — GCC High / Azure Government are designed to support FedRAMP High authorization
  boundaries. Phishing-resistant MFA maps to the Identification & Authentication (IA) and Access Control
  (AC) control families an ISSO must evidence.
- **DoD Impact Levels (IL4 / IL5)** — Azure Government / GCC High and the DoD cloud support IL4 and IL5
  workloads respectively. **Which impact level applies is the customer's ISSO/compliance determination.**
  For IL5, use the DoD endpoints (`dod-graph.microsoft.us`, `-Environment USGovDoD`) — *verify*.
- **CMMC 2.0** — for defense-industrial-base contractors, phishing-resistant authentication supports the
  Identification & Authentication (IA) practices (multifactor and replay-resistant authentication for
  privileged and network access). This solution provides the technical control; your C3PAO assessor
  evaluates the practice.
- **ITAR / EAR data residency & US-persons handling** — GCC High provides US-sovereign data residency and
  US-persons operational support, which is why organizations handling ITAR/EAR-controlled technical data
  choose it. Protecting sign-in to that environment with phishing-resistant credentials is exactly what
  this rollout does. *Confirm your data-residency and US-persons obligations with your compliance team.*

Determinations of accreditation boundary, impact level, control applicability, and which apps/users are
in scope are the customer's ISSO/compliance and business decision. This solution supplies the technical
implementation and evidence (methods-policy discovery, adoption reporting, enforcement validation) — not
the authorization.

## DoD (IL5) note

Where a tenant operates at **DoD IL5** rather than GCC High, the cloud and endpoints differ:

- Microsoft Graph host: **`dod-graph.microsoft.us`** (not `graph.microsoft.us`).
- Graph SDK: `Connect-MgGraph -Environment USGovDoD`; the `@odata.id` directory-object references in
  `ENTPASSKEYG-Set-ScopeTargeting.ps1` must use `https://dod-graph.microsoft.us`.
- Confirm the correct Entra admin center / security-info portal URLs and passkey/FIDO2 method
  availability for the DoD cloud — DoD feature availability can differ from GCC High and change over time.

All of the above is **"verify against current Microsoft Government documentation."**
