# Quick Start Guide

Get the Banking API Mock up and running in minutes!

## Choose Your Method

### 1. Local Development (Node.js)

**Fastest way to get started for development:**

```bash
# Install dependencies
npm install

# Start the server
npm start

# Or with auto-reload for development
npm run dev
```

Access the API at: `http://localhost:3000`

---

### 2. Container with Podman (Recommended)

**Best for production-like environment:**

```bash
# Build the image
podman build -t banking-api-mock:latest .

# Run the container
podman run -d --name banking-api-mock -p 3000:3000 banking-api-mock:latest

# Check it's running
podman ps
curl http://localhost:3000/health
```

**See [PODMAN.md](PODMAN.md) for complete Podman documentation.**

---

### 3. Container with Docker

**If you prefer Docker:**

```bash
# Build the image
docker build -t banking-api-mock:latest .

# Run the container
docker run -d --name banking-api-mock -p 3000:3000 banking-api-mock:latest

# Check it's running
docker ps
curl http://localhost:3000/health
```

---

### 4. Using Compose (Podman or Docker)

**Easiest way with compose:**

```bash
# With Podman Compose
podman-compose up -d

# Or with Docker Compose
docker-compose up -d

# View logs
podman-compose logs -f  # or docker-compose logs -f
```

---

## First API Call

Once the server is running, test it:

```bash
# Health check (no auth required)
curl http://localhost:3000/health

# Get accounts (requires auth token)
curl -H "Authorization: Bearer test-token-1234567890" \
  http://localhost:3000/accounts

# View API documentation
open http://localhost:3000/api-docs
```

---

## What's Next?

- 📖 **Full Documentation**: See [README.md](README.md)
- 🐳 **Podman Guide**: See [PODMAN.md](PODMAN.md)
- 🔍 **API Docs**: Visit `http://localhost:3000/api-docs` when running
- 🧪 **Test Endpoints**: Use the examples in [README.md](README.md#example-api-calls)

---

## Common Issues

### Port 3000 Already in Use?

```bash
# Use a different port
podman run -d -p 8080:3000 banking-api-mock:latest
# or
PORT=8080 npm start
```

### Need to Stop the Server?

```bash
# Local Node.js
Ctrl+C

# Podman
podman stop banking-api-mock

# Docker
docker stop banking-api-mock

# Compose
podman-compose down  # or docker-compose down
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Start locally | `npm start` |
| Build with Podman | `podman build -t banking-api-mock .` |
| Run with Podman | `podman run -d -p 3000:3000 banking-api-mock` |
| View logs (Podman) | `podman logs -f banking-api-mock` |
| Stop (Podman) | `podman stop banking-api-mock` |
| Health check | `curl http://localhost:3000/health` |
| API docs | `http://localhost:3000/api-docs` |

---

## Need Help?

- Check [README.md](README.md) for detailed documentation
- Check [PODMAN.md](PODMAN.md) for Podman-specific instructions
- Review the [Troubleshooting section](README.md#troubleshooting)