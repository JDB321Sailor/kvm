#!/bin/bash

# JETKVM Cloud Stack Management Script
# nginx-based deployment with self-signed certificates

set -e

show_help() {
    echo "JETKVM Cloud Stack Management"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  up        Start the stack"
    echo "  down      Stop the stack"
    echo "  restart   Restart the stack"
    echo "  logs      Show logs"
    echo "  status    Show container status"
    echo "  cert      Show certificate information"
    echo "  test      Test HTTPS endpoints"
    echo "  help      Show this help"
    echo ""
}

start_stack() {
    echo "🚀 Starting JETKVM Cloud Stack (nginx with self-signed SSL)..."
    docker-compose up -d
    echo "✅ Stack started"
    echo ""
    echo "🌐 Access your JETKVM Cloud at:"
    echo "   https://192.168.1.3 (main interface)"
    echo "   https://192.168.1.3/api (API endpoints)"
    echo ""
    echo "⚠️  Note: You may need to accept the self-signed certificate"
}

stop_stack() {
    echo "🛑 Stopping JETKVM Cloud Stack..."
    docker-compose down
    echo "✅ Stack stopped"
}

restart_stack() {
    echo "🔄 Restarting JETKVM Cloud Stack..."
    docker-compose down
    docker-compose up -d
    echo "✅ Stack restarted"
}

show_logs() {
    if [ -n "$2" ]; then
        docker-compose logs -f "$2"
    else
        docker-compose logs -f
    fi
}

show_status() {
    echo "📊 Container Status:"
    docker-compose ps
    echo ""
    echo "🏥 Health Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
}

show_cert() {
    echo "🔒 SSL Certificate Information:"
    echo ""
    if [ -f "/home/jbame/jetkvm-cloud/nginx/ssl/server.crt" ]; then
        echo "📄 Certificate Details:"
        openssl x509 -in /home/jbame/jetkvm-cloud/nginx/ssl/server.crt -text -noout | grep -E "(Subject:|Issuer:|Not Before|Not After|Subject Alternative Name)" | sed 's/^[[:space:]]*/  /'
        echo ""
        echo "🔍 Certificate Validity:"
        openssl x509 -in /home/jbame/jetkvm-cloud/nginx/ssl/server.crt -noout -dates | sed 's/^/  /'
    else
        echo "❌ Certificate file not found at nginx/ssl/server.crt"
        echo "   Run: ./regenerate-cert.sh to create a new certificate"
    fi
}

test_endpoints() {
    echo "🧪 Testing HTTPS Endpoints:"
    echo ""
    
    # Test main interface
    echo "🌐 Testing main interface (https://192.168.1.3):"
    if curl -k -s -o /dev/null -w "%{http_code}" https://192.168.1.3 | grep -q "200"; then
        echo "  ✅ Main interface: OK"
    else
        echo "  ❌ Main interface: Failed"
    fi
    
    # Test API health
    echo "🔌 Testing API health (https://192.168.1.3/api/):"
    if curl -k -L -s -o /dev/null -w "%{http_code}" https://192.168.1.3/api/ | grep -q "200"; then
        echo "  ✅ API health: OK"
    else
        echo "  ❌ API health: Failed"
    fi
    
    echo ""
    echo "ℹ️  Note: Using -k flag to ignore self-signed certificate warnings"
}

case "${1:-help}" in
    "up"|"start")
        start_stack
        ;;
    "down"|"stop")
        stop_stack
        ;;
    "restart")
        restart_stack
        ;;
    "logs")
        show_logs "$@"
        ;;
    "status")
        show_status
        ;;
    "cert")
        show_cert
        ;;
    "test")
        test_endpoints
        ;;
    "help"|*)
        show_help
        ;;
esac
