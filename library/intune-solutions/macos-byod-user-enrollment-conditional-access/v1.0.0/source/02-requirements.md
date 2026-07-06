# 2. Requirements — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to macOS BYOD
account-driven user enrollment and the Conditional Access gate.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and
Microsoft Entra at `https://entra.microsoft.com` unless noted.

## R1. Microsoft Intune with macOS enrollment allowed
**Description:** An Intune-licensed tenant where the **macOS** platform is permitted to enroll.
**Why:** An enrollment restriction that blocks macOS will silently stop BYOD Macs from onboarding.
**Verify:** Intune → **Devices → Enrollment → Enrollment device platform restrictions → macOS** shows
**Personally owned devices = Allow**.
**Implement:** Edit the default (or a pilot-targeted) restriction to **Allow** macOS personally owned
devices for the pilot group.

## R2. Account-driven user enrollment supported OS floor
**Description:** Target Macs run a macOS version that supports **account-driven user enrollment**.
**Why:** Account-driven **user** enrollment is a modern macOS capability; older Macs may only support
device enrollment (Model B). Do not assume — confirm and flag anything below the floor.
**Verify:** On the Mac, **Apple menu → About This Mac**; or after onboarding, Intune → device →
**Hardware**. *Uncertain about the exact minimum for your fleet? Flag it and confirm against Microsoft's
current macOS enrollment documentation rather than guessing — the floor has moved across macOS releases.*
**Implement:** Update the Mac via **System Settings → General → Software Update**, or set a
minimum-OS **compliance policy** so Macs below the floor are flagged. Where a Mac cannot meet the floor,
fall back to **device enrollment** (Overview, Model B).

## R3. Managed Apple Account capability (Apple identity for user enrollment)
**Description:** The tenant/domain can issue or federate a **managed Apple Account** used by
account-driven user enrollment for the corporate scope.
**Why:** Account-driven user enrollment provisions a **managed Apple Account** and an isolated managed
volume; the user's **personal** Apple ID is left alone. Without a managed Apple Account path, the
corporate scope cannot be established.
**Verify:** Confirm your organization's managed Apple Account approach (federated with Entra, or issued)
is in place for the pilot users. *If you are unsure whether managed Apple Accounts are configured for
your org, flag it and confirm before piloting — do not invent a state that isn't there.*
**Implement:** Establish managed Apple Accounts per Apple's current guidance (federation with Microsoft
Entra ID is the common path). Coordinate with whoever owns your Apple identity relationship.

## R4. macOS BYOD compliance policy (scoped to the pilot)
**Description:** An Intune **compliance policy** for macOS defining what "healthy enough for access"
means for BYOD (e.g. minimum OS, disk encryption where applicable, no jailbreak/gatekeeper issues).
**Why:** Conditional Access can only require a **compliant** Mac if a compliance policy exists and is
**assigned** to the Mac. No policy → no compliance signal → the CA gate cannot use it.
**Verify:** Intune → **Devices → Compliance policies**; a macOS policy named **`macOS BYOD Compliance -
Pilot`** exists and is assigned to your pilot group.
**Implement:** Create it during deployment (Implementation §Phase 2), or start from the settings there
and assign it to **`BYOD-Mac-Pilot`**.

## R5. Conditional Access capability (Entra ID P1 or higher)
**Description:** A licensing plan that includes **Conditional Access** (Entra ID P1, included in
Microsoft 365 E3/E5 and Business Premium).
**Why:** The access gate — "require a compliant/enrolled Mac" — is a Conditional Access policy.
**Verify:** Entra → **Protection → Conditional Access** loads and lets you create policies; **Entra →
Overview → Licenses** shows a P1 (or higher) plan.
**Implement:** Assign an Entra ID P1-bearing license (E3/E5/Business Premium) to the admins and the
pilot users in scope.

## R6. Break-glass (emergency access) accounts
**Description:** Two cloud-only **emergency access** accounts excluded from Conditional Access.
**Why:** A misconfigured CA policy can lock **everyone** out. Break-glass accounts are your way back in.
**Verify:** Entra → **Users**; two dedicated emergency accounts exist and are **excluded** from all
CA policies (Entra → Protection → Conditional Access → each policy → Users → Exclude).
**Implement:** Create two cloud-only accounts (long random passwords, stored securely, MFA per Microsoft
guidance), and **exclude** them from every CA policy before you enable any policy.

## R7. Pilot user identities and their personal Macs
**Description:** A small set of **pilot users** who will onboard their **own** Macs, and a Microsoft
Entra security group named **`BYOD-Mac-Pilot`** containing them.
**Why:** Account-driven user enrollment is **user-initiated**; you need willing pilot users who will add
their work account on a real personal Mac to validate the end-to-end experience.
**Verify:** Entra → **Groups → `BYOD-Mac-Pilot`** exists with the pilot users as members.
**Implement:** Entra → **Groups → New group → Security**, name it **`BYOD-Mac-Pilot`**, add the pilot
users. (This is the category Global Requirement G5, named for this solution.)

## R8. User communication / consent for BYOD
**Description:** A short user-facing message explaining what account-driven user enrollment does and
does **not** do to a personal Mac.
**Why:** BYOD only works if users trust it. They must understand the corporate scope is isolated and
only managed data is ever removed — and that you cannot see or wipe their personal data.
**Verify:** A one-page BYOD explainer exists for pilot users (privacy scope, what's managed, how to
remove the work account).
**Implement:** Draft it from the Overview's "How it works" and "privacy" points; the Best Practices
guide lists exactly what to tell users.

## R9. Network access to Microsoft and Apple endpoints
**Description:** Outbound HTTPS from the pilot Macs to Microsoft Entra/Intune and to Apple's identity
and enrollment endpoints.
**Why:** Sign-in, enrollment, managed Apple Account provisioning, policy sync, and Conditional Access
evaluation all depend on these endpoints.
**Verify:** From the Mac's network, reach `https://login.microsoftonline.com`,
`https://enrollment.manage.microsoft.com`, and Apple's identity/enrollment endpoints (e.g.
`https://gdmf.apple.com`, `https://identity.apple.com`).
**Implement:** Allow Microsoft's published Microsoft 365/Intune/Entra URL & IP ranges and Apple's
published enrollment/identity ranges through proxy/firewall. Do **not** TLS-inspect Apple enrollment
and push traffic.

## R10. Administrative roles for enrollment, compliance, and Conditional Access
**Description:** The operator holds the roles needed to configure enrollment/compliance (**Intune
Administrator**) and Conditional Access (**Conditional Access Administrator** or **Security
Administrator**).
**Why:** Creating the enrollment type, the compliance policy, and the CA policy requires elevated rights
across both Intune and Entra.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** and a CA-capable
role are assigned to the operator.
**Implement:** Assign **Intune Administrator** plus **Conditional Access Administrator** (or **Security
Administrator**); reserve Global Administrator for tenant-wide changes.
