#!/bin/bash

# Multi-hop Routing Test Script for Mesh Network
# Tests routing across multiple hops with gRPC API

set -e

echo "=== Multi-hop Routing Test ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MESH_BIN="./target/release/mesh"
CERT_DIR="test_certs_localhost"
TEST_DURATION=10

# Check if mesh binary exists
if [ ! -f "$MESH_BIN" ]; then
    echo -e "${RED}Error: mesh binary not found at $MESH_BIN${NC}"
    echo "Please run: make release"
    exit 1
fi

# Check if certificates exist
if [ ! -d "$CERT_DIR" ]; then
    echo -e "${YELLOW}Generating localhost certificates...${NC}"
    make certs-localhost
fi

echo -e "${BLUE}Building mesh with TLS support...${NC}"
make release

echo -e "${BLUE}Setting up 4-node mesh topology:${NC}"
echo "  Node 1001 (Hub) ←→ Node 2002"
echo "  Node 1001 (Hub) ←→ Node 3003" 
echo "  Node 3003       ←→ Node 4004"
echo ""
echo "Multi-hop path: 2002 → 1001 → 3003 → 4004"
echo ""

# Function to start a mesh node
start_node() {
    local node_id=$1
    local listen_port=$2
    local connect_addr=$3
    local grpc_port=$4
    local neighbors=$5
    
    local cmd="$MESH_BIN --node-id $node_id"
    
    if [ -n "$listen_port" ]; then
        cmd="$cmd --listen 0.0.0.0:$listen_port"
    fi
    
    if [ -n "$connect_addr" ]; then
        cmd="$cmd --connect $connect_addr"
    fi
    
    cmd="$cmd --tls"
    cmd="$cmd --tls-cert $CERT_DIR/node-$node_id.crt"
    cmd="$cmd --tls-key $CERT_DIR/node-$node_id.key"
    cmd="$cmd --tls-ca $CERT_DIR/ca.crt"
    
    if [ -n "$connect_addr" ]; then
        cmd="$cmd --tls-sni localhost"
    fi
    
    # Add gRPC server
    cmd="$cmd --enable-grpc --grpc-bind 127.0.0.1:$grpc_port"
    
    # Add neighbor routes for routing
    if [ -n "$neighbors" ]; then
        for neighbor in $neighbors; do
            cmd="$cmd --neighbor $neighbor"
        done
    fi
    
    echo -e "${GREEN}Starting node $node_id...${NC}"
    echo "Command: $cmd"
    
    # Start in background and capture PID
    $cmd > "node_${node_id}.log" 2>&1 &
    local pid=$!
    echo $pid > "node_${node_id}.pid"
    
    # Wait a moment for startup
    sleep 2
    
    # Check if process is still running
    if ! kill -0 $pid 2>/dev/null; then
        echo -e "${RED}Failed to start node $node_id${NC}"
        cat "node_${node_id}.log"
        return 1
    fi
    
    echo -e "${GREEN}Node $node_id started (PID: $pid)${NC}"
    return 0
}

