# Troubleshooting Guide

Symptom → most likely cause → verify → fix, for the iOS/iPadOS enrollment **"Access Denied / not
authorized"** failure and its neighbours. Work the gates in the order below (by likelihood) unless the
sign-in log already names one.

---

## A. The core failure: "Access Denied — you are not authorized to view this page"

| Failure reason (sign-in log) | Gate | Verify | Fix |
|---|---|---|---|
| "…not licensed for Intune" / no Intune service plan | Licensing (2A) | `ENRLDX-Get-UserIntuneLicense.ps1` | Assign an Intune-bearing license; wait for propagation; retry |
| MDM user scope excludes the user | MDM scope (2B) | `ENRLDX-Get-MdmUserScope.ps1` | Set scope **All**, or add the user to the scoped group |
| Platform/ownership blocked, or device limit hit | Restriction (2C) | `ENRLDX-Get-EnrollmentRestrictions.ps1` | Allow iOS/iPadOS + personal ownership; raise/clear the device limit |
| A CA policy blocks or gates the enrollment sign-in | Conditional Access (2D) | `ENRLDX-Get-EnrollmentCA.ps1` + the sign-in's CA tab | Exclude the enrollment apps/user; never disable the policy |
| Guest/B2B or disabled account | Account (2E) | `ENRLDX-Get-UserIntuneLicense.ps1` (UserType/Enabled) | Use a member account; re-enable sign-in; add required group |

> **The fast path:** read the failed sign-in first (`ENRLDX-Get-EnrollmentSignin.ps1`). The failure
> reason plus the Conditional Access result names the gate in one pass — don't guess.

---

## B. "Require compliant device" chicken-and-egg
- **Symptom:** enrollment blocked by CA requiring a compliant/hybrid-joined device — but the device can't
  be compliant until it's enrolled.
- **Verify:** `ENRLDX-Get-EnrollmentCA.ps1` shows a `compliantDevice`/`domainJoinedDevice` grant on a
  policy targeting the enrollment apps; the sign-in's CA tab shows that policy as the blocker.
- **Fix:** exclude the **Microsoft Intune Enrollment** (and where appropriate **Microsoft Intune**) app,
  or the enrolling user/group, from that policy. Keep the compliance requirement for post-enrollment
  resource access.

---

## C. Enrollment succeeds for some users but not others
- **Symptom:** same device model/OS; user A enrolls, user B gets "Access Denied."
- **Likely cause:** a **per-user** gate — license difference, MDM scope group membership, or a
  restriction/CA assignment targeting user B's group.
- **Verify:** run the license, MDM-scope and restriction scripts for **both** users and diff the results.
- **Fix:** align the failing user's license/scope/assignment with the working user's.

---

## D. ADE/corporate device: "Access Denied" during Setup Assistant
- **Symptom:** a Device Enrollment Program (ADE) device hits the failure mid-Setup-Assistant.
- **Likely cause:** license/scope/CA gate as above, **or** the serial isn't assigned to the Intune ADE
  token in ABM / no enrollment profile assigned.
- **Verify:** the four gate scripts, **plus** confirm in **ABM** the serial is under the Intune MDM
  server and in **Intune → Enrollment → Enrollment program tokens** the profile is assigned.
- **Fix:** remediate the gate; assign the device to the token and an enrollment profile; re-run Setup
  Assistant.

---

## E. Fixed the gate but the device still shows the screen
- **Symptom:** remediation applied, device still denied.
- **Likely cause:** propagation delay (license/scope), a **stale** enrollment attempt, or a **second**
  gate.
- **Verify:** re-run `ENRLDX-Get-EnrollmentSignin.ps1` for a **fresh** attempt — read the newest event,
  not the original. Check whether a different failure reason now appears (a second gate).
- **Fix:** wait for licensing/scope propagation (typically minutes), remove the management profile, retry;
  remediate any newly-revealed gate.

---

## F. Sovereign cloud (GCC High / DoD)
- **Symptom:** the runbook seems not to match the portal URLs.
- **Fix:** use `entra.microsoft.us` and `intune.microsoft.us`; run the scripts with `-Environment USGov`.
  The gates and remediation are identical.

---

## Escalation
Open a Microsoft support case only after: the sign-in log names no gate the scripts can confirm; a
confirmed remediation doesn't clear a fresh attempt; or a suspected service issue. Attach the failed and
post-fix sign-ins (with Activity/Session Ids), the gate-script output, and the change record.
