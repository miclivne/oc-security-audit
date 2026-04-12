# Profile: nextjs-prisma
# Standards: OWASP WSTG v4.2 + API Security Top 10 2023 + LLM Top 10 2025 + Top 10 2025
# Every WSTG test is accounted for: RUN (script) | RUN (llm) | SKIP | DEFER
# SKIP always includes a reason. DEFER means "Anthropic /security-review handles this."

## Stack assumptions
# Framework: Next.js (App Router) | ORM: Prisma | Auth: OAuth-only (no passwords)
# Input validation: Zod | React auto-escapes JSX by default

---

## WSTG-INFO: Information Gathering

| WSTG ID  | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| INFO-01  | Search engine recon           | RUN (script)    | curl robots.txt, sitemap.xml | Always relevant |
| INFO-02  | Web server fingerprint        | RUN (script)    | curl headers — check x-powered-by, server | Always relevant |
| INFO-03  | Identify technologies         | RUN (script)    | discover.sh | Already implemented |
| INFO-04  | Enumerate entry points        | RUN (script)    | discover.sh lists all routes | Already implemented |
| INFO-05  | Identify client-side code     | SKIP            | — | React/Next.js bundle is expected to be public |
| INFO-06  | Identify framework entry pts  | SKIP            | — | Covered by INFO-04 |
| INFO-07  | Map app execution paths       | DEFER           | Anthropic /security-review | Code-level control flow |
| INFO-08  | Framework fingerprint         | RUN (script)    | Check next.config poweredByHeader | Always relevant |
| INFO-09  | App framework specifics       | SKIP            | — | Covered by discover.sh |
| INFO-10  | Map app arch                  | SKIP            | — | Out of scope for automated scan |

---

## WSTG-CONF: Configuration Management

| WSTG ID  | Test                          | Decision          | Method | Reason |
|----------|-------------------------------|-------------------|--------|--------|
| CONF-01  | Network infrastructure        | RUN (script)      | Check hosting platform bypass domain | Platform-specific domains (Railway/Vercel/Fly) |
| CONF-02  | App platform config           | RUN (script)      | Check next.config: poweredByHeader, sourcemaps | Framework-specific config |
| CONF-03  | File extension handling       | RUN (script)      | curl .bak, .old, .tmp, .swp at production domain | Always relevant |
| CONF-04  | Backup/unreferenced files     | RUN (script)      | curl .env, .git/HEAD, package.json, .DS_Store, .npmrc | Always relevant |
| CONF-05  | Admin interfaces              | RUN (script)      | curl /admin, /dashboard, /_debug, /api/debug | Always relevant |
| CONF-06  | HTTP methods                  | RUN (script)      | curl OPTIONS, check TRACE disabled | Always relevant |
| CONF-07  | HSTS                          | RUN (script)      | Check Strict-Transport-Security header | Always relevant |
| CONF-08  | RIA cross-domain policy       | SKIP              | — | Flash/Silverlight — not applicable in 2025 |
| CONF-09  | File permissions              | RUN (script)      | Check Docker non-root USER, .env not in .next build | Always relevant |
| CONF-10  | Subdomain takeover            | RUN (script)      | dig CNAME on www and known subdomains | Check for dangling records |
| CONF-11  | Cloud storage                 | RUN (conditional) | Check S3/GCS bucket public access | Only if CLOUD_STORAGE detected |
| CONF-12  | CSP                           | RUN (script)      | Check content-security-policy header | Check unsafe-inline, unsafe-eval |
| CONF-13  | Path confusion                | SKIP              | — | Edge case, not applicable to Next.js App Router |
| CONF-14  | Other security headers        | RUN (script)      | Check x-frame-options, x-content-type-options, referrer-policy, permissions-policy | Always relevant |

---

## WSTG-IDNT: Identity Management

| WSTG ID  | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| IDNT-01  | Role definitions              | DEFER           | Anthropic /security-review | Code-level role logic |
| IDNT-02  | User registration             | SKIP            | — | OAuth-only — no registration form |
| IDNT-03  | Account provisioning          | SKIP            | — | OAuth-only — provider handles this |
| IDNT-04  | Account enumeration           | RUN (script)    | curl /api/auth endpoints | Check for user existence leakage |
| IDNT-05  | Username policy               | SKIP            | — | OAuth-only — no username |

