# Best Practices

## Diagnose from evidence, not symptoms
- Always start from the **failed sign-in** and its correlation IDs. The Activity Id / Session Id on the
  screen make this a deterministic lookup — treat trial-and-error re-enrollment as a last resort, not a
  first step.
- Require **two agreeing signals** before you act: the sign-in failure reason **and** the matching gate
  script. One without the other is a hypothesis, not a root cause.

## Change discipline
- Make **one scoped change** per identified gate, with an approved change record naming the gate.
- **Never disable a Conditional Access policy** to fix enrollment — exclude the enrollment apps or the
  user/group instead, so the policy keeps protecting everything else.
- Keep enrollment restrictions **deny-by-default**: allow exactly the platforms and ownership you intend,
  nothing broader.

## Design out the common causes
- **Licensing at the source:** assign Intune-bearing licenses via **group-based licensing** so new users
  in the enrollment group are licensed automatically.
- **MDM scope by group, not All-by-accident:** if you scope MDM to a group, make sure the enrollment
  onboarding process adds users to it. If you intend everyone to enroll, set scope to **All**.
- **Model the CA/enrollment interaction once:** maintain a documented exclusion pattern for the
  **Microsoft Intune Enrollment** app so every future CA change preserves enrollability.

## Prevent recurrence
- When the cause is a **class** problem (scope group, restriction assignment, CA pattern), fix it for the
  class, then re-test with a pilot user before closing.
- Keep a short **enrollment-readiness checklist** (licensed, in MDM scope, platform allowed, under device
  limit, not blocked by CA, member account) and run it before onboarding a new iOS fleet or user group.

## Evidence & handoff
- Store the before/after sign-ins, the gate-script output, and the change record with the ticket.
- Feed confirmed root causes back into the checklist so the next enrollment wave avoids the same wall.

## Sovereign clouds
- Use the `*.microsoft.us` portals and `-Environment USGov`; keep the same gate order and change
  discipline. Document the environment on the ticket so the correct portal is used every time.
