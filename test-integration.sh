#!/bin/bash
# Comprehensive end-to-end integration test for not-env

set -e

echo "=========================================="
echo "not-env End-to-End Integration Test"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_PORT=1214
BACKEND_URL="http://localhost:${BACKEND_PORT}"
CONTAINER_NAME="not-env-test-integration"

# Cleanup function
cleanup() {
  echo ""
  echo "Cleaning up..."
  docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
  docker volume rm not-env-test-integration-data 2>/dev/null || true
  # Clean up built image
  docker rmi not-env-standalone:test > /dev/null 2>&1 || true
  rm -f /tmp/not-env-test.env
  rm -f /tmp/test-env-import.env
  rm -f /tmp/test-app.js
  rm -f /tmp/test-app.py
  rm -f /tmp/not-env-cli-test
}

trap cleanup EXIT

# Step 1: Start Backend
echo ""
echo "Step 1: Starting backend..."
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
docker volume rm not-env-test-integration-data 2>/dev/null || true

# Try to use published image, fallback to building
CONTAINER_STARTED=false
if docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${BACKEND_PORT}:1212 \
  -e DB_TYPE=sqlite \
  -e DB_PATH=/data/test.db \
  -v not-env-test-integration-data:/data \
  ghcr.io/not-env/not-env-standalone:latest 2>&1; then
  # Verify container is actually running
  sleep 1
  if docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "✓ Using published Docker image"
    CONTAINER_STARTED=true
  else
    echo "Container started but exited immediately. Checking logs..."
    docker logs ${CONTAINER_NAME} 2>&1 | tail -20
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
  fi
fi

if [ "$CONTAINER_STARTED" != "true" ]; then
  echo "Building backend image..."
  cd not-env-backend
  if ! docker build -f Dockerfile.sqlite -t not-env-standalone:test .; then
    echo "${RED}✗ Failed to build Docker image${NC}"
    exit 1
  fi
  cd ..
  
  if ! docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${BACKEND_PORT}:1212 \
    -e DB_TYPE=sqlite \
    -e DB_PATH=/data/test.db \
    -v not-env-test-integration-data:/data \
    not-env-standalone:test; then
    echo "${RED}✗ Failed to start Docker container${NC}"
    exit 1
  fi
  
  # Verify container is actually running
  sleep 1
  if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "${RED}✗ Container started but exited immediately${NC}"
    echo "Container logs:"
    docker logs ${CONTAINER_NAME} 2>&1 | tail -20
    exit 1
  fi
  
  echo "✓ Built and started backend"
fi

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
for i in {1..30}; do
  if curl -s ${BACKEND_URL}/health > /dev/null 2>&1; then
    echo "✓ Backend is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "${RED}✗ Backend failed to start${NC}"
    docker logs ${CONTAINER_NAME}
    exit 1
  fi
  sleep 1
done

# Give backend a moment to fully initialize and log the APP_ADMIN key
sleep 2

# Step 2: Get APP_ADMIN key
echo ""
echo "Step 2: Getting APP_ADMIN key..."
# Extract key more robustly: get everything after "APP_ADMIN key: " and before any trailing text in parentheses
# Handle both formats: "APP_ADMIN key: <key>" and "APP_ADMIN key: <key> (from NOT_ENV_APP_ADMIN_KEY)"
APP_ADMIN_KEY=$(docker logs ${CONTAINER_NAME} 2>&1 | grep "APP_ADMIN key:" | grep -v "already exists" | tail -1 | sed -n 's/.*APP_ADMIN key: \([^ (]*\).*/\1/p')
if [ -z "$APP_ADMIN_KEY" ]; then
  echo "${RED}✗ Failed to get APP_ADMIN key${NC}"
  echo "Debug: Full logs with APP_ADMIN:"
  docker logs ${CONTAINER_NAME} 2>&1 | grep -i "app_admin"
  exit 1
fi
echo "✓ APP_ADMIN key retrieved"

# Step 3: Build CLI
echo ""
echo "Step 3: Building CLI..."
cd not-env-cli
go build -o /tmp/not-env-cli-test .
cd ..
echo "✓ CLI built"

# Step 4: CLI Login
echo ""
echo "Step 4: Testing CLI login..."
/tmp/not-env-cli-test login --url ${BACKEND_URL} --api-key ${APP_ADMIN_KEY}
if [ $? -ne 0 ]; then
  echo "${RED}✗ CLI login failed${NC}"
  exit 1
fi
echo "✓ CLI login successful"

