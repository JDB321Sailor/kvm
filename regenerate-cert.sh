#!/bin/bash

# Certificate Regeneration Script for JETKVM Cloud

# Load environment variables if .env file exists
if [ -f "cloud-api/.env" ]; then
    export $(grep -v '^#' cloud-api/.env | grep -v '^$' | xargs)
fi

# Default IP if not set in environment
LOCAL_IP=${LOCAL_IP:-192.168.1.3}

echo "🔐 Regenerating self-signed certificate for $LOCAL_IP..."

# Create ssl directory if it doesn't exist
mkdir -p nginx/ssl

# Generate new certificate
cd nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout server.key \
    -out server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$LOCAL_IP" \
    -addext "subjectAltName=IP:$LOCAL_IP,DNS:localhost"

echo "✅ Certificate generated successfully!"
echo ""
echo "📄 Certificate details:"
openssl x509 -in server.crt -noout -subject -dates
echo ""
echo "🔄 Restart the stack to use the new certificate:"
echo "   ./manage-stack.sh restart"
