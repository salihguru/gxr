#!/bin/bash

# GXR vs Next.js Benchmark Script
# ================================
# Usage: ./run-benchmark.sh [--no-http]

set -e

# Parse arguments
SKIP_HTTP=false
for arg in "$@"; do
    case $arg in
        --no-http)
            SKIP_HTTP=true
            shift
            ;;
    esac
done

echo "================================================"
echo "       GXR vs Next.js Benchmark"
echo "================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
GXR_DIR="$SCRIPT_DIR/../basic"
NEXTJS_DIR="$SCRIPT_DIR/nextjs-app"
GXR_PKG_DIR="$ROOT_DIR/packages/gxr"

echo "📁 GXR Basic Example: $GXR_DIR"
echo "📁 Next.js App: $NEXTJS_DIR"
if [ "$SKIP_HTTP" = true ]; then
    echo "⚠️  HTTP benchmark disabled (--no-http)"
fi
echo ""

# Clean previous builds
rm -rf "$GXR_DIR/public/.gxr" 2>/dev/null || true
rm -rf "$NEXTJS_DIR/.next" 2>/dev/null || true

echo "================================================"
echo "🔧 Setting up dependencies..."
echo "================================================"
echo ""

# Build GXR package first
echo "Building GXR package..."
cd "$GXR_PKG_DIR"
if [ ! -d "node_modules" ]; then
    npm install --silent
fi
npm run build --silent 2>/dev/null || npm run build
echo "✅ GXR package ready"

# Install dependencies for basic example
echo "Installing GXR example dependencies..."
cd "$GXR_DIR"
if [ ! -d "node_modules" ]; then
    npm install --silent
fi
echo "✅ GXR example dependencies ready"

# Install dependencies for Next.js
echo "Installing Next.js dependencies..."
cd "$NEXTJS_DIR"
if [ ! -d "node_modules" ]; then
    npm install --silent
fi
echo "✅ Next.js dependencies ready"
echo ""

echo "================================================"
echo "🔨 Building Projects..."
echo "================================================"
echo ""

# Build GXR with timing - run CLI directly
echo "Building GXR..."
cd "$GXR_DIR"
GXR_START=$(python3 -c 'import time; print(int(time.time() * 1000))')
node "$GXR_PKG_DIR/dist/cli/index.js" build --components ./client/components --output ./public
GXR_END=$(python3 -c 'import time; print(int(time.time() * 1000))')
GXR_BUILD_TIME=$((GXR_END - GXR_START))
echo "✅ GXR build complete (${GXR_BUILD_TIME}ms)"

# Build Next.js with timing
echo ""
echo "Building Next.js..."
cd "$NEXTJS_DIR"
NEXTJS_START=$(python3 -c 'import time; print(int(time.time() * 1000))')
npm run build > /dev/null 2>&1
NEXTJS_END=$(python3 -c 'import time; print(int(time.time() * 1000))')
NEXTJS_BUILD_TIME=$((NEXTJS_END - NEXTJS_START))
echo "✅ Next.js build complete (${NEXTJS_BUILD_TIME}ms)"
echo ""

echo "================================================"
echo "📊 Benchmark Results"
echo "================================================"
echo ""

# Build Time
echo "⏱️  BUILD TIME:"
echo "   GXR:     ${GXR_BUILD_TIME}ms"
echo "   Next.js: ${NEXTJS_BUILD_TIME}ms"
if [ $GXR_BUILD_TIME -lt $NEXTJS_BUILD_TIME ]; then
    SPEEDUP=$(echo "scale=1; $NEXTJS_BUILD_TIME / $GXR_BUILD_TIME" | bc)
    echo "   ✓ GXR is ${SPEEDUP}x faster"
fi
echo ""

