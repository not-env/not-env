# not-env

not-env is a self-hosted replacement for .env files that provides centralized, encrypted environment variable management.

## Overview

not-env consists of five components:

1. **[not-env-backend](./not-env-backend)** - Go API server with SQLite/PostgreSQL/MySQL support and encryption
2. **[not-env-cli](./not-env-cli)** - CLI tool for managing environments and variables
3. **[not-env-frontend](./not-env-frontend)** - Web interface for managing environments and variables
4. **[not-env-sdk-js](./SDKs/not-env-sdk-js)** - JavaScript/TypeScript SDK (monkey-patches `process.env`)
5. **[not-env-sdk-python](./SDKs/not-env-sdk-python)** - Python SDK (monkey-patches `os.environ`)

> **Note:** This repository uses git submodules. See [SETUP.md](./SETUP.md) for cloning instructions.

## Prerequisites

- **Docker** installed and running
- **Node.js 18+** (for JS SDK) or **Python 3.8+** (for Python SDK)

## Quick Start (< 5 minutes)

### Step 1: Start not-env

```bash
# Generate and save your session secret (save this!)
openssl rand -hex 32
# Save the output from this and use it for your session secret

docker run -d --name not-env -p 1212:1212 -p 3000:3000 \
  -v not-env-data:/data \
  -e SESSION_SECRET=[your-session-secret] \
  ghcr.io/not-env/not-env-standalone:latest
```

Get your APP_ADMIN key (wait a few seconds after starting):
```bash
docker logs not-env | grep "APP_ADMIN key" | tail -1
```

**Important:** Save the master key for restarts:
```bash
docker logs not-env 2>&1 | grep -A 1 "NOT_ENV_MASTER_KEY was auto-generated" | tail -1 | tr -d ' '
```

### Step 2: Add Variables (Choose One)

**Option A: Web UI (Easiest)**
1. Open http://localhost:3000
2. Login with APP_ADMIN key from Step 1
3. Create an environment and import your .env file through the UI
4. Copy the ENV_READ_ONLY key for Step 3

**Option B: CLI**
```bash
# Install CLI
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
curl -L https://github.com/not-env/not-env-cli/releases/latest/download/not-env-${OS}-${ARCH} -o not-env && chmod +x not-env

# Login and import
./not-env login  # Enter http://localhost:1212 and APP_ADMIN key
./not-env env import --name dev --file .env  # Save ENV_READ_ONLY key for Step 3
```

### Step 3: Use in Your App

**JavaScript/TypeScript:**
```bash
npm install not-env-sdk
export NOT_ENV_URL="http://localhost:1212"
export NOT_ENV_API_KEY="<ENV_READ_ONLY-key>"
```
```javascript
// CRITICAL: Import at the very top, before any other imports
require('not-env-sdk');
console.log(process.env.DB_HOST);  // Works!
```

**Python:**
```bash
pip install not-env-sdk
export NOT_ENV_URL="http://localhost:1212"
export NOT_ENV_API_KEY="<ENV_READ_ONLY-key>"
```
```python
# CRITICAL: Import at the very top, before any other imports
import not_env_sdk.register
import os
print(os.environ['DB_HOST'])  # Works!
```

**That's it!** Your app now uses variables from not-env.

## Quick Troubleshooting

- **Backend not starting?** `docker ps` to check Docker is running
- **Can't get APP_ADMIN key?** Wait a few seconds, then `docker logs not-env | grep "APP_ADMIN key"`
- **Login fails?** Include `http://` in URL (e.g., `http://localhost:1212`)
- **SDK can't fetch variables?** Check `NOT_ENV_URL` and `NOT_ENV_API_KEY` are set
- **Variables not appearing?** SDK import must be at the very top of your file

## Available Docker Images

| Image | Description | Ports |
|-------|-------------|-------|
| `ghcr.io/not-env/not-env-standalone` | Backend + Frontend + SQLite (all-in-one) | 1212, 3000 |
| `ghcr.io/not-env/not-env` | Backend only (requires external database) | 1212 |
| `ghcr.io/not-env/not-env-frontend` | Frontend only | 3000 |

## Docker Examples

### Standalone with PostgreSQL

```bash
# Generate and save your session secret (save this!)
openssl rand -hex 32
# Save the output from this and use it for your session secret

docker run -d --name not-env -p 1212:1212 -p 3000:3000 \
  -e DB_TYPE=postgres \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=notenv \
  -e DB_PASSWORD=secret \
  -e DB_NAME=notenv \
  -e SESSION_SECRET=[your-session-secret] \
  ghcr.io/not-env/not-env-standalone:latest
```

### Backend Only (External Database)

```bash
docker run -d --name not-env-backend -p 1212:1212 \
  -e DB_TYPE=postgres \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=notenv \
  -e DB_PASSWORD=secret \
  -e DB_NAME=notenv \
  ghcr.io/not-env/not-env:latest
```

See [Backend README](./not-env-backend/README.md) for MySQL examples, horizontal scaling, and advanced configuration.

## Environment Variables

| Component | Variables | Required |
|-----------|-----------|----------|
| **Backend** | `DB_TYPE`, `DB_PATH` or `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME` | Yes |
| **Backend** | `NOT_ENV_MASTER_KEY` | Auto-generated; **required for restarts** |
| **SDKs** | `NOT_ENV_URL`, `NOT_ENV_API_KEY` | Yes |

See [Backend README](./not-env-backend/README.md#environment-variables) for complete reference.

## Components

- **[Backend](./not-env-backend/README.md)** - API server, database, encryption, production setup
- **[CLI](./not-env-cli/README.md)** - Command-line interface
- **[Frontend](./not-env-frontend/README.md)** - Web interface
- **[JavaScript SDK](./SDKs/not-env-sdk-js/README.md)** - Node.js integration
- **[Python SDK](./SDKs/not-env-sdk-python/README.md)** - Python integration

## Features

- Encrypted at rest (AES-256-GCM)
- Multi-database support (SQLite, PostgreSQL, MySQL)
- Three API key types: APP_ADMIN, ENV_ADMIN, ENV_READ_ONLY
- Shell integration (`eval "$(not-env env set)"`)
- Transparent SDK integration (monkey-patches `process.env` / `os.environ`)

## Common Issues

### Master key lost

**Problem:** Master key was not saved and container was removed.

**Consequence:** All encrypted data is unrecoverable.

**Prevention:**
- Save master key immediately after first startup
- For production: Set `NOT_ENV_MASTER_KEY` explicitly
- Store in secrets management system

### Frontend shows "Loading..." forever (401 on /api/auth/session)

**Problem:** SESSION_SECRET changed between container restarts, invalidating existing session cookies.

**Solution:** Use the same SESSION_SECRET on every startup. Generate once, save, and reuse:
```bash
# Generate and save your session secret (save this!)
openssl rand -hex 32
# Save the output from this and use it for your session secret
```

### SDK can't fetch variables

**Solutions:**
- Verify `NOT_ENV_URL` and `NOT_ENV_API_KEY` are set
- Check backend: `curl $NOT_ENV_URL/health`
- Ensure SDK import is at the very top of your file

### CLI authentication fails

**Solutions:**
- Include `http://` or `https://` in URL
- Copy entire API key (no extra spaces)
- Use `not-env use` to switch keys (keeps URL)

See component READMEs for detailed troubleshooting.

## Testing

```bash
# Run all tests
./test-all.sh

# With functional tests (requires Docker)
./test-all.sh --functional

# End-to-end integration
./test-integration.sh
```

See [TESTING.md](./TESTING.md) for details.

## License

MIT
