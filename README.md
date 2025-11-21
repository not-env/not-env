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

## Quick Start (< 5 minutes)

Get not-env running in three simple steps:

### 1. Start Backend (~30 seconds)

```bash
docker run -d --name not-env -p 1212:1212 \
  -v not-env-data:/data \
  ghcr.io/not-env/not-env-standalone:latest
```

Get your APP_ADMIN key:
```bash
docker logs not-env | grep "APP_ADMIN key" | tail -1
```

### 2. Setup Environment (~2 minutes)

Install CLI (one command):
```bash
curl -L https://github.com/not-env/not-env-cli/releases/latest/download/not-env-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m) -o /usr/local/bin/not-env && chmod +x /usr/local/bin/not-env
```

Import your .env file (creates environment AND imports all variables):
```bash
# Login with APP_ADMIN key (from step 1)
not-env login
# Enter: http://localhost:1212
# Enter: <your-APP_ADMIN-key>

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
// Add at top of index.js
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
# Add at top of main.py
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

## Common Workflows

### Manual Variable Setting (Alternative to .env Import)

If you prefer to set variables manually instead of importing a .env file:

```bash
# After creating environment with 'not-env env create --name dev'
not-env login  # Use ENV_ADMIN key
not-env var set DB_HOST "localhost"
not-env var set DB_PORT "5432"
```

### Troubleshooting Quick Start

- **Backend not running?** Check with `docker ps` or `curl http://localhost:1212/health`
- **Login fails?** Verify APP_ADMIN key copied correctly (no extra spaces)
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

**Specifying APP_ADMIN key (for horizontal scaling):**

```bash
docker run -d \
  --name not-env-backend \
  -p 1212:1212 \
  -e NOT_ENV_APP_ADMIN_KEY="<your-app-admin-key>" \
  ghcr.io/not-env/not-env-standalone:latest
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

**Problem:** `not-env login` fails with 401 Unauthorized.

**Solutions:**
- Verify backend URL is correct (include `http://` or `https://`)
- Check that the API key is correct (copy entire key, no extra spaces)
- Ensure backend is running: `curl http://localhost:1212/health`

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

**Solutions:**
- If using SQLite standalone: Master key is stored in database, but you'll need to extract it
- For production: Always set `NOT_ENV_MASTER_KEY` explicitly in environment variables
- For horizontal scaling: Use `NOT_ENV_APP_ADMIN_KEY` to share admin access across instances

## Testing

See [TESTING.md](./TESTING.md) for unit test information and [INTEGRATION_TESTS.md](./INTEGRATION_TESTS.md) for automated integration tests.

**Quick test commands:**
```bash
# Unit tests
cd not-env-backend && go test ./... -v
cd not-env-cli && go test ./... -v
cd SDKs/not-env-sdk-js && npm test
cd SDKs/not-env-sdk-python && pytest

# Integration tests (requires Docker)
./test-graceful-shutdown.sh
./test-integration.sh
```

## Documentation

Each component includes comprehensive documentation:

- **README.md** - User-focused, example-driven guides
- **REQUIREMENTS.md** - Complete functional and non-functional requirements

See [SETUP.md](./SETUP.md) for information about working with git submodules.

## License

MIT

