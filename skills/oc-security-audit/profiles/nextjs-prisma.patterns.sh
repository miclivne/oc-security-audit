#!/bin/sh
# Auto-synced from nextjs-prisma.md — update both files when patterns change
# All patterns use ERE format (grep -E). Use | as OR operator, NOT \|.

# Secret patterns (hardcoded secrets)
PATTERN_SECRETS='sk-[a-zA-Z0-9]{20,}|sk_live_|sk_test_|pk_live_|AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36}|glpat-|xoxb-|xoxp-|AIza[0-9A-Za-z_-]{35}'

# Next.js public env with secret-like names
PATTERN_NEXT_PUBLIC_SECRETS='NEXT_PUBLIC_.*(SECRET|KEY|TOKEN|PASSWORD|PRIVATE)'

# Session configuration patterns
PATTERN_SESSION='httpOnly|secure|sameSite|maxAge|expires'
PATTERN_SESSION_IN_CLIENT='document\.cookie|sessionId.*body|body.*sessionId'

# Code injection escape hatches
PATTERN_EVAL='eval\(|new Function\('
PATTERN_CMD_INJECTION='child_process|exec\(|execSync\(|spawn\('
PATTERN_DANGEROUSLYHTML='dangerouslySetInnerHTML'
PATTERN_INNER_HTML='\.innerHTML\s*='

# ORM escape hatches (Prisma)
PATTERN_RAW_SQL='\$executeRawUnsafe|\$queryRawUnsafe'

# SSRF indicators
PATTERN_SSRF_FETCH='fetch\(.*\$\{|fetch\(.*\+|fetch\(.*req\.|fetch\(.*params\.|fetch\(.*body\.'

# Sensitive data in URLs
PATTERN_SECRET_IN_URL='[?&](token|key|secret|password|api_key|access_token)='

# Prototype pollution (single deduplicated pattern)
PATTERN_PROTO='__proto__|constructor\.prototype'

# Auth check patterns (for route analysis)
PATTERN_AUTH_CHECK='getSession|requireAuth|getServerSession|auth\(\)|withAuth|verifyAuth|checkAuth|session\.user'

# Rate limiting patterns
PATTERN_RATE_LIMIT='checkRateLimit|rateLimit|rateLimiter|rate_limit|Ratelimit'

# Logging & monitoring patterns
PATTERN_LOGGING_LIB='winston|pino|morgan|bunyan'
PATTERN_ERROR_LOG='console\.(error|warn)|logger\.(error|warn)'

# Account deletion patterns (privacy/legal)
PATTERN_ACCOUNT_DELETION='deleteAccount|removeAccount|closeAccount|deleteUser|deactivateAccount'

# External API key vars (space-separated list)
EXTERNAL_API_VARS='ANTHROPIC_API_KEY OPENAI_API_KEY GOOGLE_PLACES_API_KEY GOOGLE_MAPS_API_KEY STRIPE_SECRET_KEY STRIPE_PUBLISHABLE_KEY SENDGRID_API_KEY TWILIO_AUTH_TOKEN'

# Node EOL versions (space-separated major version prefixes)
NODE_EOL_VERSIONS='v18 v16 v14 v12 v10'
