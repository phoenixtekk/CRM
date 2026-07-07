# 6. Troubleshooting — Microsoft Teams Rooms Deployment & Management

Common Teams Rooms failure modes with likely root cause and resolution. Each entry names the symptom, how to confirm it, the fix, and how to verify. Use `TEAMSROOMS-Discovery.ps1` / `TEAMSROOMS-Validation.ps1` to confirm tenant-side state; device/firmware symptoms route to the Teams Rooms Pro Management portal and the certified-hardware OEM's documentation.

---

## Room won't join / declines invitations

- **Symptom.** The room declines meeting invites, or accepted meetings never appear on the console.
- **Confirm.** `Get-CalendarProcessing -Identity room-boardroom-a@contoso.com | Select AutomateProcessing, AllowConflicts, ProcessExternalMeetingMessages`.
- **Root cause.** `AutomateProcessing` is not `AutoAccept`; or `AllowConflicts = $false` is rejecting an overlapping booking; or (for external meetings) `ProcessExternalMeetingMessages = $false`.
- **Fix.** Re-run `TEAMSROOMS-Set-RoomPolicy.ps1 -Commit` to apply the standard (Section 3.4); set `AutomateProcessing AutoAccept` and `ProcessExternalMeetingMessages $true`. If overlaps are legitimately being declined, that is expected behaviour with `AllowConflicts $false`.
- **Verify.** T1/T3 and T7 in Section 5 pass; a fresh invite auto-accepts and shows on the console.

## Console shows no subject / no Join button

- **Symptom.** The meeting appears on the console but with a generic title and **no Join button**.
- **Confirm.** `Get-CalendarProcessing -Identity <room> | Select DeleteSubject, DeleteComments, AddOrganizerToSubject`.
- **Root cause.** `DeleteSubject = $true` or `DeleteComments = $true` strips the subject and the invite body — and the body carries the Teams Join link, so no Join button renders. (This is the single most common Teams Rooms misconfiguration.)
- **Fix.** Set `DeleteSubject $false`, `DeleteComments $false`, `AddOrganizerToSubject $false` (Section 3.4 / `TEAMSROOMS-Set-RoomPolicy.ps1`).
- **Verify.** T3 passes; a newly sent invite shows its real subject and a Join button on the console.

## License won't assign

- **Symptom.** `Set-MgUserLicense` fails, or the room has no Teams Rooms capability after assignment.
- **Confirm.** `Get-MgUser -UserId <room> -Property UsageLocation | Select UsageLocation` and `Get-MgSubscribedSku | Select SkuPartNumber, @{N='Avail';E={$_.PrepaidUnits.Enabled-$_.ConsumedUnits}}`.
- **Root cause.** No **UsageLocation** on the account (hard prerequisite for licensing); or **no available seats**; or the wrong **SkuPartNumber** was used (Teams Rooms SKU names vary by tenant).
- **Fix.** Set `UsageLocation` first (`Update-MgUser -UserId <id> -UsageLocation US`), confirm available seats, and resolve the correct SKU from `Get-MgSubscribedSku` — never hardcode a SkuId. Re-run `TEAMSROOMS-Set-ResourceAccount.ps1 -Commit`.
- **Verify.** T2 passes; `Get-MgUserLicenseDetail` lists the Teams Rooms SKU.

## Room signs out / password expired

- **Symptom.** A previously working room shows a sign-in prompt on the console and drops off management.
- **Confirm.** `Get-MgUser -UserId <room> -Property PasswordPolicies, AccountEnabled | Select PasswordPolicies, AccountEnabled`.
- **Root cause.** `PasswordPolicies` does not include `DisablePasswordExpiration`, so the unattended password expired; or the account was disabled; or the password of record was rotated without updating the device.
- **Fix.** Set `Update-MgUser -UserId <id> -PasswordPolicies "DisablePasswordExpiration"` and ensure `AccountEnabled` is true (Section 3.2). If the password was rotated, re-enter it on the device (OEM docs) and store it in the vault.
- **Verify.** T1 passes (`PasswordNeverExpires = True`); the room signs in and stays online.