---

## WSTG-ATHN: Authentication

| WSTG ID  | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| ATHN-01  | Credentials over encrypted channel | RUN (script) | Verify HTTPS-only, check HTTP redirect | Always relevant |
| ATHN-02  | Default credentials           | RUN (script)    | curl /admin, /wp-admin with common passwords | Always relevant |
| ATHN-03  | Account lockout               | SKIP            | — | OAuth-only — brute force handled by provider |
| ATHN-04  | Bypass authentication schema  | DEFER           | Anthropic /security-review | Logic-level bypass |
| ATHN-05  | Remember me                   | SKIP            | — | OAuth-only — provider handles persistence |
| ATHN-06  | Browser cache on auth pages   | RUN (script)    | Check Cache-Control headers | Always relevant |
| ATHN-07  | Password policy               | SKIP            | — | OAuth-only — no passwords |
| ATHN-08  | Security questions            | SKIP            | — | Not implemented |
| ATHN-09  | Password reset                | SKIP            | — | OAuth-only |
| ATHN-10  | Multi-channel auth (OTP)      | SKIP            | — | OAuth-only |

---

## WSTG-SESS: Session Management

| WSTG ID  | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| SESS-01  | Session management schema     | RUN (script)    | grep cookie config: httpOnly, secure, sameSite, maxAge | Always relevant |
| SESS-02  | Cookie attributes             | RUN (script)    | grep cookie settings; curl Set-Cookie from production | Always relevant |
| SESS-03  | Session fixation              | DEFER           | Anthropic /security-review | Code-level token rotation logic |
| SESS-04  | Exposed session variables     | RUN (script)    | grep for session tokens in URLs, logs, API responses | Always relevant |
| SESS-05  | CSRF                          | RUN (script)    | Check SameSite=Strict/Lax on session cookie | Always relevant |
| SESS-06  | Logout functionality          | DEFER           | Anthropic /security-review | Token invalidation logic |
| SESS-07  | Session timeout               | RUN (script)    | grep session maxAge/expiry config | Always relevant |
| SESS-08  | Session puzzling              | DEFER           | Anthropic /security-review | Multiple session tokens |

---

## WSTG-ATHZ: Authorization

| WSTG ID  | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| ATHZ-01  | Path traversal                | DEFER           | Anthropic /security-review | Code-level file path logic |
| ATHZ-02  | Bypass authorization schema   | RUN (script)    | Check auth on all routes; flag auth=no on mutations | Core skill check |
| ATHZ-03  | Privilege escalation          | RUN (llm)       | JUDGMENT-1: read mutation routes | Needs reasoning about role checks |
| ATHZ-04  | IDOR                          | RUN (llm)       | JUDGMENT-2: read routes with dynamic [params] | Needs reasoning about ownership |

---

## WSTG-INPV: Input Validation

