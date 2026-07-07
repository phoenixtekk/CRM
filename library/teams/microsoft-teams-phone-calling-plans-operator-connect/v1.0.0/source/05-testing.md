# 5. Testing & Validation — Teams Phone (Calling Plans & Operator Connect)

Run these after the pilot enablement (Implementation §7–§8) and after **each** expansion wave. Each
test states the **procedure** and the **expected pass/fail** signal. The automated report
`Voice Validation – Teams Phone – Report` (from `TEAMSPHONE-Validation.ps1`) backs Tests 1–4; the live
call tests (5–8) must be performed by a person. **Do not expand past the pilot until every test
passes — especially the emergency test (Test 7).**

---

## Test 1 — User is enterprise-voice-enabled with the correct number
- **Procedure:** `Get-CsOnlineUser -Identity <pilot-upn> | Select-Object UserPrincipalName,EnterpriseVoiceEnabled,LineURI`
  and `Get-CsPhoneNumberAssignment -AssignedPstnTargetId <pilot-upn>`.
- **Pass:** `EnterpriseVoiceEnabled = True`, `LineURI` shows the intended `tel:+E164` number, and the
  number's `PhoneNumberType` matches the chosen path (`CallingPlan` or `OperatorConnect`).
- **Fail:** `EnterpriseVoiceEnabled = False`, no/incorrect `LineURI`, or wrong number type → re-check
  licensing (§2.1) and re-run `TEAMSPHONE-Set-NumbersAndPolicy.ps1 -Execute` for the user.

## Test 2 — Voice policies and dial plan are assigned
- **Procedure:** `Get-CsOnlineUser -Identity <pilot-upn> | Select-Object TeamsCallingPolicy,TenantDialPlan,TeamsEmergencyCallingPolicy`.
- **Pass:** `TeamsCallingPolicy = Calling Policy - Standard - Prod`, `TenantDialPlan = Dial Plan - US -
  Prod`, `TeamsEmergencyCallingPolicy = Emergency Calling Policy - HQ - Prod`.
- **Fail:** any shows global/blank when it should be the named policy → re-grant with the correct
  `Grant-Cs*` cmdlet and confirm the artifact name matches exactly.

## Test 3 — Emergency location is attached
- **Procedure:** `Get-CsPhoneNumberAssignment -AssignedPstnTargetId <pilot-upn> | Select-Object TelephoneNumber,LocationId`
  and cross-check with `Get-CsOnlineLisLocation -LocationId <id>`.
- **Pass:** the number has a `LocationId` resolving to `Emergency Location – HQ-Floor1` (or the correct
  site place), and dynamic identifiers (subnet/AP) for the pilot site are registered.
- **Fail:** `LocationId` empty or wrong → attach the location via
  `Set-CsPhoneNumberAssignment -LocationId <id>` and confirm the LIS mapping (§ Implementation Step 4).

## Test 4 — Spare inventory and no double-assignment
- **Procedure:** `TEAMSPHONE-Discovery.ps1` (or `Get-CsPhoneNumberAssignment -PstnAssignmentStatus
  Assigned`).
- **Pass:** each assigned number maps to exactly one target; no number appears assigned to two objects;
  spare numbers still show `Unassigned`.
- **Fail:** a duplicate/orphaned assignment → unassign the incorrect one with
  `Remove-CsPhoneNumberAssignment` and reassign correctly.

## Test 5 — Outbound PSTN call
- **Procedure:** From a pilot user's Teams client, place a call to an external mobile. Try an extension
  or local-format number to confirm the dial plan normalizes it.
- **Pass:** the call connects, two-way audio is clear, and the called party sees the pilot user's
  assigned number as caller ID; local/extension dialing normalizes correctly.
- **Fail:** call fails, one-way/no audio, or normalization wrong → check network readiness (§2.7),
  `TenantDialPlan` normalization rules, and number assignment.

## Test 6 — Inbound PSTN call
- **Procedure:** From an external phone, call the pilot user's assigned number.
- **Pass:** the pilot user's Teams client rings and answers with clear two-way audio.
- **Fail:** no ring / straight to voicemail unexpectedly → confirm the number is assigned to the user
  (Test 1), the user is signed in, and call-answering/forwarding settings are as expected.

## Test 7 — Emergency call (coordinated, live) — MANDATORY GATE
- **Procedure:** **Coordinate with the carrier/operator and your security/facilities function first**
  (Requirement 2.5). Using the method they confirm (a validated emergency test service where offered,
  or a supervised live test), place an emergency call from a pilot user at the pilot site.
- **Pass:** the call routes correctly for the country/region; the **security-desk notification** defined
  in `Emergency Calling Policy – HQ – Prod` fires to the notification target; and the **location
  presented/known** matches `Emergency Location – HQ-Floor1` (or the user's actual dynamic location).
- **Fail:** no notification, wrong/absent location, or routing failure → **stop the rollout**; fix the
  LIS mapping, the emergency calling policy, and confirm carrier/operator emergency support before
  re-testing. Emergency routing behavior is **country/plan-dependent — verify in your tenant/region**.

## Test 8 — Auto attendant and call queue
- **Procedure:** Call the service number for `Auto Attendant – MainLine – Prod`. Navigate the menu to
  the option that routes to `Call Queue – Support – Prod`. Have an agent answer; also test the
  overflow/timeout path (e.g. no agent available).
- **Pass:** the auto attendant answers with the greeting/menu, honors business-hours vs after-hours
  routing, and the selected option rings the call queue agents; overflow/timeout behaves as configured.
- **Fail:** no answer, wrong routing, or schedule ignored → confirm the resource accounts are licensed
  and hold their service numbers, the app associations exist
  (`Get-CsOnlineApplicationInstanceAssociation`), and the schedule/menu configuration.

---

### Pilot exit criteria (all must be true)
- Tests 1–4 pass for **every** pilot user in `Voice Validation – Teams Phone – Report`.
- Tests 5 and 6 (outbound + inbound) pass with clear two-way audio.
- **Test 7 (emergency) passes** with correct notification and location.
- Test 8 passes for the auto attendant and call queue (if in scope).
- No unresolved errors in the validation report. Only then run Implementation **Step 10 (Expand)**.
