# Traefik Configuration for JETKVM Cloud

This directory contains the Traefik reverse proxy configuration for the JETKVM Cloud stack.

## Configuration Files

- `config.yaml` - Main Traefik static configuration
- `dynamic.yaml` - Dynamic configuration for middlewares and HTTP to HTTPS redirects

## Features

- **SSL/TLS Termination**: Automatic SSL certificates via Cloudflare DNS challenge
- **HTTP to HTTPS Redirect**: All HTTP traffic is automatically redirected to HTTPS
- **Security Headers**: Standard security headers are applied to all responses
- **Dashboard Disabled**: Traefik dashboard is disabled for security

## DNS Configuration

The following DNS CNAME records should be configured:

```
jetkvm.jbame.net  -> your-server-ip
jetui.jbame.net   -> your-server-ip  
jetapi.jbame.net  -> your-server-ip
```

## Cloudflare API Token

The Cloudflare API token (`CF_DNS_API_TOKEN`) is configured in the docker-compose.yaml file and requires the following permissions:

- Zone:Zone:Read
- Zone:DNS:Edit

## Endpoints

- **Main Application**: https://jetkvm.jbame.net
- **UI Only**: https://jetui.jbame.net
- **API Only**: https://jetapi.jbame.net
- **Local Development**: https://localhost (self-signed certificate)

## Certificate Storage

SSL certificates are stored in the Docker volume `traefik_data` and will persist across container restarts.
