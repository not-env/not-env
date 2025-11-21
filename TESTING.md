# Testing

This document describes the test suite for not-env.

## Quick Start

**Run all tests at once:**

```bash
./test-all.sh
```

This script automatically:
- Verifies all builds (backend, CLI, SDKs)
- Runs all unit tests
- Provides a summary of results

**Run with functional tests (requires Docker):**

```bash
./test-all.sh --functional
```

This includes end-to-end functional tests that verify:
- `env import` outputs both keys correctly
- Error messages show step-by-step instructions
- SDK integration works

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

## Test Status Summary

### ✅ Backend Tests - ALL PASSING

**Location:** `not-env-backend/`

**Test Files:**
- `internal/crypto/encryption_test.go` - Encryption/decryption tests
- `internal/api/middleware_test.go` - Authentication and permission middleware tests

**Coverage:**
- ✅ DEK generation and validation
- ✅ DEK encryption/decryption with master key
- ✅ Value encryption/decryption
- ✅ Crypto initialization and error handling
- ✅ Authentication middleware (missing headers, invalid formats)
- ✅ Permission checking (APP_ADMIN, ENV_ADMIN, ENV_READ_ONLY)
- ✅ Auth context extraction
- ✅ Error response formatting

**Run tests:**
```bash
cd not-env-backend
go test ./... -v
```

**Results:** All tests pass ✅

### ✅ CLI Tests - ALL PASSING

**Location:** `not-env-cli/`

**Test Files:**
- `internal/config/config_test.go` - Config management tests
- `internal/client/client_test.go` - HTTP client tests
- `internal/commands/env_test.go` - Command output format tests

**Coverage:**
- ✅ Config save/load functionality
- ✅ Config file error handling
- ✅ Config clear functionality
- ✅ HTTP client GET/POST requests
- ✅ HTTP client error parsing
- ✅ Shell export format (with escaping)
- ✅ Shell unset format

**Run tests:**
```bash
cd not-env-cli
go test ./... -v
```

**Results:** All tests pass ✅

### ⚠️ JavaScript SDK Tests - Logic Tests Available

**Location:** `SDKs/not-env-sdk-js/`

**Test Files:**
- `src/register.test.ts` - Core logic tests

**Coverage:**
- ✅ URL parsing logic
- ✅ JSON response parsing
- ✅ Proxy handler logic (preserved variables, has operator)
- ⚠️ Full integration tests require Node.js 18-20 (Jest compatibility issue with Node.js v25+)

**Run tests:**
```bash
cd SDKs/not-env-sdk-js
npm test
```

**Note:** SDK tests have a known issue with Node.js v25+ and Jest's localStorage initialization. The test logic is correct and tests pass on Node.js 18-20.

### ✅ Python SDK Tests - ALL PASSING

**Location:** `SDKs/not-env-sdk-python/`

**Test Files:**
- `tests/test_register.py` - Core SDK functionality tests

**Coverage:**
- ✅ URL parsing logic
- ✅ JSON response parsing
- ✅ os.environ patching behavior
- ✅ Preserved variables (NOT_ENV_URL, NOT_ENV_API_KEY)
- ✅ Hermetic behavior (KeyError for missing keys)
- ✅ Dict-like behavior (keys(), in operator, etc.)

**Run tests:**
```bash
cd SDKs/not-env-sdk-python
pytest
```

**Results:** All tests pass ✅

## Running Tests

### Backend
```bash
cd not-env-backend
go test ./... -v
```

**Coverage:** Crypto (encryption/decryption), middleware (auth/permissions)

### CLI
```bash
cd not-env-cli
go test ./... -v
```

**Coverage:** Config management, HTTP client, command output formatting

### JavaScript SDK
```bash
cd SDKs/not-env-sdk-js
npm test
```

**Note:** Requires Node.js 18-20 due to Jest compatibility with Node.js v25+.

**Coverage:** Proxy logic, URL/JSON parsing, preserved variables

### Python SDK
```bash
cd SDKs/not-env-sdk-python
pytest
```

**Coverage:** os.environ patching, dict-like behavior, preserved variables

## Integration Testing

### Automated Integration Tests

Two automated test scripts are available for comprehensive testing:

**Graceful Shutdown Test:**
```bash
./test-graceful-shutdown.sh
```

Tests that the backend properly handles SIGTERM and shuts down gracefully.

**End-to-End Integration Test:**
```bash
./test-integration.sh
```

Comprehensive test that verifies:
- Backend startup and health checks
- CLI authentication and commands
- Environment and variable management
- JavaScript SDK integration
- Python SDK integration
- CLI shell export functionality

### Manual Integration Testing

For manual end-to-end testing, start the backend and test each component:

```bash
# 1. Start backend
docker run -d --name not-env-backend -p 1212:1212 \
  -v not-env-data:/data \
  ghcr.io/not-env/not-env-standalone:latest

# 2. Get APP_ADMIN key from logs
docker logs not-env-backend | grep "APP_ADMIN key"

# 3. Test CLI
cd not-env-cli
go build -o not-env
./not-env login
./not-env env create --name test

# 4. Test JavaScript SDK
cd SDKs/not-env-sdk-js
export NOT_ENV_URL="http://localhost:1212"
export NOT_ENV_API_KEY="<env-read-only-key>"
node -e "require('not-env-sdk'); console.log(process.env)"

# 5. Test Python SDK
cd SDKs/not-env-sdk-python
export NOT_ENV_URL="http://localhost:1212"
export NOT_ENV_API_KEY="<env-read-only-key>"
python -c "import not_env_sdk.register; import os; print(os.environ)"
```

## Known Issues

- **JavaScript SDK**: Node.js v25+ has Jest compatibility issues. Use Node.js 18-20 for tests.
- **Integration Tests**: Require manual backend setup. Consider testcontainers for automation.
