# JETKVM Cloud - nginx SSL Configuration

This project uses nginx with self-signed certificates for secure local deployment.

## Architecture

- **nginx**: Reverse proxy with SSL termination
- **Self-signed certificate**: For example IP address 192.168.1.3 (configure for your network)
- **Docker Compose**: Container orchestration
- **PostgreSQL**: Database backend

## Prerequisites

⚠️ **Important**: Complete these steps before deployment:

1. **Generate SSL certificates:**
   ```bash
   ./regenerate-cert.sh
   ```

2. **Configure environment variables:**
   - Copy `cloud-api/.env.example` to `cloud-api/.env`
   - Update all placeholder values with your secure credentials
   - Update IP addresses to match your network configuration

## Quick Start

1. **Generate SSL certificates:**
   ```bash
   ./regenerate-cert.sh
   ```

2. **Start the stack:**
   ```bash
   ./manage-stack.sh up
   ```

3. **Access the application:**
   - Main interface: https://192.168.1.3
   - API endpoints: https://192.168.1.3/api

4. **Accept the certificate warning** in your browser (one-time setup)

## SSL Certificate

The system uses a self-signed certificate for your local IP address. This provides encryption but will show a certificate warning in browsers.

### Certificate Details
- **Subject**: CN=192.168.1.3 (example)
- **SAN**: IP:192.168.1.3, DNS:localhost
- **Validity**: 365 days from generation

### Regenerate Certificate
```bash
./regenerate-cert.sh
```

## Management Commands

```bash
# Start the stack
./manage-stack.sh up

# Stop the stack
./manage-stack.sh down

# Restart the stack
./manage-stack.sh restart

# Show status
./manage-stack.sh status

# Show certificate info
./manage-stack.sh cert

# Test endpoints
./manage-stack.sh test

# Show logs
./manage-stack.sh logs [service]
```

## JetKVM Device Configuration

Configure your JetKVM devices with:
- **Cloud API Base URL**: `https://192.168.1.3/api`
- **Cloud Frontend URL**: `https://192.168.1.3`

## nginx Configuration

The nginx configuration handles:
- HTTP to HTTPS redirects
- SSL termination
- API routing (`/api/*` → API container)
- Frontend routing (`/*` → Frontend container)
- Security headers
- Gzip compression

## File Structure

```
jetkvm-cloud/
├── docker-compose.yaml          # Docker stack definition
├── manage-stack.sh              # Management script
├── regenerate-cert.sh           # Certificate generation (run first!)
├── nginx/
│   ├── nginx.conf              # nginx configuration
│   └── ssl/
│       ├── server.crt          # SSL certificate (generated)
│       └── server.key          # SSL private key (generated)
├── cloud-api/                  # API source code
└── postgres/                   # Database data
```

## Environment Variables

The stack is configured for local IP-based access:
- `API_HOSTNAME=https://192.168.1.3`
- `APP_HOSTNAME=https://192.168.1.3`
- `CORS_ORIGINS=https://192.168.1.3,...`

## Security Notes

- Uses self-signed certificates (shows browser warnings)
- Includes standard security headers
- HTTP automatically redirects to HTTPS
- Certificate valid for IP and localhost access

## Troubleshooting

### Certificate Warnings
This is expected with self-signed certificates. Click "Advanced" → "Proceed to 10.0.0.14" in your browser.

### Certificate Regeneration
If you need a new certificate:
```bash
./regenerate-cert.sh
./manage-stack.sh restart
```

### Service Health
Check container health:
```bash
./manage-stack.sh status
```

### Logs
View service logs:
```bash
./manage-stack.sh logs          # All services
./manage-stack.sh logs nginx    # nginx only
./manage-stack.sh logs api      # API only
```
