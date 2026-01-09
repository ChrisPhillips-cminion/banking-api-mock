# Podman Deployment Guide

This guide provides instructions for building and running the Banking API Mock using Podman instead of Docker.

## Prerequisites

- **Podman**: v3.0.0 or higher
- **Podman Compose**: v1.0.0 or higher (optional)

## Quick Start with Podman

### Build the Image

```bash
podman build -t banking-api-mock:latest .
```

### Run the Container

```bash
podman run -d \
  --name banking-api-mock \
  -p 3000:3000 \
  banking-api-mock:latest
```

### Check Container Status

```bash
podman ps
podman logs banking-api-mock
```

### Stop and Remove Container

```bash
podman stop banking-api-mock
podman rm banking-api-mock
```

## Using Podman Compose

Podman Compose is compatible with Docker Compose files. You can use the existing `docker-compose.yml`:

### Start Services

```bash
podman-compose up -d
```

### View Logs

```bash
podman-compose logs -f
```

### Stop Services

```bash
podman-compose down
```

### Rebuild and Restart

```bash
podman-compose up -d --build
```

## Rootless Podman

Podman can run containers without root privileges. This is the default behavior:

```bash
# Build as regular user
podman build -t banking-api-mock:latest .

# Run as regular user
podman run -d \
  --name banking-api-mock \
  -p 3000:3000 \
  banking-api-mock:latest
```

## Podman Pod (Alternative to Docker Compose)

Create a pod for the banking API:

```bash
# Create a pod
podman pod create --name banking-pod -p 3000:3000

# Run container in the pod
podman run -d \
  --pod banking-pod \
  --name banking-api-mock \
  banking-api-mock:latest

# Check pod status
podman pod ps
podman pod logs banking-pod

# Stop and remove pod
podman pod stop banking-pod
podman pod rm banking-pod
```

## Multi-Platform Builds

```bash
# For AMD64 (Intel/AMD)
podman build --platform linux/amd64 -t banking-api-mock:amd64 .

# For ARM64 (Apple Silicon, ARM servers)
podman build --platform linux/arm64 -t banking-api-mock:arm64 .

# Multi-arch manifest (requires buildah)
podman manifest create banking-api-mock:latest
podman build --platform linux/amd64 --manifest banking-api-mock:latest .
podman build --platform linux/arm64 --manifest banking-api-mock:latest .
```

## Push to Registry

```bash
# Tag the image
podman tag banking-api-mock:latest your-registry.com/banking-api-mock:1.0.0

# Login to registry
podman login your-registry.com

# Push to registry
podman push your-registry.com/banking-api-mock:1.0.0
```

## Save and Load Images

```bash
# Save image to tar file
podman save banking-api-mock:latest -o banking-api-mock.tar

# Load image from tar file
podman load -i banking-api-mock.tar
```

## Systemd Integration

Generate a systemd service file for automatic startup:

```bash
# Generate systemd unit file
podman generate systemd --new --name banking-api-mock > ~/.config/systemd/user/banking-api-mock.service

# Enable and start service
systemctl --user enable banking-api-mock.service
systemctl --user start banking-api-mock.service

# Check status
systemctl --user status banking-api-mock.service

# View logs
journalctl --user -u banking-api-mock.service -f
```

## Kubernetes with Podman

Generate Kubernetes YAML from running container:

```bash
# Start the container
podman run -d --name banking-api-mock -p 3000:3000 banking-api-mock:latest

# Generate Kubernetes YAML
podman generate kube banking-api-mock > banking-api-k8s.yaml

# Deploy to Kubernetes
kubectl apply -f banking-api-k8s.yaml
```

## Podman vs Docker Commands

| Docker Command | Podman Equivalent |
|----------------|-------------------|
| `docker build` | `podman build` |
| `docker run` | `podman run` |
| `docker ps` | `podman ps` |
| `docker images` | `podman images` |
| `docker logs` | `podman logs` |
| `docker exec` | `podman exec` |
| `docker stop` | `podman stop` |
| `docker rm` | `podman rm` |
| `docker-compose` | `podman-compose` |

## Troubleshooting

### Port Permission Issues (Rootless)

If you encounter permission issues with ports below 1024:

```bash
# Use a higher port
podman run -d -p 8080:3000 banking-api-mock:latest

# Or enable rootless port binding
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee /etc/sysctl.d/99-rootless.conf
sudo sysctl --system
```

### SELinux Issues

If you encounter SELinux-related issues:

```bash
# Add :Z flag for volume mounts
podman run -d -v ./data:/app/data:Z banking-api-mock:latest

# Or temporarily disable SELinux (not recommended for production)
sudo setenforce 0
```

### Container Won't Start

```bash
# Check container logs
podman logs banking-api-mock

# Inspect container
podman inspect banking-api-mock

# Check events
podman events --since 1h
```

## Performance Tuning

### Resource Limits

```bash
podman run -d \
  --name banking-api-mock \
  --memory=512m \
  --cpus=1.0 \
  -p 3000:3000 \
  banking-api-mock:latest
```

### Health Check

```bash
podman run -d \
  --name banking-api-mock \
  --health-cmd='curl -f http://localhost:3000/health || exit 1' \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  -p 3000:3000 \
  banking-api-mock:latest
```

## Complete Example

Here's a complete example of building and running with Podman:

```bash
# 1. Build the image
podman build -t banking-api-mock:latest .

# 2. Run the container with all options
podman run -d \
  --name banking-api-mock \
  --restart=unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=production \
  --memory=512m \
  --cpus=1.0 \
  --health-cmd='curl -f http://localhost:3000/health || exit 1' \
  --health-interval=30s \
  banking-api-mock:latest

# 3. Verify it's running
podman ps
curl http://localhost:3000/health

# 4. View logs
podman logs -f banking-api-mock

# 5. Test the API
curl -H "Authorization: Bearer test-token-1234567890" \
  http://localhost:3000/accounts
```

## Additional Resources

- [Podman Documentation](https://docs.podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)
- [Podman vs Docker](https://docs.podman.io/en/latest/markdown/podman.1.html)