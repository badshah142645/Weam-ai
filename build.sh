#!/bin/bash

# 🧰 Universal Docker Build Script (Cross-Platform + Compose v1/v2 Compatible)

echo "🔍 Detecting Operating System..."
case "$(uname -s)" in
    Linux*)     OS="Linux/Ubuntu" ;;
    Darwin*)    OS="macOS" ;;
    MINGW*|MSYS*|CYGWIN*) OS="Windows (Git Bash/WSL)" ;;
    *)          echo "❌ Unsupported OS"; exit 1 ;;
esac
echo "✅ OS Detected: $OS"

echo "🔍 Checking Docker Compose version..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"  # v1
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"  # v2
else
    echo "❌ Docker Compose not found. Please install Docker Compose v1 or v2."
    exit 1
fi
echo "✅ Docker Compose Command: $COMPOSE_CMD"

# Step 1: Build base image
echo "🚧 Step 1/5: Building base image (pybase_docker)..."
$COMPOSE_CMD build --no-cache pybase_docker || { echo "❌ Failed to build pybase_docker"; exit 1; }
echo "✅ pybase_docker image built successfully."

# Step 2: Load .env
echo "📄 Step 2/5: Loading environment variables..."
if [ ! -f .env ]; then
  echo "❌ .env file not found!"
  exit 1
fi
set -e
set -a
source .env
set +a
echo "✅ Environment variables loaded."

# Step 3: Determine build target
echo "🛠️ Step 3/5: Determining target environment..."
TARGET="production"
[ "$NEXT_PUBLIC_APP_ENVIRONMENT" == "development" ] && TARGET="development"
echo "✅ Target selected: $TARGET"

# Step 4: Convert .env keys into --build-arg
echo "⚙️ Step 4/5: Preparing build arguments..."
BUILD_ARGS=$(grep -v '^#' .env | sed '/^\s*$/d' | awk -F= '{print "--build-arg " $1}' | xargs)
echo "✅ Build arguments prepared."

# Step 5: Build final frontend image
echo "🚀 Step 5/5: Building frontend Docker image (weamai-app)..."
docker build $BUILD_ARGS \
  --target=$TARGET \
  -f ./nextjs/Dockerfile \
  -t weamai-app:latest \
  ./nextjs --no-cache || { echo "❌ Docker build failed"; exit 1; }

echo "🎉 Build complete: weamai-app:latest"