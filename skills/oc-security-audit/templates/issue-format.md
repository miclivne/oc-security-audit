# Issue Block Template

For each finding marked WARN or FAIL, write this block:

```markdown
### {severity_emoji} Issue {N}: {short descriptive title} [{ACTION}]

Where severity_emoji is: 🔴 = FIX, 🟡 = INVESTIGATE, 🟢 = MONITOR/ACCEPT

**WSTG Reference:** {WSTG-ID or API-ID or LLM-ID} — {test name}

**Threat:** {one or more: DDoS | Data Breach | Account Takeover | Code Execution | Privacy Violation | Financial Loss}

**What's wrong:** {specific finding with evidence — include file path, curl output, or code snippet. Be concrete, not vague.}

**What could happen:** {real-world attack scenario in plain language. Describe the ACTUAL attack, not a theoretical risk.
  GOOD: "An attacker could send 1,000 requests to your autocomplete endpoint and cost you $50 in Google Places API fees."
  BAD: "Missing rate limiting could lead to abuse."}

**What could go wrong when fixing this:**
- {Could the fix break existing functionality? Be specific.}
- {Could it affect user experience? How?}
- {What should be tested after implementing the fix?}

**How others solve this:** {How do established platforms handle this? If the industry standard is to accept the behavior, say so. Cite specific examples when possible.}

**Recommended action:** {FIX | ACCEPT | MONITOR | INVESTIGATE} — {one sentence explaining why}
```

## Guidelines

- PASS items get ONE row in the findings table — no issue block needed
- Only write issue blocks for WARN and FAIL findings
- All 7 sections above are REQUIRED — never omit any
- "What could go wrong when fixing" is MANDATORY — never skip it. This is our differentiator. A fix that breaks the app is worse than the vulnerability.
- "How others solve this" should reference real platforms, not hypothetical best practices
- Be honest about ACCEPT — some findings are better accepted than fixed. Say so.
