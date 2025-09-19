#!/bin/bash

# Generate test certificates with localhost CN for mesh TLS testing

set -e

CERT_DIR="certs"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

echo "=== Generating Localhost Test Certificates for Mesh TLS ==="
echo

# Generate CA private key and certificate
echo "1. Generating CA certificate..."
openssl req -x509 -new -nodes -days 3650 -subj "/CN=mesh-ca" \
    -keyout ca.key -out ca.crt

echo "   CA certificate generated: ca.crt, ca.key"
echo

# Function to generate node certificate with localhost CN
generate_node_cert() {
    local node_id=$1
    local node_name="node-$node_id"
    
    echo "2. Generating certificate for node $node_id with localhost CN..."
    
    # Create extension file with SAN URI and DNS
    cat > "${node_name}.ext" << EOF
subjectAltName = URI:mesh://node/$node_id,DNS:localhost,IP:127.0.0.1
EOF
    
    # Generate private key and CSR with localhost CN
    openssl req -new -nodes -subj "/CN=localhost" \
        -keyout "${node_name}.key" -out "${node_name}.csr"
    
    # Sign the certificate with CA
    openssl x509 -req -in "${node_name}.csr" -CA ca.crt -CAkey ca.key -CAcreateserial \
        -days 825 -out "${node_name}.crt" -extfile "${node_name}.ext"
    
    # Clean up CSR and extension file
    rm "${node_name}.csr" "${node_name}.ext"
    
    echo "   Node $node_id certificate generated: ${node_name}.crt, ${node_name}.key"
}

# Generate certificates for test nodes
generate_node_cert 1001
generate_node_cert 2002
generate_node_cert 3003
generate_node_cert 4004
generate_node_cert 5005
generate_node_cert 6006
generate_node_cert 7007
generate_node_cert 8008
generate_node_cert 9009
generate_node_cert 10010
generate_node_cert 11011
generate_node_cert 12012
generate_node_cert 13013
generate_node_cert 14014
generate_node_cert 15015
generate_node_cert 16016

echo
echo "=== Certificate Generation Complete ==="
echo
echo "Files generated in $CERT_DIR/:"
ls -la
echo
echo "Certificate details:"
echo "Node 1001 certificate:"
openssl x509 -in node-1001.crt -text -noout | grep -A 3 "Subject:"
echo "Node 2002 certificate:"
openssl x509 -in node-2002.crt -text -noout | grep -A 3 "Subject:"
echo "Node 3003 certificate:"
openssl x509 -in node-3003.crt -text -noout | grep -A 3 "Subject:"
echo "Node 4004 certificate:"
openssl x509 -in node-4004.crt -text -noout | grep -A 3 "Subject:"
echo "Node 5005 certificate:"
openssl x509 -in node-5005.crt -text -noout | grep -A 3 "Subject:"
echo "Node 6006 certificate:"
openssl x509 -in node-6006.crt -text -noout | grep -A 3 "Subject:"
echo "Node 7007 certificate:"
openssl x509 -in node-7007.crt -text -noout | grep -A 3 "Subject:"
echo "Node 8008 certificate:"
openssl x509 -in node-8008.crt -text -noout | grep -A 3 "Subject:"
echo "Node 9009 certificate:"
openssl x509 -in node-9009.crt -text -noout | grep -A 3 "Subject:"
echo "Node 10010 certificate:"
openssl x509 -in node-10010.crt -text -noout | grep -A 3 "Subject:"
echo "Node 11011 certificate:"
openssl x509 -in node-11011.crt -text -noout | grep -A 3 "Subject:"
echo "Node 12012 certificate:"
openssl x509 -in node-12012.crt -text -noout | grep -A 3 "Subject:"
echo "Node 13013 certificate:"
openssl x509 -in node-13013.crt -text -noout | grep -A 3 "Subject:"
echo "Node 14014 certificate:"
openssl x509 -in node-14014.crt -text -noout | grep -A 3 "Subject:"
echo "Node 15015 certificate:"
openssl x509 -in node-15015.crt -text -noout | grep -A 3 "Subject:"
echo "Node 16016 certificate:"
openssl x509 -in node-16016.crt -text -noout | grep -A 3 "Subject:"