## Room behaves like a user, not a room

- **Symptom.** The room has end-user meeting behaviour (unexpected lobby, chat, or missing content-sharing) rather than the room standard.
- **Confirm.** `Get-CsOnlineUser -Identity <room> | Select TeamsMeetingPolicy, TeamsCallingPolicy`.
- **Root cause.** The room inherited the **Global/default** policy instead of the room-specific policy.
- **Fix.** Grant `Meeting Policy – Teams Rooms – Prod` and `Calling Policy – Teams Rooms – Prod` (Section 3.5 / `TEAMSROOMS-Set-RoomPolicy.ps1`). Note policy grants can take time to propagate.
- **Verify.** T4 passes; the room shows the room policy names.

## Poor or no audio/video in the room

- **Symptom.** The room joins but has no/one-way audio, no camera, or choppy video.
- **Confirm.** Check the peripherals are certified and selected on the device (OEM console); check the room subnet against Teams media guidance (R5).
- **Root cause.** Non-certified or disconnected peripheral; or network media path blocked/degraded (UDP blocked, forced proxy, no QoS).
- **Fix.** Use certified peripherals (defer device-side selection to OEM docs); with the network team, open required Teams endpoints, allow UDP media, bypass proxy for optimized traffic, and apply QoS (R5). Media quality is a **network/hardware** issue, not a tenant-config issue.
- **Verify.** T5 passes; two-way audio, camera, and content sharing all work from the room.

## Double-booked room

- **Symptom.** Two meetings land on the same slot.
- **Confirm.** `Get-CalendarProcessing -Identity <room> | Select AllowConflicts, ConflictPercentageAllowed, MaximumConflictInstances`.
- **Root cause.** `AllowConflicts = $true` (or a permissive conflict threshold) allows overlapping bookings.
- **Fix.** Set `AllowConflicts $false` unless the room policy intends overlaps (Section 3.4).
- **Verify.** T3 passes; a conflicting invite is declined.

## Room not appearing / unhealthy in Pro Management

- **Symptom.** A Pro room is missing from the Teams Rooms Pro Management portal, or shows **unhealthy/offline**.
- **Confirm.** Check the Teams admin center → **Teams Rooms** for the device, and the Pro Management portal enrollment; confirm the account holds a **Pro** license (not Basic) — Basic rooms are not eligible for full Pro Management.
- **Root cause.** Room not enrolled; assigned a **Basic** (not Pro) license; the device is offline (network/power/sign-in); or (for Government cloud) the wrong portal URL was used.
- **Fix.** Assign a **Pro** license (R1), enroll the device and assign `Config Profile – Teams Rooms – Standard` and an update ring (Section 3.6), and confirm the device is online. **Verify the correct Pro Management portal URL for your cloud** (Commercial vs Government).
- **Verify.** T6 passes; the room shows **healthy** with a profile and update ring.

## External-org meetings don't show on the console

- **Symptom.** Invites from outside the organization never appear on the room.
- **Confirm.** `Get-CalendarProcessing -Identity <room> | Select ProcessExternalMeetingMessages`.
- **Root cause.** `ProcessExternalMeetingMessages = $false`, so external invitations are not processed onto the room calendar.
- **Fix.** Set `ProcessExternalMeetingMessages $true` (Section 3.4).
- **Verify.** T7 passes; an external invite auto-accepts and shows a Join button.

---

### When to escalate to the OEM or network team

Tenant-side configuration (accounts, licensing, calendar processing, policies, Pro Management enrollment) is covered by this solution and its scripts. **Device firmware, on-device setup, physical AV, and peripheral internals** are the certified-hardware OEM's responsibility; **media-path quality** (endpoints, UDP, proxy, QoS) is the network team's. Route those symptoms accordingly rather than changing tenant configuration that is already correct.
