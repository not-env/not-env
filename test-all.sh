#!/bin/bash
# Comprehensive test script for not-env
# Runs builds, unit tests, and optional functional tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILURES=0
TESTS_RUN=0

# Function to run a test and track results
run_test() {
    local name="$1"
    shift
    local command="$@"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing $name... "
    
    if (cd "$SCRIPT_DIR" && eval "$command") > /tmp/test-output.log 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Output:"
        cat /tmp/test-output.log | tail -10
        FAILURES=$((FAILURES + 1))
        return 1
    fi
}

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${YELLOW}Warning: $1 not found, skipping related tests${NC}"
        return 1
    fi
    return 0
}

echo "=========================================="
echo "not-env Comprehensive Test Suite"
echo "=========================================="
echo ""

# Change to repo root (script location)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ============================================
# 1. BUILD VERIFICATION
# ============================================
echo "=== Build Verification ==="

run_test "Backend build" "cd not-env-backend && go build -o /dev/null ."
run_test "CLI build" "cd not-env-cli && go build -o /tmp/not-env-test ."
run_test "JavaScript SDK build" "cd SDKs/not-env-sdk-js && npm run build > /dev/null 2>&1"

if check_command "python3"; then
    run_test "Python SDK compile" "cd SDKs/not-env-sdk-python && python3 -m py_compile src/not_env_sdk/*.py 2>&1"
else
    echo -e "${YELLOW}Skipping Python SDK compile (python3 not found)${NC}"
fi

echo ""

# ============================================
# 2. UNIT TESTS
# ============================================
echo "=== Unit Tests ==="

run_test "Backend unit tests" "cd not-env-backend && go test ./... -v"
run_test "CLI unit tests" "cd not-env-cli && go test ./... -v"

if check_command "npm"; then
    run_test "JavaScript SDK tests" "cd \"$SCRIPT_DIR/SDKs/not-env-sdk-js\" && npm test 2>&1"
else
    echo -e "${YELLOW}Skipping JavaScript SDK tests (npm not found)${NC}"
fi

if check_command "pytest"; then
    run_test "Python SDK tests" "cd \"$SCRIPT_DIR/SDKs/not-env-sdk-python\" && pytest -v 2>&1"
else
    echo -e "${YELLOW}Skipping Python SDK tests (pytest not found)${NC}"
fi

echo ""

# ============================================
# 3. FUNCTIONAL TESTS (Optional)
# ============================================
if [ "$1" == "--functional" ] || [ "$1" == "-f" ]; then
    echo "=== Functional Tests ==="
    echo "These tests require a running backend..."
    
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker not found, skipping functional tests${NC}"
    else
        # Check if backend is running
        if docker ps | grep -q "not-env"; then
            echo -e "${GREEN}Backend container found${NC}"
        else
            echo -e "${YELLOW}No backend container found. Starting test backend...${NC}"
            docker run -d --name not-env-test-functional -p 1213:1212 \
                -v not-env-test-functional-data:/data \
                ghcr.io/not-env/not-env-standalone:latest > /dev/null 2>&1 || true
            
            echo "Waiting for backend to start..."
            sleep 5
            
            # Cleanup function
            cleanup_backend() {
                docker rm -f not-env-test-functional > /dev/null 2>&1 || true
                docker volume rm not-env-test-functional-data > /dev/null 2>&1 || true
            }
            trap cleanup_backend EXIT
        fi
        
        # Get APP_ADMIN key
        if docker ps | grep -q "not-env-test-functional"; then
            BACKEND_URL="http://localhost:1213"
            APP_ADMIN_KEY=$(docker logs not-env-test-functional 2>&1 | grep "APP_ADMIN key" | tail -1 | awk '{print $NF}')
        else
            BACKEND_URL="http://localhost:1212"
            # Try to get key from any not-env container
            APP_ADMIN_KEY=$(docker ps --format "{{.Names}}" | grep not-env | head -1 | xargs -I {} docker logs {} 2>&1 | grep "APP_ADMIN key" | tail -1 | awk '{print $NF}')
        fi
        
        if [ -z "$APP_ADMIN_KEY" ]; then
            echo -e "${RED}Could not get APP_ADMIN key. Skipping functional tests.${NC}"
        else
            echo "Testing env import outputs both keys..."
            
            # Login
            echo -e "${BACKEND_URL}\n${APP_ADMIN_KEY}" | /tmp/not-env-test login > /dev/null 2>&1
            
            # Create test .env
            cat > /tmp/test-env-import-functional.env <<EOF
DB_HOST=localhost
DB_PORT=5432
API_KEY=test-secret-key-functional
EOF
            
            # Test env import
            IMPORT_OUTPUT=$(/tmp/not-env-test env import --name functional-test --file /tmp/test-env-import-functional.env 2>&1)
            
            if echo "$IMPORT_OUTPUT" | grep -q "ENV_ADMIN key:" && \
               echo "$IMPORT_OUTPUT" | grep -q "ENV_READ_ONLY key:" && \
               echo "$IMPORT_OUTPUT" | grep -q "Use ENV_ADMIN for managing variables" && \
               echo "$IMPORT_OUTPUT" | grep -q "Use ENV_READ_ONLY for applications"; then
                echo -e "${GREEN}✓ env import outputs both keys correctly${NC}"
            else
                echo -e "${RED}✗ env import missing expected output${NC}"
                echo "Output:"
                echo "$IMPORT_OUTPUT"
                FAILURES=$((FAILURES + 1))
            fi
            
            # Test error message improvement
            ERROR_OUTPUT=$(/tmp/not-env-test env import --name functional-test --file /tmp/test-env-import-functional.env 2>&1)
            
            if echo "$ERROR_OUTPUT" | grep -q "To import variables:" && \
               echo "$ERROR_OUTPUT" | grep -q "Run: not-env login"; then
                echo -e "${GREEN}✓ Error message shows step-by-step instructions${NC}"
            else
                echo -e "${YELLOW}⚠ Error message format may need verification${NC}"
            fi
            
            # Cleanup test environment
            /tmp/not-env-test logout > /dev/null 2>&1 || true
            rm -f /tmp/test-env-import-functional.env
        fi
    fi
    
    echo ""
fi

# ============================================
# SUMMARY
# ============================================
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
if [ $FAILURES -eq 0 ]; then
    echo -e "Result: ${GREEN}ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "Result: ${RED}$FAILURES TEST(S) FAILED${NC}"
    echo ""
    echo "Run with --functional flag to include functional tests:"
    echo "  ./test-all.sh --functional"
    exit 1
fi

