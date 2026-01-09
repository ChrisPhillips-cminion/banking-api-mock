# Banking API Mock Server

A comprehensive mock banking API server that implements the Banking Services API specification. This mock server is designed for testing and development purposes, particularly for integration with IBM API Connect v10.

## Features

- ✅ Full implementation of Banking Services API v1.0.0
- ✅ Account management and balance inquiries
- ✅ Transaction history and search
- ✅ Payment creation and management
- ✅ Beneficiary management (CRUD operations)
- ✅ Statement generation and download
- ✅ Mock authentication (OAuth 2.0 simulation)
- ✅ Interactive API documentation (Swagger UI)
- ✅ Docker containerization
- ✅ Health check endpoint
- ✅ Request logging and correlation IDs
- ✅ Comprehensive error handling

## Prerequisites

- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher
- **Podman**: v3.0.0 or higher (recommended for containerized deployment)
- **Podman Compose**: v1.0.0 or higher (optional, for easy deployment)
- **Docker**: v20.0.0 or higher (alternative to Podman)
- **Docker Compose**: v2.0.0 or higher (alternative to Podman Compose)

> **Note**: This project supports both Podman and Docker. See [PODMAN.md](PODMAN.md) for Podman-specific instructions.

## Quick Start

### Option 1: Run Locally with Node.js

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start the server:**
   ```bash
   npm start
   ```

3. **For development with auto-reload:**
   ```bash
   npm run dev
   ```

4. **Access the API:**
   - API Base URL: `http://localhost:3000`
   - API Documentation: `http://localhost:3000/api-docs`
   - Health Check: `http://localhost:3000/health`

### Option 2: Run with Podman (Recommended)

See [PODMAN.md](PODMAN.md) for complete Podman documentation.

#### Build and Run with Podman

1. **Build the image:**
   ```bash
   podman build -t banking-api-mock:latest .
   ```

2. **Run the container:**
   ```bash
   podman run -d \
     --name banking-api-mock \
     -p 3000:3000 \
     banking-api-mock:latest
   ```

3. **Check container status:**
   ```bash
   podman ps
   podman logs banking-api-mock
   ```

4. **Stop the container:**
   ```bash
   podman stop banking-api-mock
   podman rm banking-api-mock
   ```

#### Build and Run with Podman Compose (Recommended)

1. **Start the service:**
   ```bash
   podman-compose up -d
   ```

2. **View logs:**
   ```bash
   podman-compose logs -f
   ```

3. **Stop the service:**
   ```bash
   podman-compose down
   ```

4. **Rebuild and restart:**
   ```bash
   podman-compose up -d --build
   ```

### Option 3: Run with Docker

#### Build and Run with Docker

1. **Build the Docker image:**
   ```bash
   docker build -t banking-api-mock:latest .
   ```

2. **Run the container:**
   ```bash
   docker run -d \
     --name banking-api-mock \
     -p 3000:3000 \
     banking-api-mock:latest
   ```

3. **Check container status:**
   ```bash
   docker ps
   docker logs banking-api-mock
   ```

4. **Stop the container:**
   ```bash
   docker stop banking-api-mock
   docker rm banking-api-mock
   ```

#### Build and Run with Docker Compose (Recommended)

1. **Start the service:**
   ```bash
   docker-compose up -d
   ```

2. **View logs:**
   ```bash
   docker-compose logs -f
   ```

3. **Stop the service:**
   ```bash
   docker-compose down
   ```

4. **Rebuild and restart:**
   ```bash
   docker-compose up -d --build
   ```

## API Endpoints

### Health Check
- `GET /health` - Health check endpoint (no authentication required)

### Accounts
- `GET /accounts` - List all accounts
- `GET /accounts/{accountId}` - Get account details
- `GET /accounts/{accountId}/balance` - Get account balance
- `GET /accounts/{accountId}/transactions` - Get account transactions
- `GET /accounts/{accountId}/statements` - Get account statements

### Transactions
- `GET /transactions` - List all transactions (with filters)
- `GET /transactions/{transactionId}` - Get transaction details

### Payments
- `POST /payments` - Create a new payment
- `GET /payments/{paymentId}` - Get payment details
- `PUT /payments/{paymentId}/cancel` - Cancel a payment

### Beneficiaries
- `GET /beneficiaries` - List all beneficiaries
- `POST /beneficiaries` - Create a new beneficiary
- `GET /beneficiaries/{beneficiaryId}` - Get beneficiary details
- `PUT /beneficiaries/{beneficiaryId}` - Update beneficiary
- `DELETE /beneficiaries/{beneficiaryId}` - Delete beneficiary

### Statements
- `GET /statements/{statementId}/download` - Download statement (PDF or CSV)

## Authentication

The mock server simulates OAuth 2.0 authentication. For testing purposes, it accepts any valid Bearer token or API key.

### Using Bearer Token
```bash
curl -H "Authorization: Bearer your-test-token-here" \
  http://localhost:3000/accounts
```

### Using API Key
```bash
curl -H "X-API-Key: your-api-key-here" \
  http://localhost:3000/accounts
```

**Note:** For the mock server, any token/key with at least 10 characters will be accepted.

## Example API Calls

### Get Health Status
```bash
curl http://localhost:3000/health
```

### List Accounts
```bash
curl -H "Authorization: Bearer test-token-1234567890" \
  http://localhost:3000/accounts
```

### Get Account Details
```bash
curl -H "Authorization: Bearer test-token-1234567890" \
  http://localhost:3000/accounts/acc-123456789
```

