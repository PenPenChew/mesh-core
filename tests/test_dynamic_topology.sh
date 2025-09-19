#!/bin/bash

# Test script for dynamic topology discovery
# This tests the fix for automatic topology updates when sessions connect

echo "🧪 Testing Dynamic Topology Discovery"
echo "====================================="

# Build the project
echo "Building mesh..."
make build-all

echo ""
echo "🚀 Starting 4-node mesh WITHOUT --neighbor arguments"
echo "This tests that topology is built dynamically from session connections"

# Start nodes in background (no --neighbor arguments!)
echo "Starting node 1001..."
./target/release/mesh --node-id 1001 --listen 0.0.0.0:9000 \
  --enable-grpc --grpc-bind 0.0.0.0:50051 \
  --tls --tls-cert test_certs/node-1001.crt --tls-key test_certs/node-1001.key --tls-ca test_certs/ca.crt &
NODE1_PID=$!

sleep 2

echo "Starting node 2002..."
./target/release/mesh --node-id 2002 --listen 0.0.0.0:9001 \
  --connect 127.0.0.1:9000 \
  --enable-grpc --grpc-bind 0.0.0.0:50052 \
  --tls --tls-cert test_certs/node-2002.crt --tls-key test_certs/node-2002.key --tls-ca test_certs/ca.crt --tls-sni localhost &
NODE2_PID=$!

sleep 2

echo "Starting node 3003..."
./target/release/mesh --node-id 3003 --listen 0.0.0.0:9002 \
  --connect 127.0.0.1:9001 \
  --enable-grpc --grpc-bind 0.0.0.0:50053 \
  --tls --tls-cert test_certs/node-3003.crt --tls-key test_certs/node-3003.key --tls-ca test_certs/ca.crt --tls-sni localhost &
NODE3_PID=$!

sleep 2

echo "Starting node 4004..."
./target/release/mesh --node-id 4004 --listen 0.0.0.0:9003 \
  --connect 127.0.0.1:9002 \
  --enable-grpc --grpc-bind 0.0.0.0:50054 \
  --tls --tls-cert test_certs/node-4004.crt --tls-key test_certs/node-4004.key --tls-ca test_certs/ca.crt --tls-sni localhost &
NODE4_PID=$!

echo ""
echo "⏳ Waiting for nodes to connect and build topology..."
sleep 10

echo ""
echo "🔍 Expected logs to see:"
echo "  - [topology] Updated topology after connection to node X"
echo "  - [topology] Routing table updated after connection to node X"
echo ""

echo "📡 Testing direct connection (2002 -> 3003):"
grpcurl -plaintext -d '{
  "dst_node": 3003,
  "payload": "SGVsbG8gZnJvbSAyMDAyIQ==",
  "corr_id": 12345
}' 127.0.0.1:50052 mesh.v1.MeshData/Send

sleep 2

echo ""
echo "📡 Testing multi-hop routing (2002 -> 4004 via 3003):"
grpcurl -plaintext -d '{
  "dst_node": 4004,
  "payload": "SGVsbG8gZnJvbSAyMDAyIQ==",
  "corr_id": 12346
}' 127.0.0.1:50052 mesh.v1.MeshData/Send

sleep 2

echo ""
echo "🛑 Stopping all nodes..."
kill $NODE1_PID $NODE2_PID $NODE3_PID $NODE4_PID 2>/dev/null

echo ""
echo "✅ Test complete!"
echo ""
echo "🎯 Expected results:"
echo "  ✅ No 'NoRoute' errors"
echo "  ✅ Messages route successfully"
echo "  ✅ Topology updates logged when nodes connect"
echo "  ✅ Routing table updates logged"