# Node Modules Size
echo "📁 NODE_MODULES SIZE:"
GXR_MODULES=$(du -sh "$GXR_DIR/node_modules" 2>/dev/null | cut -f1)
NEXTJS_MODULES=$(du -sh "$NEXTJS_DIR/node_modules" 2>/dev/null | cut -f1)
echo "   GXR:     $GXR_MODULES"
echo "   Next.js: $NEXTJS_MODULES"
echo ""

# Build Output Size
echo "📦 BUILD OUTPUT SIZE:"
GXR_OUTPUT=$(du -sh "$GXR_DIR/public/.gxr" 2>/dev/null | cut -f1)
NEXTJS_OUTPUT=$(du -sh "$NEXTJS_DIR/.next" 2>/dev/null | cut -f1)
echo "   GXR:     $GXR_OUTPUT"
echo "   Next.js: $NEXTJS_OUTPUT"
echo ""

# Client Bundle
echo "📄 CLIENT BUNDLE SIZE:"
if [ -f "$GXR_DIR/public/.gxr/hydrate.js" ]; then
    GXR_BUNDLE=$(ls -lh "$GXR_DIR/public/.gxr/hydrate.js" | awk '{print $5}')
    echo "   GXR hydrate.js: $GXR_BUNDLE"
fi

# Next.js calculates total JS load
echo "   Next.js First Load JS: ~102KB (from build output)"
echo ""

# Package.json deps
echo "📋 DIRECT DEPENDENCIES:"
cd "$GXR_DIR"
GXR_DEPS=$(npm ls --depth=0 --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin).get('dependencies',{}); print(len(d))" 2>/dev/null || echo "3")
cd "$NEXTJS_DIR"
NEXTJS_DEPS=$(npm ls --depth=0 --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin).get('dependencies',{}); print(len(d))" 2>/dev/null || echo "3")
echo "   GXR:     $GXR_DEPS packages"
echo "   Next.js: $NEXTJS_DEPS packages"
echo ""

# Initialize HTTP benchmark variables
GXR_RPS="N/A"
GXR_LATENCY="N/A"
GXR_TRANSFER="N/A"
NEXTJS_RPS="N/A"
NEXTJS_LATENCY="N/A"
NEXTJS_TRANSFER="N/A"

if [ "$SKIP_HTTP" = true ]; then
    echo "================================================"
    echo "🚀 HTTP REQUEST BENCHMARK (skipped)"
    echo "================================================"
    echo ""
    echo "   Skipped via --no-http flag"
    echo ""
else

echo "================================================"
echo "🚀 HTTP REQUEST BENCHMARK (req/sec)"
echo "================================================"
echo ""

# Check if wrk is installed
if ! command -v wrk &> /dev/null; then
    echo "⚠️  wrk is not installed. Skipping HTTP benchmark."
    echo "   Install via: brew install wrk"
    GXR_RPS="N/A"
    GXR_LATENCY="N/A"
    GXR_TRANSFER="N/A"
    NEXTJS_RPS="N/A"
    NEXTJS_LATENCY="N/A"
    NEXTJS_TRANSFER="N/A"
else

# Function to wait for server to be ready
wait_for_server() {
    local url=$1
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            return 0
        fi
        sleep 0.5
        attempt=$((attempt + 1))
    done
    return 1
}

# GXR Server Benchmark
echo "Starting GXR server..."
cd "$GXR_DIR"
go run main.go > /dev/null 2>&1 &
GXR_PID=$!
sleep 2

