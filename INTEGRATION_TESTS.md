# Integration Tests

This document describes the automated integration tests for not-env.

## Prerequisites

- Docker installed and running
- Go 1.21+ (for building CLI)
- Node.js 22+ (for JavaScript SDK tests)
- Python 3.8+ (for Python SDK tests)

## Test Scripts

### 1. Graceful Shutdown Test (`test-graceful-shutdown.sh`)

Tests that the backend properly handles SIGTERM signals and shuts down gracefully.

**What it tests:**
- Backend starts successfully
- Server responds to health checks
- SIGTERM signal triggers graceful shutdown
- Shutdown messages appear in logs
- Container exits cleanly (not killed)

**Run:**
```bash
./test-graceful-shutdown.sh
```

**Expected output:**
```
==========================================
Testing Graceful Shutdown
==========================================

Starting backend container...
Waiting for server to start...
✓ Server is running

Sending SIGTERM to container...

Checking shutdown logs...
✓ Graceful shutdown message found
✓ Server stopped message found
✓ Container exited gracefully (not killed)

==========================================
Graceful Shutdown Test: PASSED
==========================================
```

### 2. End-to-End Integration Test (`test-integration.sh`)

Comprehensive test that verifies the entire not-env workflow.

**What it tests:**
1. Backend startup and health checks
2. APP_ADMIN key retrieval from logs
3. CLI build and authentication
4. Environment creation via CLI
5. **.env file import** (creates environment and imports all variables)
6. Variable management via CLI (set/get) - both imported and manual
7. JavaScript SDK integration (fetches and uses variables)
8. Python SDK integration (fetches and uses variables)
9. CLI shell export functionality

**Run:**
```bash
./test-integration.sh
```

**Expected output:**
```
==========================================
not-env End-to-End Integration Test
==========================================

Step 1: Starting backend...
✓ Backend is ready

Step 2: Getting APP_ADMIN key...
✓ APP_ADMIN key retrieved

Step 3: Building CLI...
✓ CLI built

Step 4: Testing CLI login...
✓ CLI login successful

Step 5: Creating test environment...
✓ Environment created

Step 6: Testing .env import...
✓ .env file imported successfully

Step 7: Updating CLI to use ENV_ADMIN key from imported environment...
✓ CLI updated

Step 8: Verifying imported variables via CLI...
✓ Imported variables verified

Step 9: Testing manual variable setting (original environment)...
✓ Variables set manually

Step 10: Verifying manual variables via CLI...
✓ Manual variables verified

Step 11: Testing JavaScript SDK...
✓ JavaScript SDK test passed

Step 12: Testing Python SDK...
✓ Python SDK test passed

Step 13: Testing CLI env export...
✓ CLI env export works

==========================================
All Integration Tests: PASSED
==========================================
```

## Troubleshooting

### Docker not running
If you see "Cannot connect to the Docker daemon", start Docker Desktop or your Docker service.

### Port conflicts
The tests use ports 1213 and 1214. If these are in use, modify the scripts to use different ports.

### Backend fails to start
Check Docker logs:
```bash
docker logs not-env-test-shutdown  # for graceful shutdown test
docker logs not-env-test-integration  # for integration test
```

### SDK tests fail
Ensure:
- Node.js 22+ is installed for JavaScript SDK
- Python 3.8+ is installed for Python SDK
- SDKs are built (`npm install` for JS, `pip install -e .` for Python)

## Manual Testing

If automated tests fail or you want to test manually, see the [TESTING.md](./TESTING.md) manual integration testing section.

