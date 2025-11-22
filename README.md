# not-env

not-env is a self-hosted replacement for .env files that provides centralized, encrypted environment variable management.

## Overview

not-env consists of four components, each maintained as its own repository:

1. **[not-env-backend](./not-env-backend)** - Go HTTP(S) API server with SQLite/PostgreSQL/MySQL support, encryption, and horizontal scaling
2. **[not-env-cli](./not-env-cli)** - Go CLI tool for managing environments and variables
3. **[not-env-sdk-js](./SDKs/not-env-sdk-js)** - JavaScript/TypeScript SDK that monkey-patches process.env
4. **[not-env-sdk-python](./SDKs/not-env-sdk-python)** - Python SDK that monkey-patches os.environ

> **Note:** This repository uses git submodules. See [SETUP.md](./SETUP.md) for instructions on cloning and working with submodules.

## Environment Variables Quick Reference

| Component | Variables | Required |
|-----------|-----------|----------|
| **Backend** | `DB_TYPE` (sqlite/postgres/mysql), `DB_PATH` (SQLite) or `DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME` (PostgreSQL/MySQL) | Yes |
| **Backend** | `NOT_ENV_MASTER_KEY`, `NOT_ENV_APP_ADMIN_KEY` | No (auto-generated) |
| **CLI** | None | Uses config file (`~/.not-env/config`) |
| **SDKs** | `NOT_ENV_URL`, `NOT_ENV_API_KEY` | Yes |