| WSTG ID  | Test                          | Decision         | Method | Reason |
|----------|-------------------------------|------------------|--------|--------|
| INPV-01  | Reflected XSS                 | RUN (escape-hatch) | grep dangerouslySetInnerHTML | React auto-escapes; check escape hatch only |
| INPV-02  | Stored XSS                    | SKIP (framework) | Covered by INPV-01 escape hatch | React auto-escapes |
| INPV-03  | DOM XSS                       | RUN (escape-hatch) | grep innerHTML = | React VDOM; check escape hatch only |
| INPV-04  | Flash XSS                     | SKIP             | — | Flash not applicable |
| INPV-05  | SQL injection                 | RUN (escape-hatch) | grep $executeRawUnsafe, $queryRawUnsafe | Prisma parameterizes; check escape hatch only |
| INPV-06  | LDAP injection                | SKIP             | — | No LDAP |
| INPV-07  | XML injection                 | SKIP             | — | No XML parsing |
| INPV-08  | SSI injection                 | SKIP             | — | Not applicable to Next.js |
| INPV-09  | XPath injection               | SKIP             | — | No XPath |
| INPV-10  | IMAP/SMTP injection           | SKIP             | — | No mail server integration |
| INPV-11  | Code injection                | RUN (script)     | grep eval(, new Function( in src | Always relevant |
| INPV-12  | Command injection             | RUN (script)     | grep child_process, exec(, execSync(, spawn( | Always relevant |
| INPV-13  | Format string injection       | SKIP             | — | Not applicable to JavaScript |
| INPV-14  | Incubated vulnerability       | SKIP             | — | Addressed by INPV-01/02 |
| INPV-15  | HTTP splitting                | SKIP             | — | Next.js handles response headers |
| INPV-16  | HTTP request smuggling        | SKIP             | — | Handled by hosting platform |
| INPV-17  | HTTP host header injection    | RUN (script)     | curl with Host: evil.com header | Always relevant |
| INPV-18  | SSRF                          | RUN (script)     | grep fetch( with variable URLs in API routes | JUDGMENT-6 for confirmation |
| INPV-19  | Mass assignment               | SKIP (framework) | — | Zod validation strips extra fields |
| INPV-20  | Prototype pollution           | RUN (script)     | grep $PATTERN_PROTO in src | Always relevant |

---

## WSTG-ERRH: Error Handling

| WSTG ID  | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| ERRH-01  | Error codes                   | RUN (script)    | curl non-existent paths, check for stack traces | Always relevant |
| ERRH-02  | Stack traces                  | RUN (script)    | curl /api/nonexistent, check response body | Always relevant |

---

## WSTG-CRYP: Cryptography

| WSTG ID  | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| CRYP-01  | Weak TLS                      | RUN (script)    | curl --tlsv1.1 (advisory only) | Always relevant — see TLS note |
| CRYP-02  | Unencrypted channels          | RUN (script)    | curl http:// check redirect to https | Always relevant |
| CRYP-03  | Sensitive data in URL         | RUN (script)    | grep $PATTERN_SECRET_IN_URL in src | Always relevant |
| CRYP-04  | Weak hash algorithms          | DEFER           | Anthropic /security-review | Code-level crypto review |

---

## WSTG-BUSLOGIC: Business Logic

| WSTG ID  | Test                          | Decision          | Method | Reason |
|----------|-------------------------------|-------------------|--------|--------|
| BUSL-01  | Business logic data validation| RUN (llm)         | JUDGMENT-3: assess endpoint abuse potential | Needs reasoning |
| BUSL-02  | Ability to forge requests     | DEFER             | Anthropic /security-review | Code-level analysis |
| BUSL-03  | Integrity checks              | DEFER             | Anthropic /security-review | Code-level analysis |
| BUSL-04  | Process timing                | SKIP              | — | No time-sensitive flows detected |
| BUSL-05  | Workflow bypass               | RUN (llm)         | JUDGMENT-4: check multi-step flow enforcement | Needs reasoning |
| BUSL-06  | Defense against misuse        | RUN (llm)         | Assess rate limiting severity per route | Needs reasoning |
| BUSL-07  | Upload malicious files        | RUN (conditional) | JUDGMENT-5: check type validation + storage | Only if FILE_UPLOADS detected |
| BUSL-08  | Handling unexpected file types| RUN (conditional) | Same as BUSL-07 | Only if FILE_UPLOADS detected |

---

## WSTG-DOS: Denial of Service

| WSTG ID  | Test                          | Decision         | Method | Reason |
|----------|-------------------------------|------------------|--------|--------|
| DOS-01   | Anti-automation               | RUN (script)     | Check rate limiting on all routes from discovery | Core skill check |
| DOS-02   | Account lockout DoS           | SKIP             | — | OAuth-only — no password endpoint |
| DOS-03   | HTTP protocol DoS             | RUN (script)     | Check body size limits, timeout in next.config | Always relevant |
| DOS-04   | SQL wildcard DoS              | SKIP (framework) | — | Prisma parameterizes |

---

## WSTG-FILE: File Management

| WSTG ID  | Test                          | Decision          | Method | Reason |
|----------|-------------------------------|-------------------|--------|--------|
| FILE-01  | File upload types             | RUN (conditional) | JUDGMENT-5: check MIME type validation | Only if FILE_UPLOADS detected |
| FILE-02  | Malicious file upload         | RUN (conditional) | Check for path traversal in upload paths | Only if FILE_UPLOADS detected |
| FILE-03  | File inclusion                | DEFER             | Anthropic /security-review | Code-level analysis |

---

## OWASP API Security Top 10 (2023)

| API ID   | Test                               | Decision        | Method | Reason |
|----------|------------------------------------|-----------------|--------|--------|
| API1     | Broken object-level auth (IDOR)    | RUN (llm)       | Maps to ATHZ-04 / JUDGMENT-2 | Needs reasoning |
| API2     | Broken auth                        | RUN (script)    | Maps to ATHN-01, SESS-01/02 | Already covered |
| API3     | Broken object property-level auth  | RUN (llm)       | JUDGMENT-7: check public endpoint fields | Needs reasoning |
| API4     | Unrestricted resource consumption  | RUN (script)    | Rate limiting + body size + timeout (DOS-01/03) | Already covered |
| API5     | Broken function-level auth         | RUN (script)    | Auth check on all routes (ATHZ-02) | Already covered |
| API6     | SSRF                               | RUN (script)    | Maps to INPV-18 | Already covered |
| API7     | Security misconfiguration          | RUN (script)    | Maps to CONF-* | Already covered |
| API8     | Lack of automated threat protection| RUN (script)    | Maps to DOS-01 | Already covered |
| API9     | Improper inventory management      | RUN (script)    | discover.sh lists all routes | Already covered |
| API10    | Unsafe consumption of APIs         | RUN (llm)       | Check 3rd-party API response validation | Needs reasoning |

---

## OWASP LLM Top 10 (2025) — conditional: only if AI_SDK detected

| LLM ID   | Test                          | Decision        | Method | Reason |
|----------|-------------------------------|-----------------|--------|--------|
| LLM01    | Prompt injection              | RUN (llm)       | JUDGMENT-8: assess user input to AI calls | Needs reasoning |
| LLM02    | Insecure output handling      | DEFER           | Anthropic /security-review | Output rendering code |
| LLM03    | Training data poisoning       | SKIP            | — | Provider-hosted models |
| LLM04    | Model denial of service       | RUN (script)    | Check rate limiting on AI endpoints (DOS-01) | Already covered |
| LLM05    | Supply chain                  | RUN (script)    | npm audit covers AI SDK dependencies | Already covered |
| LLM06    | Excessive agency              | RUN (llm)       | Assess what actions AI integration can take | Needs reasoning |
| LLM07    | System prompt leakage         | RUN (llm)       | Check if system prompts exposed in client code | Needs reasoning |
| LLM08    | Vector/embedding weaknesses   | SKIP            | — | No RAG/vector store detected |
| LLM09    | Misinformation                | SKIP            | — | Not a security issue |
| LLM10    | Unbounded consumption         | RUN (script)    | Check rate limiting + cost controls on AI routes | Always relevant |

---

## Supply Chain

| WSTG ID    | Test                          | Decision        | Method | Reason |
|------------|-------------------------------|-----------------|--------|--------|
| SUPPLY-01  | npm audit                     | RUN (script)    | npm audit --omit=dev | Known CVEs in dependencies |
| SUPPLY-02  | Lockfile presence             | RUN (script)    | Check package-lock.json, yarn.lock, pnpm-lock.yaml | Non-reproducible builds without lockfile |

---

## DNS Security

| WSTG ID    | Test                          | Decision        | Method | Reason |
|------------|-------------------------------|-----------------|--------|--------|
| DNS-01     | SPF record                    | RUN (script)    | dig TXT $DOMAIN for SPF | Prevents email spoofing |
| DNS-02     | DMARC record                  | RUN (script)    | dig TXT _dmarc.$DOMAIN | Controls spoofed email handling |
| DNS-03     | DKIM record                   | RUN (script)    | dig TXT default._domainkey.$DOMAIN | Verifies email authenticity |

---

## External API Activity

| WSTG ID    | Test                          | Decision        | Method | Reason |
|------------|-------------------------------|-----------------|--------|--------|
| EXT-API    | External API key activity     | RUN (script)    | Check each var in $EXTERNAL_API_VARS against .env.production | Track active attack surface and data flows |

---

## Privacy / Legal

| WSTG ID    | Test                          | Decision        | Method | Reason |
|------------|-------------------------------|-----------------|--------|--------|
| PRIV-01    | Privacy page                  | RUN (script)    | find files with 'privacy' in name under src | GDPR, Google/Apple OAuth compliance |
| PRIV-02    | Account deletion              | RUN (script)    | grep $PATTERN_ACCOUNT_DELETION in src | Apple Sign In, GDPR right to erasure |

---

# WARNING: Decision column values (RUN/SKIP/DEFER) are parsed by scan.sh — do not change format

## Grep patterns (used by scan.sh — generic, not project-specific)
All patterns use ERE format (grep -E). Use | as OR operator, NOT \|.

### Secret patterns (hardcoded secrets)
PATTERN_SECRETS='sk-[a-zA-Z0-9]{20,}|sk_live_|sk_test_|pk_live_|AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36}|glpat-|xoxb-|xoxp-|AIza[0-9A-Za-z_-]{35}'

### Next.js public env with secret-like names
PATTERN_NEXT_PUBLIC_SECRETS='NEXT_PUBLIC_.*(SECRET|KEY|TOKEN|PASSWORD|PRIVATE)'

### Session configuration patterns
PATTERN_SESSION='httpOnly|secure|sameSite|maxAge|expires'
PATTERN_SESSION_IN_CLIENT='document\.cookie|sessionId.*body|body.*sessionId'

### Code injection escape hatches
PATTERN_EVAL='eval\(|new Function\('
PATTERN_CMD_INJECTION='child_process|exec\(|execSync\(|spawn\('
PATTERN_DANGEROUSLYHTML='dangerouslySetInnerHTML'
PATTERN_INNER_HTML='\.innerHTML\s*='

### ORM escape hatches (Prisma)
PATTERN_RAW_SQL='\$executeRawUnsafe|\$queryRawUnsafe'

### SSRF indicators
PATTERN_SSRF_FETCH='fetch\(.*\$\{|fetch\(.*\+|fetch\(.*req\.|fetch\(.*params\.|fetch\(.*body\.'

### Sensitive data in URLs
PATTERN_SECRET_IN_URL='[?&](token|key|secret|password|api_key|access_token)='

### Prototype pollution (single deduplicated pattern)
PATTERN_PROTO='__proto__|constructor\.prototype'

### Auth check patterns (for route analysis)
PATTERN_AUTH_CHECK='getSession|requireAuth|getServerSession|auth\(\)|withAuth|verifyAuth|checkAuth|session\.user'

### Rate limiting patterns
PATTERN_RATE_LIMIT='checkRateLimit|rateLimit|rateLimiter|rate_limit|Ratelimit'

### Logging & monitoring patterns
PATTERN_LOGGING_LIB='winston|pino|morgan|bunyan'
PATTERN_ERROR_LOG='console\.(error|warn)|logger\.(error|warn)'

### Account deletion patterns (privacy/legal)
PATTERN_ACCOUNT_DELETION='deleteAccount|removeAccount|closeAccount|deleteUser|deactivateAccount'

---

## External API key vars
EXTERNAL_API_VARS='ANTHROPIC_API_KEY OPENAI_API_KEY GOOGLE_PLACES_API_KEY GOOGLE_MAPS_API_KEY STRIPE_SECRET_KEY STRIPE_PUBLISHABLE_KEY SENDGRID_API_KEY TWILIO_AUTH_TOKEN'

---

## Node EOL versions
NODE_EOL_VERSIONS='v18 v16 v14 v12 v10'

---

## Logging & monitoring

| WSTG ID    | Test                          | Decision        | Method | Reason |
|------------|-------------------------------|-----------------|--------|--------|
| LOGG-01    | Logging library               | RUN (script)    | grep for $PATTERN_LOGGING_LIB in package.json | Absence means errors may not be captured |
| LOGG-02    | Error logging in API routes   | RUN (script)    | grep for $PATTERN_ERROR_LOG in src/app/api | Absence means errors are silent |

---

## LLM judgment calls

### JUDGMENT-1: Privilege escalation (ATHZ-03)
Read routes with data modification (POST, PATCH, PUT, DELETE where auth=yes).
Question: Can a low-privilege user trigger admin actions?
Files: Route files from discovery with mutation methods.
Flag if: Any route performs admin-level operations without checking user role.

### JUDGMENT-2: IDOR (ATHZ-04, API1)
Read routes with dynamic [param] segments (e.g., /api/[id]).
Question: Does each route verify the caller owns the resource?
Files: Route files with dynamic params from discovery.
Flag if: Mutation (PATCH/DELETE/POST) does NOT verify session.user.id === resource.userId. Note if public GET without ownership check is intentional (e.g., share link).

### JUDGMENT-3: Feature misuse (BUSL-01)
Read the 2-3 most sensitive business endpoints (subscription creation, data export, share link creation).
Question: Can this endpoint be abused for unintended financial/data impact?
Files: High-value route files from discovery.
Flag if: No server-side enforcement of business rules (quota, ownership, state machine).

### JUDGMENT-4: Workflow bypass (BUSL-05)
Read multi-step flows (e.g., checkout, onboarding, verification).
Question: Can a step be skipped by calling endpoints out of order?
Files: Route files that are part of sequential flows.
Flag if: Endpoint does not verify previous step was completed.

### JUDGMENT-5: Upload validation (FILE-01) — conditional: only if FILE_UPLOADS=yes
Read upload handler code.
Question: Does it validate file type and sanitize filename?
Files: Route files handling file uploads from discovery.
Flag if: No MIME type validation, no filename sanitization, or allows path traversal in upload path.

### JUDGMENT-6: SSRF (INPV-18)
Read routes flagged by $PATTERN_SSRF_FETCH scan (routes containing fetch with variable URLs).
Question: Is the URL user-controlled or fixed?
Files: Route files flagged by SSRF scan.
Flag if: URL is constructed from user input (req.body, req.query, params) without allowlist validation.

### JUDGMENT-7: Data exposure (API3)
Read public GET endpoints (auth=no, method includes GET) from discovery.
Question: Do responses include fields the caller shouldn't see (e.g., password hash, internal IDs, email on non-owner views)?
Files: Public GET route files from discovery.
Flag if: Response includes internal IDs not needed by frontend, email/phone on non-owner views, timestamps revealing usage patterns.

### JUDGMENT-8: Prompt injection (LLM01) — conditional: only if AI_SDK != none
Read AI routes (routes that import AI SDK).
Question: Can user input manipulate the system prompt?
Files: Route files containing AI SDK imports (generateText, streamText, generateObject).
Flag if: User input flows directly into system prompt without sanitization, or system prompt is constructed with string concatenation from user data.

---

## Stack-specific SKIP rationale

| Skipped check | Why safe for this stack |
|---------------|------------------------|
| SQL injection (INPV-05) | Prisma ORM parameterizes all queries by default. Escape hatch ($executeRawUnsafe) is still checked. |
| XSS reflected/stored (INPV-01/02) | React auto-escapes all JSX output. Escape hatch (dangerouslySetInnerHTML, innerHTML=) is still checked. |
| CSRF (SESS-05) | Next.js sets SameSite=Lax by default. Checked that cookie config doesn't override this. |
| Password attacks (ATHN-03/07/09) | OAuth-only authentication — no password input exists. |
| Mass assignment (INPV-19) | Zod schemas on all API inputs — extra fields are stripped or rejected. |
| Account lockout DoS (DOS-02) | No password endpoint to lock. |
| SQL wildcard DoS (DOS-04) | Prisma uses parameterized queries — no raw LIKE % patterns via user input. |
| Flash/Silverlight (CONF-08, INPV-04) | Not applicable in 2025. |
| Training data poisoning (LLM03) | We consume hosted model APIs — no training pipeline. |
| Vector/embedding weaknesses (LLM08) | No RAG/vector store in this stack. |
