#!/bin/bash

# Test script for topology propagation fix
# Tests 4-node linear topology: 1001 ←→ 2002 ←→ 3003 ←→ 4004

set -e

echo "🧪 Testing Topology Propagation Fix"
echo "=================================="
echo ""

# Build the project
echo "📦 Building mesh binary..."
cargo build --release
echo ""

# Kill any existing mesh processes
echo "🧹 Cleaning up existing processes..."
pkill -f "target/release/mesh" || true
sleep 2
echo ""

# Start nodes in order
echo "🚀 Starting 4-node linear topology..."
echo ""

# Node 2002 (middle-left)
echo "Starting node 2002 (listening on 9002, gRPC on 50052)..."
./target/release/mesh \
  --node-id 2002 \
  --listen 0.0.0.0:9002 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50052 &
NODE_2002_PID=$!
sleep 2

# Node 1001 (leftmost) - connects to 2002
echo "Starting node 1001 (connecting to 2002, gRPC on 50051)..."
./target/release/mesh \
  --node-id 1001 \
  --connect 127.0.0.1:9002 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50051 &
NODE_1001_PID=$!
sleep 2

# Node 3003 (middle-right) - connects to 2002
echo "Starting node 3003 (connecting to 2002, listening on 9003, gRPC on 50053)..."
./target/release/mesh \
  --node-id 3003 \
  --connect 127.0.0.1:9002 \
  --listen 0.0.0.0:9003 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50053 &
NODE_3003_PID=$!
sleep 2

# Node 4004 (rightmost) - connects to 3003
echo "Starting node 4004 (connecting to 3003, gRPC on 50054)..."
./target/release/mesh \
  --node-id 4004 \
  --connect 127.0.0.1:9003 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50054 &
NODE_4004_PID=$!

echo ""
echo "⏳ Waiting for topology convergence (10 seconds)..."
sleep 10
echo ""

# Function to check routing table
check_routing_table() {
    local node_name=$1
    local port=$2
    local expected_routes=$3
    
    echo "📊 Checking routing table for $node_name (port $port):"
    
    local result
    result=$(grpcurl -plaintext -d '{}' 127.0.0.1:$port mesh.v1.MeshControl/GetRoutingTable 2>/dev/null || echo "ERROR")
    
    if [[ "$result" == "ERROR" ]]; then
        echo "   ❌ Failed to get routing table"
        return 1
    fi
    
    echo "$result" | jq '.'
    
    # Count routes
    local route_count
    route_count=$(echo "$result" | jq '.routes | length' 2>/dev/null || echo "0")
    
    echo "   Routes found: $route_count (expected: $expected_routes)"
    
    if [[ "$route_count" -ge "$expected_routes" ]]; then
        echo "   ✅ Sufficient routes found"
        return 0
    else
        echo "   ❌ Insufficient routes (expected at least $expected_routes)"
        return 1
    fi
}

echo "🔍 Checking routing tables..."
echo ""

# Expected routing table sizes after fix:
# Node 1001: Should see 2002 (direct), 3003 (via 2002), 4004 (via 2002) = 3 routes
# Node 2002: Should see 1001 (direct), 3003 (direct), 4004 (via 3003) = 3 routes  
# Node 3003: Should see 2002 (direct), 4004 (direct), 1001 (via 2002) = 3 routes
# Node 4004: Should see 3003 (direct), 2002 (via 3003), 1001 (via 3003) = 3 routes

PASS=0
TOTAL=4

if check_routing_table "Node 1001" 50051 3; then
    ((PASS++))
fi
echo ""

if check_routing_table "Node 2002" 50052 3; then
    ((PASS++))
fi
echo ""

if check_routing_table "Node 3003" 50053 3; then
    ((PASS++))
fi
echo ""

if check_routing_table "Node 4004" 50054 3; then
    ((PASS++))
fi
echo ""

# Test multi-hop message routing
echo "📨 Testing multi-hop message routing..."
echo ""

# Test 1001 → 4004 (3 hops)
echo "Testing message from 1001 to 4004 (should route via 2002 → 3003):"
RESULT=$(grpcurl -plaintext -d '{
  "dst_node": 4004,
  "payload": "SGVsbG8gZnJvbSAxMDAxIQ==",
  "corr_id": 12345
}' 127.0.0.1:50051 mesh.v1.MeshData/Send 2>&1)

if echo "$RESULT" | grep -q "NoRoute"; then
    echo "   ❌ NoRoute error - multi-hop routing failed"
else
    echo "   ✅ Message sent successfully"
    ((PASS++))
fi

# Test 4004 → 1001 (3 hops)
echo ""
echo "Testing message from 4004 to 1001 (should route via 3003 → 2002):"
RESULT=$(grpcurl -plaintext -d '{
  "dst_node": 1001,
  "payload": "SGVsbG8gZnJvbSA0MDA0IQ==",
  "corr_id": 54321
}' 127.0.0.1:50054 mesh.v1.MeshData/Send 2>&1)

if echo "$RESULT" | grep -q "NoRoute"; then
    echo "   ❌ NoRoute error - multi-hop routing failed"
else
    echo "   ✅ Message sent successfully"
    ((PASS++))
fi

TOTAL=6  # 4 routing table checks + 2 message tests

echo ""
echo "🏁 Test Results:"
echo "==============="
echo "Passed: $PASS/$TOTAL tests"

if [[ $PASS -eq $TOTAL ]]; then
    echo "🎉 ALL TESTS PASSED! Topology propagation fix is working correctly."
    EXIT_CODE=0
else
    echo "❌ Some tests failed. Topology propagation may still have issues."
    EXIT_CODE=1
fi

echo ""
echo "🧹 Cleaning up..."
kill $NODE_1001_PID $NODE_2002_PID $NODE_3003_PID $NODE_4004_PID 2>/dev/null || true
sleep 2

echo "✅ Test complete."
exit $EXIT_CODE
