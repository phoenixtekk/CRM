# 6. Troubleshooting — Teams Phone (Calling Plans & Operator Connect)

Common failure modes and how to resolve them. Use the read-only scripts
(`TEAMSPHONE-Discovery.ps1`, `TEAMSPHONE-Validation.ps1`, `TEAMSPHONE-Scope.ps1`) to pinpoint the issue
before changing anything, and reuse the named artifacts from the Overview.

---

## A number won't assign (`Set-CsPhoneNumberAssignment` errors)
- **Symptom:** assignment fails with a licensing, number-type, or "not found" error.
- **Likely causes & fixes:**
  - **Missing Teams Phone license** — confirm the user has Teams Phone (and, for Calling Plans, a
    calling plan / pay-as-you-go add-on). Fix per Requirement 2.1, then retry.
  - **Wrong `-PhoneNumberType`** — the type must match how the number was provisioned (`CallingPlan`
    vs `OperatorConnect`). Check the number in `Get-CsPhoneNumberAssignment` and pass the matching type.
  - **Number not in tenant / still provisioning** — for Operator Connect, the operator must finish
    provisioning before the number appears; re-check `Voice → Phone numbers`. For Calling Plans, confirm
    the `Get new numbers` order or port order completed.
  - **Number already assigned** — a number can only target one object; unassign it first
    (`Remove-CsPhoneNumberAssignment`).

## User has a number but is not enterprise-voice-enabled
- **Symptom:** `Get-CsOnlineUser` shows `LineURI` set but `EnterpriseVoiceEnabled = False`, or calls
  don't work.
- **Fix:** `Set-CsPhoneNumberAssignment` normally enables enterprise voice; if it didn't, confirm
  licensing propagated (new licenses can take time), re-run the assignment, and allow policy
  propagation before testing. Validate with `TEAMSPHONE-Validation.ps1`.

## Policies show "Global" instead of the named policy
- **Symptom:** `TeamsCallingPolicy` / `TenantDialPlan` / `TeamsEmergencyCallingPolicy` is blank/Global
  after enablement.
- **Fix:** re-grant with the exact policy name (`Grant-CsTeamsCallingPolicy -PolicyName "Calling Policy
  - Standard - Prod"`, etc.). **Watch the naming caveat:** PowerShell identities use the ASCII hyphen
  form (`Calling Policy - Standard - Prod`), not the en-dash used in the display name — a mismatch means
  "policy not found." Confirm the policy exists (`Get-CsTeamsCallingPolicy`).

## Extension or local-format dialing fails
- **Symptom:** dialing a full E.164 number works, but extensions or local formats fail.
- **Fix:** the **Tenant Dial Plan** normalizes dialed strings. Confirm `Dial Plan - US - Prod` is
  granted to the user and its normalization rules (`New-CsVoiceNormalizationRule`) cover the pattern.
  Test rules with `Get-CsEffectiveTenantDialPlan -Identity <upn>` and its test cmdlet
  (`Test-CsEffectiveTenantDialPlan`) — **verify exact cmdlet availability in your tenant**. Remember the
  **Online Voice Routing Policy is Direct-Routing-only** and is not the cause here.

## Emergency call has no location or no notification
- **Symptom:** Test 7 fails — the emergency call presents no/wrong location, or the security desk isn't
  notified.
- **Fix:**
  - **Location:** confirm the number has a `LocationId` (`Get-CsPhoneNumberAssignment
    -AssignedPstnTargetId <upn>`) resolving to `Emergency Location – HQ-Floor1`, and that the site's
    subnets/APs are mapped (`Get-CsOnlineLisSubnet`, `Get-CsOnlineLisWirelessAccessPoint`). Attach with
    `Set-CsPhoneNumberAssignment -LocationId <id>`.
  - **Notification:** confirm `Emergency Calling Policy – HQ – Prod` has the notification target/mode
    set and is granted to the user.
  - **Routing:** for Calling Plans/Operator Connect, PSAP routing is Microsoft's/the operator's
    responsibility (the Emergency Call *Routing* Policy is Direct-Routing-only). If routing itself
    fails, engage the carrier/operator — **do not** try to fix it with a customer routing policy.
    Emergency behavior is **country/plan-dependent — verify in your tenant/region**.

## Poor call quality / one-way or no audio
- **Symptom:** calls connect but audio is choppy, delayed, or one-way.
- **Fix:** this is almost always a **network** issue, not licensing. Verify the required Microsoft 365
  media endpoints are reachable and not proxied, adequate bandwidth and low jitter/latency, and QoS if
  used (Requirement 2.7). Test from a different network to isolate. Check the client's audio device.

## Auto attendant or call queue doesn't answer / routes wrong
- **Symptom:** calling the service number fails, ignores the schedule, or doesn't reach agents.
- **Fix:**
  - Confirm the **resource account is licensed** (Teams Phone Resource Account) and **holds a service
    number** (`Get-CsOnlineApplicationInstance`).
  - Confirm the **association** exists (`Get-CsOnlineApplicationInstanceAssociation -Identity
    <resourceaccount>`) linking the account to `Auto Attendant – MainLine – Prod` /
    `Call Queue – Support – Prod`.
  - Confirm the **schedule/menu** (business hours, holidays, DTMF option) and that the call queue has
    online agents and the expected routing/overflow/timeout.

## Operator Connect numbers never appear
- **Symptom:** the operator is selected but no numbers show under `Voice → Phone numbers`.
- **Fix:** Operator Connect requires the operator to **provision** numbers into your tenant after
  onboarding. Confirm the operator is enabled in `Voice → Operators`, that onboarding/consent completed,
  and follow up with the operator — provisioning is on their side, not a Teams misconfiguration.

## Government cloud (GCC High / DoD) behaves differently
- **Symptom:** a portal path, feature, or cmdlet result differs from what's documented.
- **Fix:** Calling Plan / Operator Connect availability, admin portals, and some behavior differ in
  government clouds. **Verify the feature, URL, and cmdlet behavior for your specific cloud/tenant** —
  do not assume Commercial guidance applies unchanged.

## Rollback needed for a user
- **Symptom:** a user must be backed out of Teams Phone.
- **Fix:** `TEAMSPHONE-Set-NumbersAndPolicy.ps1 -Rollback -WhatIf` to preview, then `-Rollback -Execute`
  to unassign the number and reset the dial plan / calling / emergency policies to Global. For voice
  apps, remove the association (`Remove-CsOnlineApplicationInstanceAssociation`) and unassign the
  service number.

---

*If a symptom isn't listed, start with `TEAMSPHONE-Validation.ps1` to get the per-user PASS/FAIL, then
work the failing check with the matching section above. Plan-, country-, operator-, and cloud-dependent
behavior is always "verify in your tenant" — never assume.*
