# Executive Summary

**The problem.** A technically flawless migration of ~150,000 users from Microsoft 365 to Google
Workspace still fails if people don't change how they work. Users forward to old inboxes, save to
shadow file shares, meet in the wrong tool, and never touch Gemini. The migration is *delivered* but
its value — the license spend, the productivity case, the platform decision — is not *realized*.

**The outcome.** This solution is the **adoption, change-management, and training program** that turns
the cutover into measured behavior change: users trained by role, supported at go-live, and actively
using the new tools — with the usage data to prove it. It is the human side of the transformation,
run as a repeatable, wave-aligned program rather than a one-shot launch email.

**The approach.** Every migration wave runs the same OCM cycle — **awareness → training →
reinforcement** — carried locally by a **champion network** (respected peers, ~1 per 50–100 users)
and backed by a visible **executive sponsor**. Role-based learning paths deliver just-in-time skills
for Gmail, Drive, Docs, Meet, and Chat (and **Gemini where the cohort is licensed and features are
enabled**), with completion **gating go-live**. A staffed **hypercare/floorwalker** model absorbs the
first-days support surge, and **adoption metrics** — computed read-only from the Google Admin SDK
Reports API — show whether each cohort's usage is actually climbing, driving the next wave. The whole
cycle is proven **pilot-first** on a friendly Wave 0 before it scales.

**Why it is safe and governed.** The program follows the house model **Assess → Design → Configure →
Pilot → Validate → Expand** with explicit pass/fail gates (training delivered, hypercare staffed,
adoption trending up) and a documented **hold/rollback** for any wave that fails. Its five Python
tools are **read-only or dry-run by default**, authenticate via Application Default Credentials, and
contain **no hardcoded credentials or service-account keys** — the program measures adoption without
ever writing user data. Messaging tone, mandatory-training policy, and Gemini feature availability are
verified with the organization's HR/Comms and in-tenant Admin console rather than assumed.

**The bottom line.** A Google Workspace move that *sticks*: champions engaged, users trained by role,
hypercare staffed, and adoption measured and climbing — the human side of a 150k-user transformation,
done right, at a fraction of traditional consulting cost.
