# 1. Solution Overview — Dynamic Device Targeting in Intune

## Why dynamic targeting
Static security groups with hand-picked members do not scale. Every new device must be added by
hand, membership drifts as devices are retired or repurposed, and no one can easily prove which
devices a policy actually reaches. The result is missed policy on new devices, wasted admin hours,
and audit gaps. Dynamic targeting fixes this at the source: devices are targeted by rule, not by
name, so the right devices are included automatically and stay correct as the fleet changes.

## The two mechanisms

### Dynamic security groups (membership rules)
A dynamic security group in Microsoft Entra ID has a membership rule — a query over device
attributes — instead of a static member list. Entra continuously evaluates the rule and adds or
removes devices automatically. You assign policies and apps to the group; membership is maintained
for you. Rules are written in the membership-rule syntax and reference device properties such as
`deviceOSType`, `deviceOSVersion`, `deviceManufacturer`, `deviceModel`, `deviceCategory`,
`enrollmentProfileName`, and `deviceOwnership`.

Worked membership-rule examples:
- All Windows devices: `(device.deviceOSType -eq "Windows")`
- Corporate-owned Windows only: `(device.deviceOSType -eq "Windows") and (device.deviceOwnership -eq "Company")`
- Devices from a specific autopilot/enrollment profile: `(device.enrollmentProfileName -eq "Corp – Windows – Autopilot")`
- A device model family: `(device.deviceModel -startsWith "Surface")`
- Devices tagged to a category: `(device.deviceCategory -eq "Kiosk")`

### Assignment filters (filter rules, applied at assignment time)
An assignment filter is a reusable rule you attach to an individual policy or app assignment, set to
either include or exclude the matching devices. The group answers who is broadly in scope; the
filter narrows that single assignment to exactly the devices that match, without creating another
group. Filters are defined once under Intune and reused across many assignments. Filter rules use
the filter-rule syntax over managed-device properties such as `operatingSystem`, `osVersion`,
`deviceOwnership`, `model`, `manufacturer`, `enrollmentProfileName`, and `deviceCategory`.

Worked filter-rule examples:
- Only Windows 11 devices: `(device.osVersion -startsWith "10.0.2")`
- Personal (BYOD) devices, to exclude: `(device.deviceOwnership -eq "Personal")`
- A specific model, to include: `(device.model -eq "Surface Pro 9")`
- A specific enrollment profile: `(device.enrollmentProfileName -eq "Corp – Windows – Autopilot")`

## When to use each
- Use a dynamic security group when a population is broad, stable, and reused by many assignments
  (for example, all corporate Windows devices) — it becomes the durable audience.
- Use an assignment filter when you need to narrow or carve out a specific assignment (for example,
  send this one app only to a device model, or exclude BYOD from this one policy) without minting a
  new group for every variation.
- Rule of thumb: group for the broad audience, filter for the per-assignment exception. Fewer groups
  plus reusable filters is easier to maintain than a group for every combination.

## Precedence and evaluation
- Entra evaluates a group's membership rule and materializes the members; the group is the audience.
- At assignment time, Intune evaluates the attached filter against each in-scope device: an include
  filter keeps only matching devices; an exclude filter drops matching devices.
- Across assignments, Intune's assignment rules still apply: an exclude assignment beats an include
  assignment. A filter narrows within an assignment; a group exclusion removes an audience entirely.
- Effective targeting is therefore group membership, then filter include/exclude, then any
  include/exclude assignment precedence. Always validate the effective result, not the intent.

## The scalable targeting taxonomy
Name every dynamic group, filter, and taxonomy artifact with the pattern
`<Purpose> – <Scope> – <Stage>` and reuse the names verbatim wherever they appear. Examples used
throughout this solution:
- Dynamic group `Corp Devices – Windows – All`
- Dynamic group `Corp Devices – Windows – Pilot`
- Assignment filter `OS Version – Windows 11 – Include`
- Assignment filter `Ownership – Personal – Exclude`
- Assignment filter `Model – Surface – Include`

## Benefits
- Scale — new matching devices are included automatically; no hand-maintained lists.
- Accuracy — membership tracks the fleet, so policy reaches exactly the intended devices.
- Fewer objects — reusable filters replace a proliferation of near-duplicate groups.
- Auditability — a named taxonomy makes coverage and intent obvious for reviews.
- Speed — assign once, reuse the same groups and filters everywhere.

## Limitations (be honest with buyers)
- Dynamic device groups require Entra ID P1 licensing.
- Membership-rule evaluation is not instant; new devices take time to appear in a dynamic group.
- Attribute quality matters — rules are only as good as `deviceModel`, `deviceCategory`, ownership,
  and `enrollmentProfileName` being populated correctly.
- Overlapping filters and exclusions can produce non-obvious effective targeting; always validate.

## The standard Phoenixtekk deployment model
> Define the taxonomy -> build dynamic groups with membership rules -> create assignment filters ->
> apply filters to policy/app assignments -> validate effective targeting on a pilot -> expand.
> Phoenixtekk pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
