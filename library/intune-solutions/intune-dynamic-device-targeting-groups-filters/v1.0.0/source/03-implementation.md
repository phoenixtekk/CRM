# 3. Implementation Guide — Dynamic Device Targeting in Intune

Follow these steps in order. Group work is done in the Entra admin center
(`https://entra.microsoft.com`); filter and assignment work is done in the Microsoft Intune admin
center (`https://intune.microsoft.com`).

> Model: define a named targeting taxonomy, build dynamic security groups for the broad audiences,
> create reusable assignment filters for per-assignment narrowing, apply them, validate effective
> targeting on a pilot, then expand.

## Step 1 — Define the targeting taxonomy
1. Decide the broad audiences that many assignments will reuse (for example all corporate Windows
   devices) — these become dynamic groups.
2. Decide the per-assignment narrowings (for example OS version, model, ownership) — these become
   reusable filters.
3. Name every artifact with the pattern `<Purpose> – <Scope> – <Stage>` and record the names; reuse
   them verbatim everywhere. This solution uses: dynamic groups `Corp Devices – Windows – All` and
   `Corp Devices – Windows – Pilot`; filters `OS Version – Windows 11 – Include`,
   `Ownership – Personal – Exclude`, and `Model – Surface – Include`.

## Step 2 — Create the dynamic security groups
1. Entra -> `Groups -> New group`.
2. Group type `Security`; Group name `Corp Devices – Windows – Pilot`.
3. Membership type: select `Dynamic Device`.
4. Under `Dynamic device` click `Edit dynamic query`, switch to the rule syntax editor, and enter the
   membership rule. For the pilot, target a small set — for example devices from the pilot
   enrollment profile: `(device.enrollmentProfileName -eq "Corp – Windows – Pilot")`. `Save`.
5. `Create`.
6. Repeat for `Corp Devices – Windows – All` with the broad rule
   `(device.deviceOSType -eq "Windows") and (device.deviceOwnership -eq "Company")`. `Create`.
7. Wait for Entra to evaluate the rules, then confirm membership populated (see Step 6 / Testing).

## Step 3 — Create the assignment filters
1. Intune -> `Tenant administration -> Filters -> Create`.
2. Filter name `OS Version – Windows 11 – Include`; Platform `Windows 10 and later`. `Next`.
3. Build the rule in the rule editor (or the syntax box): `(device.osVersion -startsWith "10.0.2")`.
   `Next -> Create`.
4. Repeat to create `Ownership – Personal – Exclude` with rule
   `(device.deviceOwnership -eq "Personal")` and `Model – Surface – Include` with rule
   `(device.model -startsWith "Surface")`. Filters are direction-neutral here; include vs. exclude is
   chosen when the filter is attached to an assignment (Step 4).

## Step 4 — Apply filters to policy / app assignments
1. Open the policy or app to target (for example `Devices -> Configuration`, open a profile, or
   `Apps -> All apps`, open an app).
2. Go to the `Assignments` blade.
3. Under `Included groups`, add `Corp Devices – Windows – All`.
4. On that assignment row, click `Edit filter`, select the filter (for example
   `OS Version – Windows 11 – Include`), and set the mode to `Include` (only matching devices) or
   `Exclude` (all but matching devices). Use `Ownership – Personal – Exclude` in `Exclude` mode to
   carve BYOD out of a corporate assignment.
5. `Save` (or `Review + save`).

## Step 5 — Apply on the pilot
1. Assign the pilot policy/app to `Corp Devices – Windows – Pilot` with the intended filter.
2. On a pilot device, sync policy (`Settings -> Accounts -> Access work or school -> Info -> Sync`).
3. Confirm the assignment reached the device (Intune -> device -> the policy shows applied), or run
   `DYNTGT-Validation.ps1`.

## Step 6 — Validate effective targeting (pilot gate)
1. Run `DYNTGT-Validation.ps1` -> confirms a device's group membership and the filter include/exclude
   result for the assignment.
2. Run `DYNTGT-Report.ps1` -> targeting-coverage summary and any drift (devices in scope but missing
   the assignment, or matched by no group).
3. Confirm the effective targeting matches intent for the pilot before expanding. Complete the
   Testing Guide.

## Step 7 — Expand to production
1. Switch the assignment audience from `Corp Devices – Windows – Pilot` to
   `Corp Devices – Windows – All`, keeping the same filters.
2. Re-run `DYNTGT-Report.ps1` to confirm coverage and no drift across the fleet.
3. Reuse the same named groups and filters for the next policy/app — assign once, repeat everywhere.

---
### Order of operations
`Taxonomy -> Dynamic groups -> Filters -> Apply to assignments -> Apply on pilot -> Validate effective targeting -> Expand`
