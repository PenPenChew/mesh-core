# Start a test node

# Require an argument for the node ID
if [ -z "$1" ]; then
    echo "Usage: $0 <node_id>"
    exit 1
fi

node_id=$1

# Listen ports for each node
# Extract the last 3 digits from node_id (1001->001, 2002->002, etc.) and add to base port
# Force decimal interpretation by removing leading zeros
port_offset=${node_id: -3}
port_offset=$((10#$port_offset))
listen_port=$((10000 + port_offset))
grpc_port=$((50100 + port_offset))

# Connect address for each node
# 1001 starts without connecting to anything
# 2002 connects to 1001
# 3003 connects to 1002
# 4004 connects to 3003
# 5005 connects to 2002 and 4004
# 6006 connects to 5005
# 7007 connects to 6006
# 8008 connects to 7007
# 9009 connects to 1001 and 7007
# 10010 connects to 9009
# 11011 connects to 9009
# 12012 connects to 10010 and 11011
# 13013 connects to 12012
# 14014 connects to 13013
# 15015 connects to 14014
# 16016 does not connect to anything (can be used to test AddSession)

# Generate the connect address for each node (--connect ip:port)
connect_args=""
case $node_id in
    1001)
        # 1001 starts without connecting to anything
        connect_args=""
        ;;
    2002)
        # 2002 connects to 1001
        connect_args="--connect 127.0.0.1:10001"
        ;;
    3003)
        # 3003 connects to 1002
        connect_args="--connect 127.0.0.1:10002"
        ;;
    4004)
        # 4004 connects to 3003
        connect_args="--connect 127.0.0.1:10002"
        ;;
    5005)
        # 5005 connects to 2002 and 4004
        connect_args="--connect 127.0.0.1:10003 --connect 127.0.0.1:10004"
        ;;
    6006)
        # 6006 connects to 5005
        connect_args="--connect 127.0.0.1:10005"
        ;;
    7007)
        # 7007 connects to 6006
        connect_args="--connect 127.0.0.1:10006"
        ;;
    8008)
        # 8008 connects to 7007
        connect_args="--connect 127.0.0.1:10007"
        ;;
    9009)
        # 9009 connects to 1001 and 7007
        connect_args="--connect 127.0.0.1:10001 --connect 127.0.0.1:10007"
        ;;
    10010)
        # 10010 connects to 9009
        connect_args="--connect 127.0.0.1:10009"
        ;;
    11011)
        # 11011 connects to 9009
        connect_args="--connect 127.0.0.1:10009"
        ;;
    12012)
        # 12012 connects to 10010 and 11011
        connect_args="--connect 127.0.0.1:10010 --connect 127.0.0.1:10011"
        ;;
    13013)
        # 13013 connects to 12012
        connect_args="--connect 127.0.0.1:10012"
        ;;
    14014)
        # 14014 connects to 13013
        connect_args="--connect 127.0.0.1:10013"
        ;;
    15015)
        # 15015 connects to 14014
        connect_args="--connect 127.0.0.1:10014"
        ;;
    16016)
        # 16016 does not connect to anything
        connect_args=""
        ;;
    *)
        echo "Unknown node ID: $node_id"
        exit 1
        ;;
esac

# Start the node
./target/release/mesh --node-id $node_id --listen 0.0.0.0:$listen_port --enable-grpc --grpc-bind 0.0.0.0:$grpc_port --tls --tls-cert certs/node-$node_id.crt --tls-key certs/node-$node_id.key --tls-ca certs/ca.crt $connect_args