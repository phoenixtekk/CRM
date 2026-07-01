# 3. Implementation Guide — SSL/TLS Inspection & Decryption Rollout (Netskope)

Follow these steps in order. Certificate deployment is performed in the Microsoft Intune admin center
(`https://intune.microsoft.com`); the decryption policy and bypass list are configured in your
Netskope tenant admin console.

> Model: Establish certificate trust on devices first, build the decryption policy with the
> do-not-decrypt bypass list, steer only the pilot group, validate apps and user experience, then
> expand to the fleet. Pilot validates before any broad enforcement.

> Vendor note: exact Netskope console screens and menu paths change over time and are deferred to the
> official Netskope documentation and your tenant. Steps below name the action and the artifact;
> confirm the precise control in your Netskope console.

Named artifacts (create with these exact names and reuse verbatim):

- Trusted cert profile: `Netskope Inspection Root – All Managed Devices – Pilot`
- Trusted cert profile: `Netskope Inspection Root – All Managed Devices – Production`
- Decryption policy: `SSL Inspection – Pilot Group – Pilot`
- Decryption policy: `SSL Inspection – All Users – Production`
- Bypass list: `Do-Not-Decrypt – Sensitive & Pinned – All Stages`
- Pilot group: `SSL Inspection – Pilot Users – Pilot`
- Broad group: `SSL Inspection – All Users – Production`

## Step 1 — Assess (discovery)
1. Run `NSSSL-Discovery.ps1` on representative devices to report whether an inspection root is already
   trusted, the OS/store state, and any obvious certificate-trust gaps. Read-only.
2. Confirm the requirements in section 2 are met; export the inspection certificate root/intermediate
   from your Netskope tenant (location deferred to Netskope docs).

## Step 2 — Create the scope groups
1. Entra -> Groups -> New group -> Security -> `SSL Inspection – Pilot Users – Pilot` (a few
   representative users/devices). Create. Or run `NSSSL-Set-ScopeTargeting.ps1` to populate it.
2. Entra -> Groups -> New group -> Security -> `SSL Inspection – All Users – Production` (the rest of
   the fleet). Create.

## Step 3 — Deploy the inspection certificate root via Intune (pilot)
1. Intune -> Devices -> Configuration -> Create -> New policy.
2. Platform: Windows 10 and later. Profile type: Templates -> Trusted certificate. Create.
3. Name: `Netskope Inspection Root – All Managed Devices – Pilot`. Next.
4. Configuration settings: upload the inspection root certificate file (`.cer`); destination store:
   Computer certificate store - Root. Next.
   - If the inspection chain includes an intermediate, deploy it as a second Trusted certificate
     profile to the Intermediate store.
5. Assignments -> Add groups -> `SSL Inspection – Pilot Users – Pilot`. Next -> Create.

## Step 4 — Build the do-not-decrypt bypass list
1. In the Netskope console, create the bypass list `Do-Not-Decrypt – Sensitive & Pinned – All Stages`.
2. Add the do-not-decrypt entries (exact menu deferred to Netskope docs):
   - Banking / financial categories.
   - Health / medical categories.
   - Certificate-pinned applications (so they are passed through, not broken).
   - Other sensitive personal categories per your privacy policy (legal, government, etc.).
3. This single named list is reused by both the pilot and production decryption policies.

## Step 5 — Create the pilot decryption policy
1. In the Netskope console, create the decryption (SSL inspection) policy `SSL Inspection – Pilot
   Group – Pilot`.
2. Source/scope: the pilot users/devices that correspond to `SSL Inspection – Pilot Users – Pilot`.
3. Action: decrypt, with the do-not-decrypt bypass list `Do-Not-Decrypt – Sensitive & Pinned – All
   Stages` applied ahead of the decrypt rule (bypass evaluated first).
4. Save the policy but stage it to the pilot scope only — do not apply broadly yet.

## Step 6 — Validate certificate trust on a pilot device
1. On a pilot device, force a policy sync (Settings -> Accounts -> Access work or school -> Info ->
   Sync) so the Intune trusted-certificate profile applies.
2. Run `NSSSL-Validation.ps1` to confirm the inspection root is present in the trusted root store and
   the chain validates. Read-only.
3. If the root is missing, run `NSSSL-Remediation.ps1` (default `-WhatIf`) to preview the sync, then
   re-run with `-Execute` to request a sync, and re-validate.

## Step 7 — Validate the pilot (apps + user experience)
1. On a pilot device, browse decrypted sites and confirm no certificate warnings appear.
2. Open the do-not-decrypt categories (a banking site, a health site) and confirm they are passed
   through (their original certificate is presented, not the inspection certificate).
3. Open known certificate-pinned applications and confirm they still work (bypassed, not broken).
4. Run `NSSSL-Report.ps1` to capture certificate-trust and decryption-readiness state across pilot
   devices. Complete the Testing Guide and its pass/fail gate.

### Pilot gate
Do not proceed to Step 8 until the pilot gate in the Testing Guide passes: certificate trust is
silent (no warnings) on pilot devices, the do-not-decrypt categories are confirmed bypassed, and
known pinned applications still work. If the gate fails, use the rollback below and remediate before
retrying.

> Rollback: disable the `SSL Inspection – Pilot Group – Pilot` decryption policy (or remove pilot
> members), which immediately stops decrypting their traffic; remove the trusted-certificate profile
> assignment only if trust itself must be reverted. Communicate per the change plan.

## Step 8 — Expand certificate trust to the fleet
1. Create the production trusted-certificate profile `Netskope Inspection Root – All Managed Devices –
   Production` (same root certificate, Computer store - Root) and assign it to `SSL Inspection – All
   Users – Production`.
2. Confirm trust deploys broadly (spot-check with `NSSSL-Validation.ps1`) before enabling broad
   decryption — trust must lead decryption, never trail it.

## Step 9 — Expand decryption to production
1. In the Netskope console, create `SSL Inspection – All Users – Production` decryption policy with
   the same do-not-decrypt bypass list `Do-Not-Decrypt – Sensitive & Pinned – All Stages`, scoped to
   `SSL Inspection – All Users – Production`.
2. Roll out in stages, re-validating with `NSSSL-Validation.ps1` and `NSSSL-Report.ps1` each stage,
   and chase any devices missing certificate trust before they hit decryption.

---
### Order of operations
`Discover -> Scope groups -> Deploy cert (pilot) -> Build bypass list -> Pilot decryption policy ->
Validate trust -> Validate pilot (apps/UX) -> [pilot gate] -> Expand cert (fleet) -> Expand
decryption`
