# Executive Summary — Dual-Device (Personal + Corporate) Management with Single Sign-On

A huge share of your people carry **two devices** — a **corporate-owned device (COD)** the company
buys and controls, and their **own personal device (BYOD)** they also use for work. They expect the
**same work account to just sign in on both**, seamlessly. Handled badly, that means duplicate
policies, inconsistent security, two logins, and frustrated users.

This solution is built for exactly that **one-person-two-devices** scenario, under **Microsoft
Intune** and **one Microsoft Entra identity**: the user signs in with the same corporate account on
**both** their company device and their personal device, gets **single sign-on** across them, and IT
applies the **right level of control to each** based on who owns it.

- **Corporate-owned (COD)** → full MDM enrollment, device compliance, and configuration. IT owns the
  device end to end.
- **Personal / BYOD** → lighter-touch management: **App Protection (MAM)** that secures corporate
  data inside apps without taking over the employee's device — or optional personal MDM enrollment.
- **One identity, both devices, single sign-on** → the user's single Entra account works on both of
  their devices; the Microsoft identity broker (WAM on the corporate device, Microsoft Authenticator
  on the personal device) gives **silent SSO** so they sign in once per device. **Ownership-based
  targeting** routes the correct policy to each device automatically, and **Conditional Access** grants
  access from their compliant company device *or* a protected app on their personal one.

Built the standard repeatable way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** one employee account that signs in seamlessly — with single sign-on — across both their
corporate and personal device, corporate data protected on each, and access governed by compliance
and app protection — delivered by your own team without a consulting engagement.
