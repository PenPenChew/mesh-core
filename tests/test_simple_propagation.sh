#!/bin/bash

# Simple test to isolate the propagation issue
# Start nodes sequentially with delays to avoid race conditions

set -e

echo "🧪 Testing Simple Topology Propagation"
echo "====================================="
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

echo "🚀 Starting nodes sequentially with delays..."
echo ""

# Start node 2002 first
echo "Starting node 2002..."
./target/release/mesh \
  --node-id 2002 \
  --listen 0.0.0.0:9002 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50052 &
NODE_2002_PID=$!
sleep 3

# Connect node 1001
echo "Connecting node 1001 to 2002..."
./target/release/mesh \
  --node-id 1001 \
  --connect 127.0.0.1:9002 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50051 &
NODE_1001_PID=$!
sleep 3

echo "Checking 2-node topology..."
echo "Node 1001 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50051 mesh.v1.MeshControl/GetRoutingTable | jq '.routes | length'
echo "Node 2002 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50052 mesh.v1.MeshControl/GetRoutingTable | jq '.routes | length'
echo ""

# Connect node 3003
echo "Connecting node 3003 to 2002..."
./target/release/mesh \
  --node-id 3003 \
  --connect 127.0.0.1:9002 \
  --listen 0.0.0.0:9003 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50053 &
NODE_3003_PID=$!
sleep 3

echo "Checking 3-node topology..."
echo "Node 1001 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50051 mesh.v1.MeshControl/GetRoutingTable | jq '.routes | length'
echo "Node 2002 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50052 mesh.v1.MeshControl/GetRoutingTable | jq '.routes | length'
echo "Node 3003 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50053 mesh.v1.MeshControl/GetRoutingTable | jq '.routes | length'
echo ""

# Connect node 4004
echo "Connecting node 4004 to 3003..."
./target/release/mesh \
  --node-id 4004 \
  --connect 127.0.0.1:9003 \
  --enable-grpc \
  --grpc-bind 0.0.0.0:50054 &
NODE_4004_PID=$!
sleep 5

echo "Checking final 4-node topology..."
echo "Node 1001 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50051 mesh.v1.MeshControl/GetRoutingTable
echo ""
echo "Node 2002 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50052 mesh.v1.MeshControl/GetRoutingTable
echo ""
echo "Node 3003 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50053 mesh.v1.MeshControl/GetRoutingTable
echo ""
echo "Node 4004 routing table:"
grpcurl -plaintext -d '{}' 127.0.0.1:50054 mesh.v1.MeshControl/GetRoutingTable
echo ""

echo "Testing 4004 → 1001 routing..."
RESULT=$(grpcurl -plaintext -d '{
  "dst_node": 1001,
  "payload": "SGVsbG8gZnJvbSA0MDA0IQ==",
  "corr_id": 54321
}' 127.0.0.1:50054 mesh.v1.MeshData/Send 2>&1)

echo "Result: $RESULT"

echo ""
echo "🧹 Cleaning up..."
kill $NODE_1001_PID $NODE_2002_PID $NODE_3003_PID $NODE_4004_PID 2>/dev/null || true
sleep 2

echo "✅ Test complete."