# Step 5: Create Environment
echo ""
echo "Step 5: Creating test environment..."
ENV_RESPONSE=$(/tmp/not-env-cli-test env create --name test-env --description "Test environment" 2>&1)
# Use sed pattern matching similar to APP_ADMIN key extraction (more robust)
ENV_ADMIN_KEY=$(echo "$ENV_RESPONSE" | grep "ENV_ADMIN key:" | sed -n 's/.*ENV_ADMIN key: \([^ ]*\).*/\1/p')
ENV_READ_ONLY_KEY=$(echo "$ENV_RESPONSE" | grep "ENV_READ_ONLY key:" | sed -n 's/.*ENV_READ_ONLY key: \([^ ]*\).*/\1/p')

if [ -z "$ENV_ADMIN_KEY" ] || [ -z "$ENV_READ_ONLY_KEY" ]; then
  echo "${RED}✗ Failed to create environment${NC}"
  echo "$ENV_RESPONSE"
  exit 1
fi
echo "✓ Environment created"
echo "  ENV_ADMIN key: ${ENV_ADMIN_KEY:0:20}..."
echo "  ENV_READ_ONLY key: ${ENV_READ_ONLY_KEY:0:20}..."

# Step 6: Test .env Import
echo ""
echo "Step 6: Testing .env import..."
# Create a test .env file
cat > /tmp/test-env-import.env <<EOF
DB_HOST=localhost
DB_PORT=5432
API_KEY=test-api-key-12345
IMPORTED_VAR=imported-value
EOF

# Import .env file (creates new environment)
IMPORT_RESPONSE=$(/tmp/not-env-cli-test env import --name test-import-env --file /tmp/test-env-import.env 2>&1)
# Use sed pattern matching (more robust)
IMPORT_ENV_ADMIN_KEY=$(echo "$IMPORT_RESPONSE" | grep "ENV_ADMIN key:" | sed -n 's/.*ENV_ADMIN key: \([^ ]*\).*/\1/p')
IMPORT_ENV_READ_ONLY_KEY=$(echo "$IMPORT_RESPONSE" | grep "ENV_READ_ONLY key:" | sed -n 's/.*ENV_READ_ONLY key: \([^ ]*\).*/\1/p')

if [ -z "$IMPORT_ENV_ADMIN_KEY" ]; then
  echo "${RED}✗ Failed to import .env file${NC}"
  echo "$IMPORT_RESPONSE"
  exit 1
fi
echo "✓ .env file imported successfully"

# Step 7: Update CLI to use ENV_ADMIN key from imported environment
echo ""
echo "Step 7: Updating CLI to use ENV_ADMIN key from imported environment..."
/tmp/not-env-cli-test login --url ${BACKEND_URL} --api-key ${IMPORT_ENV_ADMIN_KEY}
if [ $? -ne 0 ]; then
  echo "${RED}✗ CLI update failed${NC}"
  exit 1
fi
echo "✓ CLI updated"

# Step 8: Verify Imported Variables via CLI
echo ""
echo "Step 8: Verifying imported variables via CLI..."
# Extract just the value part from KEY=VALUE output
IMPORTED_DB_HOST=$(/tmp/not-env-cli-test var get DB_HOST | cut -d= -f2-)
IMPORTED_DB_PORT=$(/tmp/not-env-cli-test var get DB_PORT | cut -d= -f2-)
IMPORTED_API_KEY=$(/tmp/not-env-cli-test var get API_KEY | cut -d= -f2-)
IMPORTED_VAR=$(/tmp/not-env-cli-test var get IMPORTED_VAR | cut -d= -f2-)

if [ "$IMPORTED_DB_HOST" != "localhost" ] || [ "$IMPORTED_DB_PORT" != "5432" ] || [ "$IMPORTED_API_KEY" != "test-api-key-12345" ] || [ "$IMPORTED_VAR" != "imported-value" ]; then
  echo "${RED}✗ Imported variable values don't match${NC}"
  echo "DB_HOST: $IMPORTED_DB_HOST (expected: localhost)"
  echo "DB_PORT: $IMPORTED_DB_PORT (expected: 5432)"
  echo "API_KEY: $IMPORTED_API_KEY (expected: test-api-key-12345)"
  echo "IMPORTED_VAR: $IMPORTED_VAR (expected: imported-value)"
  exit 1
fi
echo "✓ Imported variables verified"

# Step 9: Also test manual variable setting (for original test-env)
echo ""
echo "Step 9: Testing manual variable setting (original environment)..."
/tmp/not-env-cli-test login --url ${BACKEND_URL} --api-key ${ENV_ADMIN_KEY}
if [ $? -ne 0 ]; then
  echo "${RED}✗ CLI login failed${NC}"
  exit 1
fi
/tmp/not-env-cli-test var set DB_HOST "localhost"
/tmp/not-env-cli-test var set DB_PORT "5432"
/tmp/not-env-cli-test var set API_KEY "test-api-key-12345"
echo "✓ Variables set manually"

