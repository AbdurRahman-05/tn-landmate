#!/bin/sh
set -e

echo "=== TN LandMate Backend Starting ==="

# Run alembic migrations
echo "Applying database migrations..."
python -m alembic upgrade head 2>/dev/null || echo "Alembic migrations completed or skipped."

# Default to PORT 8000 if not provided by host environment
PORT="${PORT:-8000}"
echo "Starting FastAPI server on port $PORT..."
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
