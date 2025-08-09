# JetKVM Cloud Setup

This is a simplified deployment setup using nginx as a reverse proxy with self-signed SSL certificates.

## Stack Components

- **nginx**: Reverse proxy with SSL termination  
- **PostgreSQL**: Database
- **API**: Node.js/TypeScript backend
- **Frontend**: React/Vite frontend

## Prerequisites

- Docker and Docker Compose installed
- Built Docker images for the API and UI components

## Quick Start

1. **Copy environment files:**
   ```bash
   cp kvm/.env.example kvm/.env
   cp cloud-api/.env.example cloud-api/.env
   ```

2. **Configure environment variables:**
   - Edit `kvm/.env` and `cloud-api/.env` with your specific values
   - Update hostnames to match your server IP address (currently configured for 10.0.0.14)

3. **Generate session secrets:**
   ```bash
   openssl rand -base64 32
   ```
   Use this value for `COOKIE_SECRET` in both .env files

4. **Set up Google OAuth (optional):**
   - Create a project in Google Cloud Console
   - Enable Google+ API  
   - Create OAuth 2.0 credentials
   - Add redirect URIs: `https://YOUR_IP_ADDRESS/api/oidc/callback`
   - Update `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in .env files

5. **Deploy the stack:**
   ```bash
   ./manage-stack-simple.sh up
   ```

6. **Access the application:**
   - **Web interface**: https://YOUR_IP_ADDRESS
   - **API**: https://YOUR_IP_ADDRESS/api

## SSL Certificates

The stack uses self-signed SSL certificates generated automatically. For production use, consider:
- Let's Encrypt certificates
- Proper domain name with DNS  
- Certificate authority signed certificates

## Management Commands

Use the `manage-stack-simple.sh` script:

```bash
# Start the stack
./manage-stack-simple.sh up

# Stop the stack  
./manage-stack-simple.sh down

# Restart the stack
./manage-stack-simple.sh restart

# View logs (all services)
./manage-stack-simple.sh logs

# View logs for specific service
./manage-stack-simple.sh logs api
./manage-stack-simple.sh logs frontend  
./manage-stack-simple.sh logs postgres
./manage-stack-simple.sh logs nginx

# Check service status
./manage-stack-simple.sh status
```

## Security Notes

- `.env` files are ignored by git and contain sensitive information
- Change default passwords and secrets before production use
- Self-signed certificates will show security warnings in browsers
- Consider proper SSL certificates for production deployments

## Troubleshooting

### Services not starting
1. Check if required ports are available (80, 443, 5432)
2. Ensure Docker images are built correctly
3. Check logs: `./manage-stack-simple.sh logs [service]`

### SSL Certificate Issues  
1. Certificates are generated automatically on first run
2. If you see SSL errors, try: `./manage-stack-simple.sh restart`
3. Check nginx logs: `./manage-stack-simple.sh logs nginx`

### Google OAuth Issues
1. Update redirect URI in Google Cloud Console to `https://YOUR_IP_ADDRESS/api/oidc/callback`
2. Ensure `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are set in .env files
3. Check that hostnames in .env match your actual IP address
