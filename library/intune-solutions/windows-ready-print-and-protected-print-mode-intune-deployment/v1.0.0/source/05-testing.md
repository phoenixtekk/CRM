# Testing & Validation

Validation is objective: WPP is enabled where intended, printing works through Windows Ready Print, and
nothing was removed that wasn't in the plan.

## Test 1 — Baseline inventory captured (pre-deployment)
1. Run **`WPPRINT-Get-PrintDriverInventory.ps1`** and **`WPPRINT-Test-MopriaReadiness.ps1`** on the pilot
   devices before assignment.
2. **Pass criteria:** you have a per-device list of printers/drivers and a Ready-Print eligibility
   classification — the "before" picture WPP will change.

## Test 2 — OS eligibility confirmed
1. Run **`WPPRINT-Get-WPPState.ps1`**.
2. **Pass criteria:** every targeted device reports **Windows 11 24H2+**; ineligible devices are excluded
   by the assignment filter.

## Test 3 — Profile applied, WPP enabled
1. After the pilot syncs, run **`WPPRINT-Get-WPPState.ps1`** (or `WPPRINT-Validate-Deployment.ps1`).
2. **Pass criteria:** `WindowsProtectedPrintGroupPolicyState` is set under
   `HKLM\Software\Policies\Microsoft\Windows NT\Printers\WPP`; state = **enabled**; Intune shows the
   profile **Succeeded**.

## Test 4 — Printing works via the IPP class driver
1. On a pilot device, print a test page to a Mopria/IPP printer.
2. **Pass criteria:** the job prints, and the printer is using the **Microsoft IPP Class Driver** (not a
   vendor V3/V4 driver). `WPPRINT-Validate-Deployment.ps1` confirms.

## Test 5 — Removals match the plan
1. Compare the Phase-1 inventory to the post-deployment state.
2. **Pass criteria:** the printers/drivers removed are exactly those the assessment flagged as
   third-party — **no unplanned removals**. Any Mopria printer reinstalls via Windows Ready Print.

## Test 6 — Third-party Point and Print is blocked
1. Attempt to install a printer that would pull a **third-party driver** via Point and Print.
2. **Pass criteria:** the third-party driver install is **blocked** — confirming the WPP hardening.

## Test 7 — Scanning validated (multifunction devices)
1. On an MFD in scope, perform a scan.
2. **Pass criteria:** scanning works via **Mopria/eSCL**, or the device is correctly identified as a
   scan **exception** and kept out of WPP scope until remediated.

## Test 8 — No collateral impact
1. Confirm eligible non-pilot devices are unaffected, and exception devices retained their required
   (non-Mopria) printers because they were excluded from scope.
2. **Pass criteria:** only the intended ring changed; exceptions behave as before.

## Evidence to keep
- The pre/post inventory diff (what WPP removed vs. the plan).
- The WPP-enabled state and a successful IPP-class-driver print.
- The scan validation and the exception list.
