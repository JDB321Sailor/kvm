#!/bin/bash

# Certificate Regeneration Script for JETKVM Cloud

echo "🔐 Regenerating self-signed certificate for 10.0.0.14..."

# Create ssl directory if it doesn't exist
mkdir -p nginx/ssl

# Generate new certificate
cd nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout server.key \
    -out server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=10.0.0.14" \
    -addext "subjectAltName=IP:10.0.0.14,DNS:localhost"

echo "✅ Certificate generated successfully!"
echo ""
echo "📄 Certificate details:"
openssl x509 -in server.crt -noout -subject -dates
echo ""
echo "🔄 Restart the stack to use the new certificate:"
echo "   ./manage-stack.sh restart"
