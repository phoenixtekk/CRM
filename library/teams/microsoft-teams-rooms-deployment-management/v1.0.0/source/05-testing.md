# 5. Testing & Validation — Microsoft Teams Rooms Deployment & Management

These procedures validate the pilot room against the **Phase 5** gates in Section 3. Each test states **what to do**, the **expected pass**, and the **fail signal** (which routes to Section 6). Run them in order; the pilot is validated only when **every** test passes. Use `TEAMSROOMS-Validation.ps1` to automate the object-state checks (T1–T4, T6) and perform the in-room checks (T5) by hand.

Canonical objects under test: `Room Account – Boardroom-A – Pilot` (`room-boardroom-a@contoso.com`), `Meeting Policy – Teams Rooms – Prod`, `Calling Policy – Teams Rooms – Prod`, `Config Profile – Teams Rooms – Standard`, `Update Ring – Teams Rooms – Pilot`.

---

## T1 — Resource account is provisioned correctly (Gate V1)

- **Do.** Exchange Online: `Get-Mailbox room-boardroom-a@contoso.com | Select RecipientTypeDetails`. Graph: `Get-MgUser -UserId room-boardroom-a@contoso.com -Property AccountEnabled,UsageLocation,PasswordPolicies | Select AccountEnabled,UsageLocation,PasswordPolicies`.
- **Pass.** `RecipientTypeDetails = RoomMailbox`; `AccountEnabled = True`; `UsageLocation` is set; `PasswordPolicies` contains `DisablePasswordExpiration`.
- **Fail.** Not a room mailbox, account disabled, no usage location, or password can expire → Section 6, "Room signs out / password expired" and "License won't assign".

## T2 — Teams Rooms license is assigned (Gate V2)

- **Do.** `Get-MgUserLicenseDetail -UserId room-boardroom-a@contoso.com | Select SkuPartNumber`.
- **Pass.** A Teams Rooms SKU (Pro for the pilot) is listed. **Verify the exact SkuPartNumber for your tenant.**
- **Fail.** No Teams Rooms SKU, or an unexpected SKU → Section 6, "License won't assign".

## T3 — Calendar processing matches the standard (Gate V3)

- **Do.** `Get-CalendarProcessing -Identity room-boardroom-a@contoso.com | Select AutomateProcessing,AddOrganizerToSubject,DeleteSubject,DeleteComments,ProcessExternalMeetingMessages,AllowConflicts`.
- **Pass.** `AutomateProcessing = AutoAccept`; `AddOrganizerToSubject = False`; `DeleteSubject = False`; `DeleteComments = False`; `ProcessExternalMeetingMessages = True`; `AllowConflicts = False`.
- **Fail.** Subject/body being stripped (join button/agenda missing on console) or double-booking allowed unexpectedly → Section 6, "Console shows no subject / no Join button" and "Double-booked room".

## T4 — Room policies are granted (Gate V4)

- **Do.** `Get-CsOnlineUser -Identity room-boardroom-a@contoso.com | Select TeamsMeetingPolicy, TeamsCallingPolicy`.
- **Pass.** `TeamsMeetingPolicy = Meeting Policy - Teams Rooms - Prod` and `TeamsCallingPolicy = Calling Policy - Teams Rooms - Prod`.
- **Fail.** Policies show the global/default or the wrong name → re-run Section 3.5; see Section 6, "Room behaves like a user, not a room".

## T5 — Room books and one-touch-joins with working media (Gate V5)

- **Do.** From a normal user, create a Teams meeting and add `Room Account – Boardroom-A – Pilot` as a resource. Then, at the room console: confirm the meeting appears with its subject and a **Join** button; press **Join**; speak, share video, and share content from a laptop.
- **Pass.** The invite auto-accepts; the console shows subject and Join; one touch joins; two-way audio, camera video, and content sharing all work.
- **Fail.** Invite declined or not shown; no Join button; no/poor audio or video; content won't share → Section 6, "Room won't join / declines invites", "Console shows no subject / no Join button", "Poor or no audio/video".

## T6 — Room is centrally managed and healthy (Gate V6)

- **Do.** In the **Teams Rooms Pro Management** portal (verify URL for your cloud) and **Teams admin center → Teams Rooms**, locate the room.
- **Pass.** The room is **online/enrolled**, shows **healthy** status, has `Config Profile – Teams Rooms – Standard` applied, and is in `Update Ring – Teams Rooms – Pilot`.
- **Fail.** Room absent, unhealthy, unenrolled, or no update ring → Section 6, "Room not appearing / unhealthy in Pro Management".

## T7 — External-org meeting appears (regression)

- **Do.** Have someone outside the org invite the room to a Teams meeting.
- **Pass.** The external invitation auto-accepts and shows on the console with a Join button (because `ProcessExternalMeetingMessages = True`).
- **Fail.** External invite ignored → re-check T3 and Section 6.

---

## Validation sign-off

Record the pass/fail for T1–T7, the tester, and the date. **All must pass** before Phase 6 (Expand). Re-run T1–T4 and T6 with `TEAMSROOMS-Validation.ps1` after any later change to the room, and re-run T5 after firmware/software updates land via the update ring.
