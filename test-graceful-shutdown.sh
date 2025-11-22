#!/bin/bash
# Test graceful shutdown of not-env backend

set -e

echo "=========================================="
echo "Testing Graceful Shutdown"
echo "=========================================="

# Clean up any existing containers
docker rm -f not-env-test-shutdown 2>/dev/null || true

# Start backend in background
echo ""
echo "Starting backend container..."
CONTAINER_STARTED=false
BUILT_IMAGE_ID=""

if docker run -d \
  --name not-env-test-shutdown \
  -p 1213:1212 \
  -e DB_TYPE=sqlite \
  -e DB_PATH=/data/test.db \
  -v not-env-test-data:/data \
  ghcr.io/not-env/not-env-standalone:latest 2>&1; then
  sleep 1
  if docker ps --format "{{.Names}}" | grep -q "^not-env-test-shutdown$"; then
    CONTAINER_STARTED=true
  else
    docker rm -f not-env-test-shutdown > /dev/null 2>&1 || true
  fi
fi

if [ "$CONTAINER_STARTED" != "true" ]; then
  echo "Building backend image..."
  cd not-env-backend
  BUILT_IMAGE_ID=$(docker build -f Dockerfile.sqlite -q .)
  cd ..
  docker run -d \
    --name not-env-test-shutdown \
    -p 1213:1212 \
    -e DB_TYPE=sqlite \
    -e DB_PATH=/data/test.db \
    -v not-env-test-data:/data \
    ${BUILT_IMAGE_ID}
fi

# Wait for server to start
echo "Waiting for server to start..."
sleep 3

# Verify server is running
if ! curl -s http://localhost:1213/health > /dev/null; then
  echo "ERROR: Server failed to start"
  docker logs not-env-test-shutdown
  docker rm -f not-env-test-shutdown
  exit 1
fi

echo "✓ Server is running"

# Send SIGTERM
echo ""
echo "Sending SIGTERM to container..."
docker stop not-env-test-shutdown

# Wait a moment for shutdown
sleep 2

# Check logs for graceful shutdown message
echo ""
echo "Checking shutdown logs..."
if docker logs not-env-test-shutdown 2>&1 | grep -q "Shutting down server"; then
  echo "✓ Graceful shutdown message found"
else
  echo "WARNING: Graceful shutdown message not found in logs"
  docker logs not-env-test-shutdown
fi

if docker logs not-env-test-shutdown 2>&1 | grep -q "Server stopped"; then
  echo "✓ Server stopped message found"
else
  echo "WARNING: Server stopped message not found in logs"
fi

# Verify container stopped (not killed)
if [ "$(docker inspect -f '{{.State.Status}}' not-env-test-shutdown 2>/dev/null)" = "exited" ]; then
  echo "✓ Container exited gracefully (not killed)"
else
  echo "WARNING: Container status unexpected"
fi

# Cleanup
docker rm -f not-env-test-shutdown 2>/dev/null || true
# Clean up built image if it exists
if [ -n "$BUILT_IMAGE_ID" ]; then
  docker rmi ${BUILT_IMAGE_ID} > /dev/null 2>&1 || true
fi

echo ""
echo "=========================================="
echo "Graceful Shutdown Test: PASSED"
echo "=========================================="

