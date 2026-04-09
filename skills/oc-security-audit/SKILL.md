---
name: oc-security-audit
description: "Pre-launch security audit for web apps. Runs OWASP checks via shell scripts, then AI analyzes findings. Covers rate limiting, hosting bypass, data exposure, headers, session security, AI risks. Complements /security-review."
allowed-tools: Read, Grep, Glob, Bash(bash *discover.sh), Bash(bash *scan.sh)
---

You are running the OC Security Audit — a pre-launch security check for web applications.

Before each step, print a short status line so the user knows what's happening. Use this format:

**`[Step N/6]` Description — brief detail**

## Step 1: Discover

Print: **`[Step 1/6]` Detecting your stack — framework, ORM, auth, routes, domain...**

Run the discovery script:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/discover.sh
```

Extract from the output:
- `PROFILE`, `SRC_ROOT`, `PROJECT_ROOT`, `DOMAIN`, `HOSTING`, `FRAMEWORK`, `ORM`
- All `ROUTE:` lines (route inventory)
- All feature flags: `FILE_UPLOADS`, `AI_SDK`, `PAYMENTS`, `WEBSOCKETS` (format: `KEY: value`)

After discovery completes, print: **`[Step 1/6]` Done — detected {FRAMEWORK} + {ORM}, {ROUTE_COUNT} routes, domain: {DOMAIN}**

If `DOMAIN` is `unknown`, ask the user: "What is your production domain? (e.g. myapp.com)"
If `PROFILE` is `unsupported`, tell the user that only stack-independent checks will run.

## Step 2: Select tests

Print: **`[Step 2/6]` Selecting tests for {PROFILE} profile...**

Read `profiles/{PROFILE}.md` and count the decisions:
- Count rows with `RUN (script)` + `RUN (escape-hatch)` + `RUN (conditional)` → these will execute
- Count rows with `RUN (llm)` → these are LLM judgment calls
- Count rows with `SKIP` → not applicable to this stack
- Count rows with `DEFER` → need deeper code review

Print the selection summary:

**`[Step 2/6]` Profile has {TOTAL} OWASP test cases:**
- **{RUN_SCRIPT} test types selected** (automated script checks — some test multiple targets, e.g., rate limiting checks each route)
- **{RUN_LLM} judgment calls** (LLM reads code to assess)
- **{SKIP} skipped** (not applicable — e.g., OAuth-only means no password tests)
- **{DEFER} deferred** (need deeper code analysis — run `/security-review`)

## Step 3: Scan

Print: **`[Step 3/6]` Running {RUN_SCRIPT} security checks — headers, auth, rate limiting, secrets, DNS...**

Extract feature flags from discovery output, then run scan.sh with ALL values.

```bash
OC_FILE_UPLOADS=$(echo "$DISCOVERY" | grep "^FILE_UPLOADS:" | awk '{print $2}')
OC_AI_SDK=$(echo "$DISCOVERY" | grep "^AI_SDK:" | awk '{print $2}')
OC_PAYMENTS=$(echo "$DISCOVERY" | grep "^PAYMENTS:" | awk '{print $2}')
OC_WEBSOCKETS=$(echo "$DISCOVERY" | grep "^WEBSOCKETS:" | awk '{print $2}')
```

Then invoke (use `$HOME`, NOT `~` — tilde is not expanded in subshells):

```bash
OC_PROFILE={profile} OC_SRC_ROOT={src_root} OC_PROJECT_ROOT={project_root} OC_DOMAIN={domain} OC_HOSTING={hosting} OC_FRAMEWORK={framework} OC_ORM={orm} OC_FILE_UPLOADS=$OC_FILE_UPLOADS OC_AI_SDK=$OC_AI_SDK OC_PAYMENTS=$OC_PAYMENTS OC_WEBSOCKETS=$OC_WEBSOCKETS bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh
```

After scan completes, print: **`[Step 3/6]` Done — {TOTAL} individual checks run across {RUN_SCRIPT} test types ({PASS} pass, {WARN} warn, {FAIL} fail)**

## Step 4: Analyze

Print: **`[Step 4/6]` Reading code for judgment calls — IDOR, privilege escalation, data exposure...**

Read `profiles/{PROFILE}.md`, section `## LLM judgment calls`.
For each JUDGMENT-N: read ONLY the files listed, answer ONLY the questions asked. Do not explore broadly.

Do NOT print the judgment results here — they go into the report (PASS results in "What's secure", WARN results as issue blocks in "What needs attention"). Just print the step completion:

After analysis, print: **`[Step 4/6]` Done — {N} judgment calls completed**

## Step 5: Report

Print: **`[Step 5/6]` Writing the report...**

Read `templates/report.md` for the full report structure and instructions.
Key rules:
- Present report directly in conversation, NOT to a file
- Lead with the positive — "What's secure" comes first
- Group related findings into single issues (e.g., 9 rate limiting WARNs = 1 issue)
- Issues are grouped under their category — the user reads: category → issues → details
- Each issue uses the 7-section format from `templates/issue-format.md`
- "What could go wrong when fixing" is the most important section — must name a specific risk

## Step 6: Close

Print: **`[Step 6/6]` Wrapping up...**

1. Remind: "For deep code vulnerability analysis, also run `/security-review`."
2. Ask if the user wants the report saved to a file.