# Step 10: Verify Manual Variables via CLI (original environment)
echo ""
echo "Step 10: Verifying manual variables via CLI (original environment)..."
# Extract just the value part from KEY=VALUE output
DB_HOST=$(/tmp/not-env-cli-test var get DB_HOST | cut -d= -f2-)
DB_PORT=$(/tmp/not-env-cli-test var get DB_PORT | cut -d= -f2-)
API_KEY=$(/tmp/not-env-cli-test var get API_KEY | cut -d= -f2-)

if [ "$DB_HOST" != "localhost" ] || [ "$DB_PORT" != "5432" ] || [ "$API_KEY" != "test-api-key-12345" ]; then
  echo "${RED}✗ Variable values don't match${NC}"
  echo "DB_HOST: $DB_HOST (expected: localhost)"
  echo "DB_PORT: $DB_PORT (expected: 5432)"
  echo "API_KEY: $API_KEY (expected: test-api-key-12345)"
  exit 1
fi
echo "✓ Manual variables verified"

# Step 11: Test JavaScript SDK
echo ""
echo "Step 11: Testing JavaScript SDK..."
cd SDKs/not-env-sdk-js

# Ensure SDK is built
if [ ! -d "dist" ] || [ ! -f "dist/register.js" ]; then
  echo "Building JavaScript SDK..."
  npm run build
  if [ $? -ne 0 ]; then
    echo "${RED}✗ Failed to build JavaScript SDK${NC}"
    exit 1
  fi
fi

# Create test app with absolute path to SDK
SDK_DIR=$(pwd)
cat > /tmp/test-app.js <<EOF
require('${SDK_DIR}/dist/register.js');
console.log('DB_HOST=' + process.env.DB_HOST);
console.log('DB_PORT=' + process.env.DB_PORT);
console.log('API_KEY=' + process.env.API_KEY);
EOF

# Run test app
export NOT_ENV_URL=${BACKEND_URL}
export NOT_ENV_API_KEY=${ENV_READ_ONLY_KEY}
JS_OUTPUT=$(node /tmp/test-app.js)

if echo "$JS_OUTPUT" | grep -q "DB_HOST=localhost" && \
   echo "$JS_OUTPUT" | grep -q "DB_PORT=5432" && \
   echo "$JS_OUTPUT" | grep -q "API_KEY=test-api-key-12345"; then
  echo "✓ JavaScript SDK test passed"
else
  echo "${RED}✗ JavaScript SDK test failed${NC}"
  echo "Output: $JS_OUTPUT"
  exit 1
fi

cd ../..

# Step 12: Test Python SDK
echo ""
echo "Step 12: Testing Python SDK..."
cd SDKs/not-env-sdk-python

# Create test app
cat > /tmp/test-app.py <<EOF
import not_env_sdk.register
import os
print('DB_HOST=' + os.environ['DB_HOST'])
print('DB_PORT=' + os.environ['DB_PORT'])
print('API_KEY=' + os.environ['API_KEY'])
EOF

# Run test app
export NOT_ENV_URL=${BACKEND_URL}
export NOT_ENV_API_KEY=${ENV_READ_ONLY_KEY}
PY_OUTPUT=$(python3 /tmp/test-app.py)

if echo "$PY_OUTPUT" | grep -q "DB_HOST=localhost" && \
   echo "$PY_OUTPUT" | grep -q "DB_PORT=5432" && \
   echo "$PY_OUTPUT" | grep -q "API_KEY=test-api-key-12345"; then
  echo "✓ Python SDK test passed"
else
  echo "${RED}✗ Python SDK test failed${NC}"
  echo "Output: $PY_OUTPUT"
  exit 1
fi

cd ../..

# Step 13: Test CLI env export
echo ""
echo "Step 13: Testing CLI env export..."
ENV_EXPORT=$(/tmp/not-env-cli-test env set)
if echo "$ENV_EXPORT" | grep -q "export DB_HOST=" && \
   echo "$ENV_EXPORT" | grep -q "export DB_PORT=" && \
   echo "$ENV_EXPORT" | grep -q "export API_KEY="; then
  echo "✓ CLI env export works"
else
  echo "${RED}✗ CLI env export failed${NC}"
  exit 1
fi

# Success!
echo ""
echo "=========================================="
echo "${GREEN}All Integration Tests: PASSED${NC}"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Backend started and healthy"
echo "  ✓ CLI authentication and commands"
echo "  ✓ Environment and variable management"
echo "  ✓ JavaScript SDK integration"
echo "  ✓ Python SDK integration"
echo "  ✓ CLI shell export"
echo ""