# Function to stop all nodes
cleanup() {
    echo -e "${YELLOW}Stopping all nodes...${NC}"
    
    for node in 1001 2002 3003 4004; do
        if [ -f "node_${node}.pid" ]; then
            local pid=$(cat "node_${node}.pid")
            if kill -0 $pid 2>/dev/null; then
                echo "Stopping node $node (PID: $pid)"
                kill $pid
                sleep 1
                # Force kill if still running
                if kill -0 $pid 2>/dev/null; then
                    kill -9 $pid
                fi
            fi
            rm -f "node_${node}.pid"
        fi
    done
    
    # Clean up log files
    rm -f node_*.log
    
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Set up cleanup on exit
trap cleanup EXIT

echo -e "${BLUE}1. Starting Node 1001 (Hub - connects to 2002 and 3003)${NC}"
start_node 1001 9000 "" 50051 "127.0.0.1:9001 127.0.0.1:9002"

echo -e "${BLUE}2. Starting Node 2002 (connects to 1001)${NC}"
start_node 2002 9001 "127.0.0.1:9000" 50052 "127.0.0.1:9000"

echo -e "${BLUE}3. Starting Node 3003 (connects to 1001, listens for 4004)${NC}"
start_node 3003 9002 "127.0.0.1:9000" 50053 "127.0.0.1:9000 127.0.0.1:9003"

echo -e "${BLUE}4. Starting Node 4004 (connects to 3003)${NC}"
start_node 4004 9003 "127.0.0.1:9002" 50054 "127.0.0.1:9002"

echo -e "${GREEN}All nodes started successfully!${NC}"
echo ""

# Wait for all connections to establish
echo -e "${BLUE}Waiting for mesh to stabilize...${NC}"
sleep 5

echo -e "${BLUE}5. Testing gRPC connectivity${NC}"

# Function to test gRPC endpoint
test_grpc() {
    local port=$1
    local node_id=$2
    
    echo "Testing gRPC on port $port (node $node_id)..."
    
    # Simple test using grpcurl if available, otherwise just check if port is open
    if command -v grpcurl >/dev/null 2>&1; then
        if grpcurl -plaintext 127.0.0.1:$port list >/dev/null 2>&1; then
            echo -e "${GREEN}✓ gRPC server on port $port is responding${NC}"
            return 0
        else
            echo -e "${RED}✗ gRPC server on port $port is not responding${NC}"
            return 1
        fi
    else
        # Fallback: check if port is open
        if nc -z 127.0.0.1 $port 2>/dev/null; then
            echo -e "${GREEN}✓ Port $port is open${NC}"
            return 0
        else
            echo -e "${RED}✗ Port $port is not open${NC}"
            return 1
        fi
    fi
}

# Test all gRPC endpoints
test_grpc 50051 1001
test_grpc 50052 2002
test_grpc 50053 3003
test_grpc 50054 4004

echo ""
echo -e "${BLUE}6. Checking node logs for routing information${NC}"

# Function to check logs for routing info
check_routing_logs() {
    local node_id=$1
    echo "=== Node $node_id routing information ==="
    
    if [ -f "node_${node_id}.log" ]; then
        echo "Routes configured:"
        grep -i "route\|neighbor" "node_${node_id}.log" || echo "No routing info found"
        echo ""
        
        echo "Session connections:"
        grep -i "session\|connected\|handshake" "node_${node_id}.log" | tail -5 || echo "No session info found"
        echo ""
    else
        echo "Log file not found for node $node_id"
    fi
}

for node in 1001 2002 3003 4004; do
    check_routing_logs $node
done

echo -e "${BLUE}7. Network topology verification${NC}"
echo "Expected connections:"
echo "  1001 ↔ 2002 (direct)"
echo "  1001 ↔ 3003 (direct)" 
echo "  3003 ↔ 4004 (direct)"
echo ""
echo "Multi-hop paths:"
echo "  2002 → 4004: 2002 → 1001 → 3003 → 4004"
echo "  4004 → 2002: 4004 → 3003 → 1001 → 2002"
echo ""

# Show active connections
echo -e "${BLUE}Active TCP connections:${NC}"
netstat -an | grep -E ":(9000|9001|9002|9003|50051|50052|50053|50054)" | grep ESTABLISHED || echo "No established connections found"

echo ""
echo -e "${GREEN}Multi-hop routing test setup complete!${NC}"
echo ""
echo -e "${YELLOW}To test routing manually:${NC}"
echo ""
echo "1. Install grpcurl:"
echo "   brew install grpcurl  # macOS"
echo "   # or download from https://github.com/fullstorydev/grpcurl"
echo ""
echo "2. Send a message from node 2002 to node 4004:"
echo "   grpcurl -plaintext -d '{\"dst_node\": 4004, \"payload\": \"SGVsbG8gZnJvbSAyMDAyIQ==\", \"corr_id\": 12345}' \\"
echo "     127.0.0.1:50052 mesh.v1.MeshData/Send"
echo ""
echo "3. Subscribe to messages on node 4004:"
echo "   grpcurl -plaintext -d '{\"src_node\": 2002}' \\"
echo "     127.0.0.1:50054 mesh.v1.MeshData/Subscribe"
echo ""
echo "4. Check routing table on any node:"
echo "   grpcurl -plaintext -d '{}' 127.0.0.1:50051 mesh.v1.MeshControl/GetRoutingTable"
echo ""
echo "5. Get topology information:"
echo "   grpcurl -plaintext -d '{}' 127.0.0.1:50051 mesh.v1.MeshControl/GetTopology"
echo ""
echo -e "${BLUE}Nodes will run for $TEST_DURATION seconds...${NC}"

# Keep nodes running for the test duration
for i in $(seq 1 $TEST_DURATION); do
    echo -n "."
    sleep 1
done

echo ""
echo -e "${GREEN}Test completed!${NC}"

# Show final status
echo ""
echo -e "${BLUE}Final node status:${NC}"
for node in 1001 2002 3003 4004; do
    if [ -f "node_${node}.pid" ]; then
        local pid=$(cat "node_${node}.pid")
        if kill -0 $pid 2>/dev/null; then
            echo -e "${GREEN}✓ Node $node is running${NC}"
        else
            echo -e "${RED}✗ Node $node stopped${NC}"
        fi
    fi
done

echo ""
echo -e "${YELLOW}Note: This test sets up the mesh topology but doesn't implement actual${NC}"
echo -e "${YELLOW}message forwarding yet. The routing table is configured, but you'll need${NC}"
echo -e "${YELLOW}to integrate the routing decisions with the session layer to enable${NC}"
echo -e "${YELLOW}actual multi-hop message delivery.${NC}"
echo ""
echo -e "${BLUE}Next steps for full multi-hop routing:${NC}"
echo "1. Integrate routing decisions with session message forwarding"
echo "2. Implement topology discovery and route computation"
echo "3. Add DATA frame forwarding based on routing decisions"
echo "4. Test end-to-end message delivery across multiple hops"
