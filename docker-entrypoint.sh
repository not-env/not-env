#!/bin/sh
set -e

# Handle signals for graceful shutdown
cleanup() {
    echo "Shutting down..."
    if [ -n "$BACKEND_PID" ]; then
        kill -TERM "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# Start backend in background
echo "Starting not-env backend..."
cd /app/backend
./not-env-backend &
BACKEND_PID=$!

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
for i in $(seq 1 30); do
    if wget -q --spider http://localhost:1212/health 2>/dev/null; then
        echo "Backend is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Backend failed to start within 30 seconds"
        exit 1
    fi
    sleep 1
done

# Start frontend in foreground (keeps container alive)
echo "Starting not-env frontend..."
cd /app/frontend
exec node server.js