### Create a Payment
```bash
curl -X POST \
  -H "Authorization: Bearer test-token-1234567890" \
  -H "Content-Type: application/json" \
  -d '{
    "fromAccountId": "acc-123456789",
    "toBeneficiaryId": "ben-987654321",
    "amount": 100.00,
    "currency": "GBP",
    "paymentType": "DOMESTIC",
    "reference": "Test payment",
    "scheduledDate": "2024-01-15",
    "urgency": "NORMAL"
  }' \
  http://localhost:3000/payments
```

### List Transactions with Filters
```bash
curl -H "Authorization: Bearer test-token-1234567890" \
  "http://localhost:3000/transactions?page=1&limit=10&transactionType=DEBIT"
```

### Create a Beneficiary
```bash
curl -X POST \
  -H "Authorization: Bearer test-token-1234567890" \
  -H "Content-Type: application/json" \
  -d '{
    "beneficiaryType": "INDIVIDUAL",
    "name": "John Doe",
    "nickname": "John",
    "accountNumber": "12345678",
    "routingNumber": "123456",
    "bankName": "Test Bank",
    "bankAddress": {
      "street": "123 Main St",
      "city": "London",
      "state": "Greater London",
      "postalCode": "SW1A 1AA",
      "country": "GB"
    },
    "email": "john.doe@example.com",
    "phone": "+441234567890"
  }' \
  http://localhost:3000/beneficiaries
```

## Docker Image Management

### Build for Different Platforms
```bash
# For AMD64 (Intel/AMD)
docker build --platform linux/amd64 -t banking-api-mock:amd64 .

# For ARM64 (Apple Silicon, ARM servers)
docker build --platform linux/arm64 -t banking-api-mock:arm64 .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t banking-api-mock:latest .
```

### Tag and Push to Registry
```bash
# Tag the image
docker tag banking-api-mock:latest your-registry.com/banking-api-mock:1.0.0
docker tag banking-api-mock:latest your-registry.com/banking-api-mock:latest

# Push to registry
docker push your-registry.com/banking-api-mock:1.0.0
docker push your-registry.com/banking-api-mock:latest
```

### Save and Load Docker Image
```bash
# Save image to tar file
docker save banking-api-mock:latest -o banking-api-mock.tar

# Load image from tar file
docker load -i banking-api-mock.tar
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3000` | Port number for the server |
| `NODE_ENV` | `development` | Environment mode (development/production) |

### Setting Environment Variables

**Docker:**
```bash
docker run -d \
  -e PORT=8080 \
  -e NODE_ENV=production \
  -p 8080:8080 \
  banking-api-mock:latest
```

**Docker Compose:**
```yaml
environment:
  - PORT=8080
  - NODE_ENV=production
```

## Kubernetes Deployment

### Create Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: banking-api-mock
spec:
  replicas: 3
  selector:
    matchLabels:
      app: banking-api-mock
  template:
    metadata:
      labels:
        app: banking-api-mock
    spec:
      containers:
      - name: banking-api-mock
        image: banking-api-mock:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: banking-api-mock
spec:
  selector:
    app: banking-api-mock
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
```

Apply the configuration:
```bash
kubectl apply -f k8s-deployment.yaml
```

## Monitoring and Logs

### View Docker Logs
```bash
# Follow logs
docker logs -f banking-api-mock

# Last 100 lines
docker logs --tail 100 banking-api-mock

# With timestamps
docker logs -t banking-api-mock
```

### View Docker Compose Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f banking-api-mock

# Last 50 lines
docker-compose logs --tail 50
```

## Troubleshooting

### Container Won't Start
```bash
# Check container status
docker ps -a

# View container logs
docker logs banking-api-mock

# Inspect container
docker inspect banking-api-mock
```

### Port Already in Use
```bash
# Find process using port 3000
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Use different port
docker run -p 8080:3000 banking-api-mock:latest
```

### Health Check Failing
```bash
# Test health endpoint
curl http://localhost:3000/health

# Check container health
docker inspect --format='{{.State.Health.Status}}' banking-api-mock
```

## Development

### Project Structure
```
banking-api-mock/
├── config/
│   └── banking-api-openapi.yaml    # OpenAPI specification
├── src/
│   ├── middleware/
│   │   ├── auth.js                 # Authentication middleware
│   │   ├── errorHandler.js         # Error handling
│   │   └── requestLogger.js        # Request logging
│   ├── routes/
│   │   ├── accounts.js             # Account endpoints
│   │   ├── beneficiaries.js        # Beneficiary endpoints
│   │   ├── health.js               # Health check
│   │   ├── payments.js             # Payment endpoints
│   │   ├── statements.js           # Statement endpoints
│   │   └── transactions.js         # Transaction endpoints
│   ├── utils/
│   │   └── mockData.js             # Mock data generators
│   └── server.js                   # Main server file
├── .dockerignore
├── docker-compose.yml
├── Dockerfile
├── package.json
└── README.md
```

### Adding New Endpoints
1. Create route handler in `src/routes/`
2. Import and register in `src/server.js`
3. Add mock data generator in `src/utils/mockData.js` if needed
4. Update OpenAPI spec in `config/banking-api-openapi.yaml`

## Integration with IBM API Connect v10

This mock server is designed to work as a backend service for IBM API Connect v10:

1. **Deploy the mock server** using Docker or Kubernetes
2. **Configure API Connect** to use the mock server URL as the backend
3. **Import the OpenAPI specification** from `config/banking-api-openapi.yaml`
4. **Test the integration** using the API Connect test tool

## License

Apache 2.0

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/your-org/banking-api-mock/issues)
- Email: api-support@bankingservices.com

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.