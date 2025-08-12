# JETKVM Cloud - nginx SSL Configuration

This project uses nginx with self-signed certificates for secure local deployment with configurable IP addressing.

> **Important**: This deployment is designed to work by using environment variables for IP configuration.

## Architecture

- **nginx**: Reverse proxy with SSL termination
- **Self-signed certificate**: Generated for your configured LOCAL_IP address
- **Docker Compose**: Container orchestration with environment variable support
- **PostgreSQL**: Database backend

## Prerequisites

⚠️ **Important**: Complete these steps before deployment:

1. **Configure environment variables:**
   - Copy `cloud-api/.env.example` to `cloud-api/.env`
   - Set `LOCAL_IP` to your machine's IP address (e.g., `LOCAL_IP=192.168.1.100`)
   - Update all placeholder values with your secure credentials

2. **Build Docker images:**
   ```bash
   ./manage-stack.sh build
   ```

3. **Generate SSL certificates:**
   ```bash
   ./regenerate-cert.sh
   ```

## Quick Start

1. **Configure environment:**
   ```bash
   # Copy environment template
   cp cloud-api/.env.example cloud-api/.env
   
   # Edit .env file to set your LOCAL_IP
   nano cloud-api/.env  # Set LOCAL_IP=YOUR_ACTUAL_IP
   ```

2. **Build Docker images:**
   ```bash
   ./manage-stack.sh build
   ```

3. **Generate SSL certificates:**
   ```bash
   ./regenerate-cert.sh
   ```

4. **Start the stack:**
   ```bash
   ./manage-stack.sh up
   ```

5. **Access the application:**
   - Main interface: https://YOUR_LOCAL_IP
   - API endpoints: https://YOUR_LOCAL_IP/api

6. **Accept the certificate warning** in your browser (one-time setup)

## SSL Certificate

The system uses a self-signed certificate for your configured LOCAL_IP address. This provides encryption but will show a certificate warning in browsers.

### Certificate Details
- **Subject**: CN=YOUR_LOCAL_IP (dynamically generated)
- **SAN**: IP:YOUR_LOCAL_IP, DNS:localhost
- **Validity**: 365 days from generation

### Regenerate Certificate
```bash
./regenerate-cert.sh
```

## Management Commands

```bash
# Build Docker images (required before first run)
./manage-stack.sh build

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

Configure your JetKVM devices with your LOCAL_IP address:
- **Cloud API Base URL**: `https://YOUR_LOCAL_IP/api`
- **Cloud Frontend URL**: `https://YOUR_LOCAL_IP`

(Replace YOUR_LOCAL_IP with the IP address you configured in `.env`)

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

The stack uses environment variable substitution for flexible IP configuration:
- Copy `cloud-api/.env.example` to `cloud-api/.env`
- Set `LOCAL_IP=YOUR_ACTUAL_IP` in the `.env` file
- All services will automatically use your configured IP address

## Security Notes

- Uses self-signed certificates (shows browser warnings)
- Includes standard security headers
- HTTP automatically redirects to HTTPS
- Certificate valid for IP and localhost access

## Troubleshooting

### Certificate Warnings
This is expected with self-signed certificates. Click "Advanced" → "Proceed to YOUR_LOCAL_IP" in your browser.

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
