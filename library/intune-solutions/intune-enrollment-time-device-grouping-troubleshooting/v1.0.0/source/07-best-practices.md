# Best Practices

Durable practices for Enrollment-Time Device Grouping that keep it working across tenants,
platforms, and staff turnover.

## Group design

- **One purpose per group.** Use a dedicated Assigned security group per platform and role
  (`Autopilot – Devices – Prod`, `iOS – Shared Devices – Prod`). Do not reuse a group that also
  drives licensing or unrelated assignments — enrollment-time membership should be unambiguous.
- **Get the create-only attributes right the first time.** **Membership type (Dynamic vs
  Assigned)**, **role-assignable**, and **directory-sync source** cannot be safely changed after
  creation. If any is wrong, make a new group — do not try to convert.
- **Start empty.** An empty target group makes it obvious that enrollment is what populated it, and
  keeps validation honest.
- **Never use a Dynamic group** for this purpose. It is the number-one misconfiguration and it is
  unsupported — Intune's enrollment-time write and Entra's rule engine cannot both own membership.

## The owner requirement

- **Match the service principal by AppId, always.** `f1346770-5b25-470b-88bd-d5744ab7952c` is
  constant; the display name (**Intune Provisioning Client** vs **Intune Autopilot
  ConfidentialClient**) is not. Documentation, runbooks, and scripts should key on the AppId.
- **Add the owner *before* wiring the policy, and wait for propagation.** Budget **5–10 minutes**
  after adding the owner before you Save. Saving too early is a self-inflicted "not an owner"
  failure.
- **Treat the owner as protected configuration.** Do not remove the Intune Provisioning Client from
  a group's owners as part of routine cleanup — it silently breaks future enrollment-time
  additions. Document its presence in your group's description.

## RBAC and delegation

- **Keep target groups inside operators' Intune RBAC scope.** With custom RBAC, a group outside
  scope produces a confusing "cannot find the security group" symptom. Add enrollment-time target
  groups to the relevant role-assignment scope groups deliberately.
- **Use least privilege for the tooling.** Run the read-only assessment/validation scripts with
  read scopes; grant `Group.ReadWrite.All` only for the brief window you use the add-owner tool.

## Change control and validation

- **Pilot first, always.** Validate the full chain (group → owner → Save → device joins at
  enrollment → assignments apply) on `…– Pilot` groups before touching `…– Prod`.
- **Prove it with a real enrollment**, not just a successful Save. A policy can save and still not
  populate devices if something upstream changes; T5–T7 in Testing catch that.
- **Keep a rollback ready.** Clearing the Device Group on a policy is a safe, instant rollback that
  never removes protection from already-enrolled devices.

## Cross-platform discipline

- **Apply the documented Windows requirement to Apple deliberately.** Microsoft documents this for
  Autopilot device preparation; Apple ADE uses the same backend but is sparsely documented.
  Because control names and availability can differ, **verify Apple labels and behavior in your
  tenant** and record what you find — do not assume the Apple UI matches the Windows docs
  verbatim.
- **Standardize the naming convention** (`<Purpose> – <Scope> – <Stage>`) across both platforms so
  the same runbook, tests, and scripts read cleanly for Windows and Apple.

## Noise discipline

- **Pre-brief your team on the Azure Activity Log red herring.** The `AuthorizationFailed` /
  `microsoft.insights/eventtypes/values/read` errors are Azure Monitor Reader-access noise
  surfaced by the portal — **not** the enrollment-grouping problem. Teaching this up front saves
  hours of misdirected troubleshooting.

## Documentation and evidence

- **Record the exact artifact names, the AppId owner, and the tenant-verified control paths** in
  your own runbook, since Apple labels and the newer Windows blades are version-dependent.
- **Save the output of `ETDG-Assess-GroupReadiness.ps1` / `ETDG-Test-EnrollmentGroupPrereqs.ps1`**
  as the "known-good" baseline so a future regression is a one-command diff.
