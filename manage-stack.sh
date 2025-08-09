#!/bin/bash

# JETKVM Cloud Stack Management Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "${1:-help}" in
    "up"|"start")
        echo "🚀 Starting JETKVM Cloud Stack..."
        docker-compose up -d
        echo ""
        echo "✅ Stack started successfully!"
        echo ""
        echo "🌐 Services available at:"
        echo "  • Frontend UI:     https://localhost (via Traefik)"
        echo "  • Production UI:   https://jetui.jbame.net"
        echo "  • Production API:  https://jetapi.jbame.net"
        echo "  • Main Domain:     https://jetkvm.jbame.net"
        echo "  • Database:        postgres://jetkvm:***@localhost:5432/jetkvm"
        echo ""
        echo "📊 To check status: ./manage-stack.sh status"
        echo "🛑 To stop:        ./manage-stack.sh down"
        ;;
    
    "down"|"stop")
        echo "🛑 Stopping JETKVM Cloud Stack..."
        docker-compose down
        echo "✅ Stack stopped successfully!"
        ;;
    
    "restart")
        echo "🔄 Restarting JETKVM Cloud Stack..."
        docker-compose down
        docker-compose up -d
        echo "✅ Stack restarted successfully!"
        ;;
    
    "status")
        echo "📊 JETKVM Cloud Stack Status:"
        echo ""
        docker-compose ps
        echo ""
        echo "🔍 Service Health:"
        for service in traefik postgres api frontend; do
            health=$(docker inspect --format='{{.State.Health.Status}}' jetkvm-$service 2>/dev/null || echo "no-healthcheck")
            case $health in
                "healthy") echo "  ✅ $service: healthy" ;;
                "unhealthy") echo "  ❌ $service: unhealthy" ;;
                "starting") echo "  🟡 $service: starting" ;;
                "no-healthcheck") echo "  ⚪ $service: running (no healthcheck)" ;;
                *) echo "  ❓ $service: $health" ;;
            esac
        done
        ;;
    
    "logs")
        service="${2:-}"
        if [ -n "$service" ]; then
            echo "📋 Logs for $service:"
            docker-compose logs -f "$service"
        else
            echo "📋 All service logs:"
            docker-compose logs -f
        fi
        ;;
    
    "build")
        echo "🔨 Building Docker images..."
        echo "  Building API..."
        (cd cloud-api && ./build-docker.sh)
        echo "  Building UI..."
        (cd kvm/ui && ./build-docker.sh)
        echo "✅ All images built successfully!"
        ;;
    
    "clean")
        echo "🧹 Cleaning up JETKVM Cloud Stack..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        echo "✅ Cleanup completed!"
        ;;
    
    "test")
        echo "🧪 Testing JETKVM Cloud Stack endpoints..."
        echo ""
        
        # Test Traefik HTTPS Frontend
        frontend_https_status=$(curl -s -w "%{http_code}" -o /dev/null -k https://localhost/ 2>/dev/null || echo "000")
        if [ "$frontend_https_status" = "200" ]; then
            echo "  ✅ Frontend UI (HTTPS): https://localhost (Status: $frontend_https_status)"
        else
            echo "  ❌ Frontend UI (HTTPS): https://localhost (Status: $frontend_https_status)"
        fi
        
        # Test Traefik HTTPS API  
        api_https_status=$(curl -s -w "%{http_code}" -o /dev/null -k https://localhost/api/ 2>/dev/null || echo "000")
        if [ "$api_https_status" = "200" ]; then
            echo "  ✅ API Server (HTTPS): https://localhost/api (Status: $api_https_status)"
        else
            echo "  ❌ API Server (HTTPS): https://localhost/api (Status: $api_https_status)"
        fi
        
        # Test Traefik ping endpoint
        ping_status=$(curl -s -w "%{http_code}" -o /dev/null http://localhost/ping 2>/dev/null || echo "000")
        if [ "$ping_status" = "200" ]; then
            echo "  ✅ Traefik Ping: http://localhost/ping (Status: $ping_status)"
        else
            echo "  ❌ Traefik Ping: http://localhost/ping (Status: $ping_status)"
        fi
        
        echo ""
        if [ "$frontend_https_status" = "200" ] && [ "$api_https_status" = "200" ] && [ "$ping_status" = "200" ]; then
            echo "🎉 All local tests passed! JETKVM Cloud Stack with Traefik is working correctly."
            echo ""
            echo "🌐 Testing production endpoints (with Let's Encrypt certificates):"
            
            # Test production endpoints
            prod_main_status=$(curl -s -w "%{http_code}" -o /dev/null https://jetkvm.jbame.net/ 2>/dev/null || echo "000")
            prod_ui_status=$(curl -s -w "%{http_code}" -o /dev/null https://jetui.jbame.net/ 2>/dev/null || echo "000")
            prod_api_status=$(curl -s -w "%{http_code}" -o /dev/null https://jetapi.jbame.net/ 2>/dev/null || echo "000")
            
            if [ "$prod_main_status" = "200" ]; then
                echo "  ✅ Main Application: https://jetkvm.jbame.net (Status: $prod_main_status)"
            else
                echo "  ❌ Main Application: https://jetkvm.jbame.net (Status: $prod_main_status)"
            fi
            
            if [ "$prod_ui_status" = "200" ]; then
                echo "  ✅ UI Interface: https://jetui.jbame.net (Status: $prod_ui_status)"
            else
                echo "  ❌ UI Interface: https://jetui.jbame.net (Status: $prod_ui_status)"
            fi
            
            if [ "$prod_api_status" = "200" ]; then
                echo "  ✅ API Endpoint: https://jetapi.jbame.net (Status: $prod_api_status)"
            else
                echo "  ❌ API Endpoint: https://jetapi.jbame.net (Status: $prod_api_status)"
            fi
        else
            echo "⚠️  Some tests failed. Check service logs with: ./manage-stack.sh logs"
        fi
        ;;
    
    "certs")
        echo "🔒 Certificate Status:"
        echo ""
        echo "📁 ACME Certificate Storage:"
        docker exec jetkvm-traefik ls -la /data/ 2>/dev/null || echo "  ❌ Cannot access certificate storage"
        echo ""
        echo "🌐 Production Certificate Details:"
        for domain in jetkvm.jbame.net jetui.jbame.net jetapi.jbame.net; do
            cert_info=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo "  ✅ $domain:"
                echo "     $(echo "$cert_info" | grep subject)"
                echo "     $(echo "$cert_info" | grep issuer)"
                echo "     $(echo "$cert_info" | grep notAfter)"
            else
                echo "  ❌ $domain: Certificate check failed"
            fi
        done
        echo ""
        echo "📋 Recent ACME/Certificate logs:"
        docker logs jetkvm-traefik | grep -E "(acme|certificate|cloudflare)" | tail -10
        ;;

    "help"|*)
        echo "JETKVM Cloud Stack Management"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  up|start    - Start the stack"
        echo "  down|stop   - Stop the stack"
        echo "  restart     - Restart the stack"
        echo "  status      - Show stack status"
        echo "  logs [svc]  - Show logs (optionally for specific service)"
        echo "  test        - Test all endpoints"
        echo "  certs       - Check certificate status"
        echo "  build       - Build all Docker images"
        echo "  clean       - Stop and clean up everything"
        echo "  help        - Show this help"
        echo ""
        echo "Services: traefik, postgres, api, frontend"
        ;;
esac