**Full Configuration Reference:** See [Backend README](./not-env-backend/README.md#environment-variables) for complete environment variable documentation.

**Note:** For `env list` command, APP_ADMIN sees all environments, while ENV_ADMIN and ENV_READ_ONLY see only their own environment.

## Prerequisites

Before starting, ensure you have:

- **Docker** installed and running (for backend)
- **Linux/macOS/Windows** (WSL or Git Bash for Windows) for CLI
- **Node.js 22+** (for JavaScript SDK) or **Python 3.8+** (for Python SDK)

**Quick check:**
```bash
docker --version  # Should show Docker version
```

## Quick Start (< 5 minutes)

Get not-env running in three simple steps:

### 1. Start Backend (~30 seconds - 2 minutes on first run)

```bash
docker run -d --name not-env -p 1212:1212 \
  -v not-env-data:/data \
  ghcr.io/not-env/not-env-standalone:latest
```

**Note:** First run may take longer if Docker needs to pull the image (~1-2 minutes). Subsequent runs are faster.

Get your APP_ADMIN key:
```bash
docker logs not-env | grep "APP_ADMIN key" | tail -1
```

**Important:** Save the master key from logs (you'll need it to restart):
```bash
docker logs not-env 2>&1 | grep -A 1 "NOT_ENV_MASTER_KEY was auto-generated" | tail -1 | tr -d ' '
```

### 2. Setup Environment (~2 minutes)

Install CLI (one command):
```bash
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')
curl -L https://github.com/not-env/not-env-cli/releases/latest/download/not-env-${OS}-${ARCH} -o not-env && chmod +x not-env
```

Import your .env file (creates environment AND imports all variables):
```bash
# Login with APP_ADMIN key (from step 1)
not-env login
# Enter: http://localhost:1212
# Enter: <your-APP_ADMIN-key>

# Or use flags for non-interactive use:
# not-env login --url http://localhost:1212 --api-key <your-APP_ADMIN-key>

# Create a sample .env file (or use your existing one)
cat > .env <<EOF
DB_HOST=localhost
DB_PORT=5432
API_KEY=your-secret-key
EOF

# Import .env file (creates environment 'dev' and imports all variables)
not-env env import --name dev --file .env
# Save both keys from output! ENV_READ_ONLY is needed for Step 3.
```

**Note:** This single command creates the environment AND imports all variables from your .env file. No need to set variables manually!

### 3. Use in Your App (~30 seconds)

**Copy ENV_READ_ONLY key from Step 2 output, then:**

**JavaScript/TypeScript:**
```bash
npm install not-env-sdk
```
```javascript
// CRITICAL: Import SDK at the very top, before any other imports
require('not-env-sdk');
console.log(process.env.DB_HOST);  // Works!
```
```bash
export NOT_ENV_URL="http://localhost:1212"
export NOT_ENV_API_KEY="<ENV_READ_ONLY-key-from-step-2>"
node index.js
```

**Python:**
```bash
pip install not-env-sdk
```
```python
# CRITICAL: Import SDK at the very top, before any other imports
import not_env_sdk.register
import os
print(os.environ['DB_HOST'])  # Works!
```
```bash
export NOT_ENV_URL="http://localhost:1212"
export NOT_ENV_API_KEY="<ENV_READ_ONLY-key-from-step-2>"
python main.py
```

**That's it!** Your app now uses variables from not-env.

## Quick Troubleshooting

If something doesn't work:

- **Backend not starting?** Check Docker is running: `docker ps`
- **Can't get APP_ADMIN key?** Wait a few seconds after starting, then: `docker logs not-env | grep "APP_ADMIN key"`
- **Login fails?** Verify backend URL includes `http://` or `https://` (e.g., `http://localhost:1212`)
- **SDK can't fetch variables?** Check `NOT_ENV_URL` and `NOT_ENV_API_KEY` are set correctly
- **Variables not appearing?** Ensure SDK import is at the very top of your file (before other imports)

See [Common Issues](#common-issues) section below for detailed troubleshooting.

## What's Next?

Now that you have not-env running:

1. **Import your existing .env files**: Use `not-env env import` for each environment
2. **Set up your applications**: Add SDK imports to your code (see [SDK READMEs](./SDKs/))
3. **Manage variables**: Use `not-env var set/get/list` to manage variables
4. **Production setup**: See [Production Setup](#production-setup) for best practices

## Common Workflows

### Manual Variable Setting (Alternative to .env Import)

If you prefer to set variables manually instead of importing a .env file:

```bash
# After creating environment with 'not-env env create --name dev'
not-env use  # Switch to ENV_ADMIN key (faster than login)
not-env var set DB_HOST "localhost"
not-env var set DB_PORT "5432"
```

**Tip:** Use `not-env use` instead of `not-env login` when switching API keys - it keeps your backend URL and only prompts for the new API key.

### Troubleshooting Quick Start

- **Backend not running?** Check with `docker ps` or `curl http://localhost:1212/health`
- **Login fails?** Verify APP_ADMIN key copied correctly (no extra spaces)
- **Switching API keys?** Use `not-env use` instead of `not-env login` - it's faster and keeps your backend URL
- **SDK can't fetch variables?** Check `NOT_ENV_URL` and `NOT_ENV_API_KEY` are set correctly
- **Variables not appearing?** Ensure SDK import is at the very top of your file (before other imports)

## Detailed Examples

For more detailed examples including importing `.env` files, see:
- [Backend README](./not-env-backend/README.md) - Advanced configuration
- [CLI README](./not-env-cli/README.md) - Importing .env files
- [JavaScript SDK README](./SDKs/not-env-sdk-js/README.md) - Framework integration
- [Python SDK README](./SDKs/not-env-sdk-python/README.md) - Framework integration

## Docker Usage Examples

### Running Published Images

**Standalone SQLite backend:**

```bash
docker run -d \
  --name not-env-backend \
  -p 1212:1212 \
  -v not-env-data:/data \
  ghcr.io/not-env/not-env-standalone:latest
```

**Minimal backend (connect to external database):**

```bash
docker run -d \
  --name not-env-backend \
  -p 1212:1212 \
  -e DB_TYPE=postgres \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=notenv \
  -e DB_PASSWORD=secret \
  -e DB_NAME=notenv \
  ghcr.io/not-env/not-env:latest
```

**For horizontal scaling (multiple instances):**

All instances must share the same master key and APP_ADMIN key:

```bash
docker run -d --name not-env-backend-1 -p 1212:1212 \
  -e DB_TYPE=postgres \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=notenv \
  -e DB_PASSWORD=secret \
  -e DB_NAME=notenv \
  -e NOT_ENV_MASTER_KEY="<shared-master-key>" \
  -e NOT_ENV_APP_ADMIN_KEY="<shared-app-admin-key>" \
  ghcr.io/not-env/not-env:latest

# Instance 2 (same keys, different port)
docker run -d --name not-env-backend-2 -p 1213:1212 \
  -e DB_TYPE=postgres \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=notenv \
  -e DB_PASSWORD=secret \
  -e DB_NAME=notenv \
  -e NOT_ENV_MASTER_KEY="<shared-master-key>" \
  -e NOT_ENV_APP_ADMIN_KEY="<shared-app-admin-key>" \
  ghcr.io/not-env/not-env:latest
```

### Building from Source

**Build standalone image:**

```bash
docker build -f Dockerfile.sqlite -t not-env-standalone:local .
```

**Build minimal image:**

```bash
docker build -f Dockerfile -t not-env:local .
```

### Multi-Architecture Builds

**Using docker buildx:**

```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 \
  -f Dockerfile.sqlite \
  -t ghcr.io/not-env/not-env-standalone:latest \
  --push .
```

## Production Setup

For production deployments, follow these best practices:

### 1. Set Master Key Explicitly

Never rely on auto-generation in production. Set `NOT_ENV_MASTER_KEY` explicitly:

```bash
# Generate a secure master key
openssl rand -base64 32

# Use it when starting container
docker run -d --name not-env-backend -p 1212:1212 \
  -e DB_TYPE=postgres \
  -e DB_HOST=postgres.example.com \
  -e DB_PORT=5432 \
  -e DB_USER=notenv \
  -e DB_PASSWORD=secret \
  -e DB_NAME=notenv \
  -e NOT_ENV_MASTER_KEY="<generated-key>" \
  -e NOT_ENV_APP_ADMIN_KEY="<your-app-admin-key>" \
  ghcr.io/not-env/not-env:latest
```

### 2. Use External Database

Use PostgreSQL or MySQL for production (not SQLite):

- Better performance and reliability
- Supports horizontal scaling
- Easier backup and recovery
- Better concurrent access handling

### 3. Use Secrets Management

Store sensitive keys securely:

- **Docker:** Use Docker secrets or environment files
- **Kubernetes:** Use Kubernetes secrets
- **Cloud:** Use cloud provider secrets management (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)
- **Never commit keys to version control**

### 4. Enable HTTPS

Use a reverse proxy (nginx, Traefik, Caddy) or TLS termination:

```bash
# Example with nginx reverse proxy
# Backend runs on localhost:1212
# nginx handles HTTPS and forwards to backend
```

### 5. Backup Strategy

- **Database backups:** Regular automated backups of PostgreSQL/MySQL database
- **Master key backup:** Store master key separately in secure location (secrets management)
- **Test restores:** Regularly test backup restoration procedures

### 6. Monitoring

- Monitor backend health: `curl https://not-env.example.com/health`
- Set up alerts for container failures
- Monitor database connection health
- Track API usage and errors

See [Backend README](./not-env-backend/README.md) for detailed production configuration.

## CI/CD Integration Examples

Replace your platform's secrets management with not-env:

### GitHub Actions

```yaml
name: Deploy
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
      - name: Install dependencies
        run: npm install
      - name: Deploy
        env:
          NOT_ENV_URL: ${{ secrets.NOT_ENV_URL }}
          NOT_ENV_API_KEY: ${{ secrets.NOT_ENV_API_KEY }}
        run: npm run deploy
```

### GitLab CI/CD

```yaml
deploy:
  script:
    - npm install
    - npm run deploy
  variables:
    NOT_ENV_URL: $NOT_ENV_URL
    NOT_ENV_API_KEY: $NOT_ENV_API_KEY
```

### Vercel

Add environment variables in Vercel dashboard:
- `NOT_ENV_URL`: Your backend URL
- `NOT_ENV_API_KEY`: Your ENV_READ_ONLY key

Then import the SDK in your code:

```javascript
require('not-env-sdk');
```

### Netlify

Add environment variables in Netlify dashboard:
- `NOT_ENV_URL`: Your backend URL
- `NOT_ENV_API_KEY`: Your ENV_READ_ONLY key

Then import the SDK in your code:

```javascript
require('not-env-sdk');
```

### AWS Lambda

Set environment variables in Lambda configuration:
- `NOT_ENV_URL`: Your backend URL
- `NOT_ENV_API_KEY`: Your ENV_READ_ONLY key

Then import the SDK in your Lambda function:

```javascript
require('not-env-sdk');

exports.handler = async (event) => {
  const apiKey = process.env.API_KEY; // from not-env
  // ...
};
```

## Components

- **[Backend](./not-env-backend/README.md)** - API server, database, encryption
- **[CLI](./not-env-cli/README.md)** - Command-line interface for management
- **[JavaScript SDK](./SDKs/not-env-sdk-js/README.md)** - JavaScript/TypeScript integration
- **[Python SDK](./SDKs/not-env-sdk-python/README.md)** - Python integration

## Features

- ✅ Encrypted at rest (AES-256-GCM)
- ✅ Multi-database support (SQLite, PostgreSQL, MySQL/MariaDB)
- ✅ Three API key types: APP_ADMIN (organization management), ENV_ADMIN (variable management), ENV_READ_ONLY (read-only access)
- ✅ Environment-based organization
- ✅ Shell integration (`eval "$(not-env env set)"`)
- ✅ Transparent Node.js integration (monkey-patches `process.env`)
- ✅ Transparent Python integration (monkey-patches `os.environ`)

## Common Issues

### Backend won't start

**Problem:** Backend container exits immediately or fails to start.

**Solutions:**
- Check logs: `docker logs not-env-backend`
- Verify database connection variables are set correctly
- For SQLite: Ensure volume mount path is writable
- For PostgreSQL/MySQL: Verify database is accessible and credentials are correct

### CLI authentication fails

**Problem:** `not-env login` or `not-env use` fails with 401 Unauthorized.

**Solutions:**
- Verify backend URL is correct (include `http://` or `https://`)
- Check that the API key is correct (copy entire key, no extra spaces)
- Ensure backend is running: `curl http://localhost:1212/health`
- Use `not-env use` to switch API keys (keeps backend URL, only prompts for API key)
- Use `not-env login` when changing backend URL or logging in for the first time

### SDK can't fetch variables

**Problem:** Application fails to start with SDK import error.

**Solutions:**
- Verify `NOT_ENV_URL` and `NOT_ENV_API_KEY` are set in environment
- Check backend is accessible: `curl $NOT_ENV_URL/health`
- Verify API key has correct permissions (ENV_READ_ONLY or ENV_ADMIN)
- Check network connectivity (firewall, VPN, etc.)

### Variables not appearing in application

**Problem:** `process.env` or `os.environ` doesn't show variables from not-env.

**Solutions:**
- Ensure SDK is imported at the very top of your entry file (before any other imports)
- Verify variables exist in the environment: `not-env var list --env <env-name>`
- Check you're using the correct environment name
- Verify API key has access to the environment

### Master key lost

**Problem:** Backend master key was not saved and container was removed.

**Consequences:**
- **All encrypted data becomes unrecoverable** - The master key is required to decrypt organization DEKs, which are required to decrypt variable values
- You must recreate all environments and variables from scratch
- If you have database backups but lost the master key, the backups are also unusable

**Solutions:**
- **If using SQLite standalone:** The master key is NOT stored in the database. Always save the master key from first startup logs. If lost, you must recreate everything.
- **For production:** Always set `NOT_ENV_MASTER_KEY` explicitly in environment variables or secrets management (never rely on auto-generation).
- **For horizontal scaling:** All instances must use the same `NOT_ENV_MASTER_KEY` and `NOT_ENV_APP_ADMIN_KEY`.
- **Recovery:** If master key is lost, you must restore from a backup that includes the master key, or recreate all environments and variables.

**Prevention:**
- Save master key immediately after first startup
- Store in secure secrets management system
- Include master key in your backup strategy (store separately from database backups)

## Testing

See [TESTING.md](./TESTING.md) for detailed test information and [INTEGRATION_TESTS.md](./INTEGRATION_TESTS.md) for automated integration tests.

### Quick Test Commands

**Run all automated tests:**
```bash
# Comprehensive test suite (builds + unit tests)
./test-all.sh

# With functional tests (requires Docker)
./test-all.sh --functional

# End-to-end integration test (requires Docker)
./test-integration.sh

# Graceful shutdown test (requires Docker)
./test-graceful-shutdown.sh
```

**Run all tests at once:**
```bash
./test-all.sh && ./test-integration.sh && ./test-graceful-shutdown.sh
```

**Run tests individually:**
```bash
# Backend
cd not-env-backend && go test ./... -v

# CLI
cd not-env-cli && go test ./... -v

# JavaScript SDK
cd SDKs/not-env-sdk-js && npm test

# Python SDK
cd SDKs/not-env-sdk-python && pytest
```

### Full Test Verification

To fully verify everything works:

1. **Run automated test suite:**
   ```bash
   ./test-all.sh
   ```
   This verifies all builds and unit tests pass.

2. **Run integration tests:**
   ```bash
   ./test-integration.sh
   ```
   This verifies the complete workflow: backend startup, CLI commands, SDK integration.

3. **Run graceful shutdown test:**
   ```bash
   ./test-graceful-shutdown.sh
   ```
   This verifies the backend handles shutdown signals correctly.

4. **Follow Quick Start from scratch:**
   - Start backend (Step 1)
   - Import .env file (Step 2)
   - Use SDKs (Step 3)
   - Verify all steps work as documented

**Expected duration:** ~30-60 seconds for all automated tests.

See [TESTING.md](./TESTING.md) and [INTEGRATION_TESTS.md](./INTEGRATION_TESTS.md) for detailed test documentation.

## Documentation

Each component includes comprehensive documentation:

- **README.md** - User-focused, example-driven guides
- **REQUIREMENTS.md** - Complete functional and non-functional requirements

See [SETUP.md](./SETUP.md) for information about working with git submodules.

## License

MIT

