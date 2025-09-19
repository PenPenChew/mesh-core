#!/bin/bash

# Test script for the Mesh MVP
# This demonstrates the listener and connector functionality

echo "=== Mesh MVP Test ==="
echo

# Build the project
echo "Building mesh binary..."
cargo build --release -p mesh-bin
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
echo

# Test 1: Show help
echo "1. Testing CLI help:"
./target/release/mesh --help
echo

# Test 2: Test invalid arguments
echo "2. Testing error handling (no listen or connect):"
./target/release/mesh --node-id 999 2>&1 | head -3
echo

# Test 3: Quick connection test (will fail but shows the attempt)
echo "3. Testing connection attempt (will fail - no listener):"
echo "   Starting connector that will try to connect to non-existent listener..."
echo "   (This should show connection attempts and failures)"
echo

# Run connector for a few seconds then kill it
./target/release/mesh --node-id 2002 --connect 127.0.0.1:19999 --ping-interval 1s --idle-timeout 3s --log-level info &
CONNECTOR_PID=$!

# Let it try for a few seconds
sleep 3

# Kill the connector
kill $CONNECTOR_PID 2>/dev/null
wait $CONNECTOR_PID 2>/dev/null

echo
echo "=== MVP Test Complete ==="
echo
echo "To test full functionality, run in two terminals:"
echo
echo "Terminal A (listener):"
echo "  ./target/release/mesh --node-id 1001 --listen 0.0.0.0:9000 --ping-interval 5s --idle-timeout 30s"
echo
echo "Terminal B (connector):"
echo "  ./target/release/mesh --node-id 2002 --connect 127.0.0.1:9000 --ping-interval 5s --idle-timeout 30s"
echo
echo "Expected output:"
echo "  - Both sides show 'Connected to ...' messages"
echo "  - Periodic '[keepalive] PONG RTT = ...' messages"
echo "  - Clean disconnection when one side is terminated"
