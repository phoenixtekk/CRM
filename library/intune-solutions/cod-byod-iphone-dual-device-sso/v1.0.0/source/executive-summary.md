# Executive Summary — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

A huge share of your people carry **two iPhones** — a **corporate iPhone (COD)** the company buys and
controls, and their **own personal iPhone (BYOD)** they also use for work. They expect the **same work
account to just sign in on both**, seamlessly. Handled badly, that means duplicate policies,
inconsistent security, two logins, and frustrated users.

This solution is built for exactly that **one-person-two-iPhones** scenario, under **Microsoft
Intune** and **one Microsoft Entra identity**: the user signs in with the same corporate account on
**both** their company iPhone and their personal iPhone, gets **single sign-on** across them, and IT
applies the **right level of control to each** based on who owns it.

- **Corporate iPhone (COD)** → supervised enrollment via **Apple Business Manager + Automated Device
  Enrollment (ADE)**, full MDM, device compliance, and configuration. IT owns the iPhone end to end.
- **Personal iPhone (BYOD)** → lighter-touch management: **App Protection (MAM)** that secures
  corporate data inside apps without taking over the employee's phone — or optional **Account-Driven
  Apple User Enrollment**.
- **One identity, both iPhones, single sign-on** → the user's single Entra account works on both
  iPhones; on iOS the **Microsoft Authenticator** broker plus the **iOS Enterprise SSO extension** give
  **silent SSO** so they sign in once per iPhone. **Ownership-based targeting** routes the correct
  policy to each iPhone automatically, and **Conditional Access** grants access from their compliant
  company iPhone *or* a protected app on their personal one.

Built the standard Phoenixtekk way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** one employee account that signs in seamlessly — with single sign-on — across both their
corporate and personal iPhone, corporate data protected on each, and access governed by compliance
and app protection — delivered by your own team without a consulting engagement.