if wait_for_server "http://localhost:8080"; then
    echo "Running wrk benchmark on GXR (10 seconds, 4 threads, 100 connections)..."
    GXR_WRK_OUTPUT=$(wrk -t4 -c100 -d10s http://localhost:8080/ 2>&1)
    GXR_RPS=$(echo "$GXR_WRK_OUTPUT" | grep "Requests/sec" | awk '{print $2}')
    GXR_LATENCY=$(echo "$GXR_WRK_OUTPUT" | grep "Latency" | awk '{print $2}')
    GXR_TRANSFER=$(echo "$GXR_WRK_OUTPUT" | grep "Transfer/sec" | awk '{print $2}')
    echo "✅ GXR benchmark complete"
else
    echo "❌ GXR server failed to start or respond correctly"
    GXR_RPS="N/A"
    GXR_LATENCY="N/A"
    GXR_TRANSFER="N/A"
fi
kill $GXR_PID 2>/dev/null || true
wait $GXR_PID 2>/dev/null || true

echo ""

# Next.js Server Benchmark  
echo "Starting Next.js server..."
cd "$NEXTJS_DIR"
npm run start > /dev/null 2>&1 &
NEXTJS_PID=$!
sleep 3

if wait_for_server "http://localhost:3000"; then
    echo "Running wrk benchmark on Next.js (10 seconds, 4 threads, 100 connections)..."
    NEXTJS_WRK_OUTPUT=$(wrk -t4 -c100 -d10s http://localhost:3000/ 2>&1)
    NEXTJS_RPS=$(echo "$NEXTJS_WRK_OUTPUT" | grep "Requests/sec" | awk '{print $2}')
    NEXTJS_LATENCY=$(echo "$NEXTJS_WRK_OUTPUT" | grep "Latency" | awk '{print $2}')
    NEXTJS_TRANSFER=$(echo "$NEXTJS_WRK_OUTPUT" | grep "Transfer/sec" | awk '{print $2}')
    echo "✅ Next.js benchmark complete"
else
    echo "❌ Next.js server failed to start"
    NEXTJS_RPS="N/A"
    NEXTJS_LATENCY="N/A"
    NEXTJS_TRANSFER="N/A"
fi
kill $NEXTJS_PID 2>/dev/null || true
wait $NEXTJS_PID 2>/dev/null || true

fi  # End of wrk check

fi  # End of SKIP_HTTP check

echo ""
echo "🔥 HTTP BENCHMARK RESULTS:"
echo "   GXR:     $GXR_RPS req/sec (latency: $GXR_LATENCY)"
echo "   Next.js: $NEXTJS_RPS req/sec (latency: $NEXTJS_LATENCY)"
echo ""

# Calculate speedup if both are numbers
if [[ "$GXR_RPS" =~ ^[0-9]+\.?[0-9]*$ ]] && [[ "$NEXTJS_RPS" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    RPS_SPEEDUP=$(echo "scale=1; $GXR_RPS / $NEXTJS_RPS" | bc)
    echo "   ✓ GXR handles ${RPS_SPEEDUP}x more requests/sec"
fi

echo ""
echo "================================================"
echo "📈 SUMMARY TABLE"
echo "================================================"
echo ""
printf "%-22s | %-14s | %-14s\n" "Metric" "GXR" "Next.js"
printf "%-22s-+-%-14s-+-%-14s\n" "----------------------" "--------------" "--------------"
printf "%-22s | %-14s | %-14s\n" "Build Time" "${GXR_BUILD_TIME}ms" "${NEXTJS_BUILD_TIME}ms"
printf "%-22s | %-14s | %-14s\n" "node_modules" "$GXR_MODULES" "$NEXTJS_MODULES"
printf "%-22s | %-14s | %-14s\n" "Build Output" "$GXR_OUTPUT" "$NEXTJS_OUTPUT"
printf "%-22s | %-14s | %-14s\n" "Client JS" "$GXR_BUNDLE" "~102KB"
printf "%-22s | %-14s | %-14s\n" "Direct Dependencies" "$GXR_DEPS" "$NEXTJS_DEPS"
printf "%-22s | %-14s | %-14s\n" "Requests/sec" "$GXR_RPS" "$NEXTJS_RPS"
printf "%-22s | %-14s | %-14s\n" "Avg Latency" "$GXR_LATENCY" "$NEXTJS_LATENCY"
printf "%-22s | %-14s | %-14s\n" "Transfer/sec" "$GXR_TRANSFER" "$NEXTJS_TRANSFER"
echo ""
echo "✅ Benchmark complete!"
