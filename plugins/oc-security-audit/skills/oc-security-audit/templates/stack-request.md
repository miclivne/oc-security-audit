---
name: Stack Support Request
about: Request support for a tech stack not currently covered
title: "Stack request: [framework] + [ORM/DB]"
labels: enhancement, stack-request
---

## Detected Stack

**Framework:**
**ORM/Database:**
**Auth:**
**Language:**
**Hosting:**

## What happened

The OC Security Audit skill detected my stack but does not have a full profile for it. It ran stack-independent checks only (rate limiting, hosting bypass, secrets, headers, DNS, supply chain) but skipped stack-specific checks (code escape hatches, API auth coverage, IDOR verification, AI data flow, SSRF patterns).

## What I'd like

Full profile support for this stack, including:
- [ ] Framework-specific escape hatch checks
- [ ] API route discovery patterns
- [ ] Auth middleware detection
- [ ] ORM-specific raw query patterns
