# OpenShift Deployment Guide

This guide explains how to build and deploy the Banking API Mock Server on OpenShift Container Platform (OCP).

## Prerequisites

- OpenShift CLI (`oc`) installed and configured
- Access to an OpenShift cluster
- Appropriate permissions to create projects, builds, and deployments

## Quick Start

### 1. Create a New Project

```bash
oc new-project banking-api-mock
```

### 2. Deploy Using the BuildConfig

#### Option A: Build from Git Repository

Update the Git URL in `openshift-buildconfig.yaml` to point to your repository, then apply:

```bash
oc apply -f openshift-buildconfig.yaml
```

#### Option B: Build from Local Source

Create a binary build and upload your local source code:

```bash
# Create the ImageStream
oc create imagestream banking-api-mock

# Create a binary BuildConfig
oc new-build --name=banking-api-mock \
  --binary=true \
  --strategy=docker \
  --to=banking-api-mock:latest

# Start the build from local directory
oc start-build banking-api-mock --from-dir=. --follow

# Deploy the application
oc apply -f openshift-buildconfig.yaml
```

### 3. Monitor the Build

```bash
# Watch build progress
oc logs -f bc/banking-api-mock

# Check build status
oc get builds

# Get detailed build info
oc describe build banking-api-mock-1
```

### 4. Verify Deployment

```bash
# Check deployment status
oc get deployment banking-api-mock

# Check pods
oc get pods -l app=banking-api-mock

# View pod logs
oc logs -f deployment/banking-api-mock

# Check service
oc get svc banking-api-mock

# Get route URL
oc get route banking-api-mock
```

### 5. Access the Application

```bash
# Get the route URL
ROUTE_URL=$(oc get route banking-api-mock -o jsonpath='{.spec.host}')

# Test the health endpoint
curl https://$ROUTE_URL/health

# Access API documentation
echo "API Docs: https://$ROUTE_URL/api-docs"
```

## BuildConfig Details

The `openshift-buildconfig.yaml` file includes:

1. **ImageStream**: Stores the built container images
2. **BuildConfig**: Defines how to build the container from source
3. **Deployment**: Manages the application pods
4. **Service**: Exposes the application within the cluster
5. **Route**: Provides external access with TLS termination

### Build Strategy

The BuildConfig uses a **Docker strategy** which:
- Uses the `Dockerfile` in the repository root
- Builds from the `node:18-alpine` base image
- Follows the multi-stage build process defined in the Dockerfile

### Triggers

The build is triggered automatically by:
- **ConfigChange**: When the BuildConfig is created or updated
- **ImageChange**: When the base image (node:18-alpine) is updated

## Configuration Options

### Update Git Repository

Edit the BuildConfig to point to your Git repository:

```bash
oc edit bc/banking-api-mock
```

Update the `source.git.uri` field:
```yaml
source:
  type: Git
  git:
    uri: https://github.com/your-org/banking-api-mock.git
    ref: main
```

### Environment Variables

Add or modify environment variables in the Deployment:

```bash
oc set env deployment/banking-api-mock \
  NODE_ENV=production \
  PORT=3000 \
  LOG_LEVEL=info
```

### Scaling

Scale the number of replicas:

```bash
# Scale up
oc scale deployment/banking-api-mock --replicas=3

# Scale down
oc scale deployment/banking-api-mock --replicas=1
```

### Resource Limits

Update resource requests and limits:

```bash
oc set resources deployment/banking-api-mock \
  --requests=cpu=200m,memory=256Mi \
  --limits=cpu=1000m,memory=1Gi
```

## Build from Different Sources

### Build from GitHub

```bash
oc new-build https://github.com/your-org/banking-api-mock.git \
  --name=banking-api-mock \
  --strategy=docker
```

### Build from Local Directory

```bash
oc start-build banking-api-mock --from-dir=. --follow
```

### Build from Dockerfile

```bash
oc new-build --name=banking-api-mock \
  --dockerfile=$'FROM node:18-alpine\nWORKDIR /app\nCOPY . .\nRUN npm ci --only=production\nCMD ["npm", "start"]'
```

## Webhook Triggers

### Add GitHub Webhook

```bash
# Get webhook URL
oc describe bc/banking-api-mock | grep -A 1 "Webhook GitHub"

# Add the webhook URL to your GitHub repository settings
# Settings > Webhooks > Add webhook
```

### Add Generic Webhook

```bash
# Get generic webhook URL
oc describe bc/banking-api-mock | grep -A 1 "Webhook Generic"

# Trigger build via webhook
curl -X POST <webhook-url>
```

## Troubleshooting

### Build Fails

```bash
# Check build logs
oc logs -f bc/banking-api-mock

# Get build details
oc describe build banking-api-mock-1

# Cancel a running build
oc cancel-build banking-api-mock-1

# Delete and recreate build
oc delete bc/banking-api-mock
oc apply -f openshift-buildconfig.yaml
```

### Pod Crashes or Won't Start

```bash
# Check pod status
oc get pods -l app=banking-api-mock

# View pod logs
oc logs -f deployment/banking-api-mock

# Describe pod for events
oc describe pod <pod-name>

# Check deployment events
oc describe deployment banking-api-mock
```

### Route Not Accessible

```bash
# Check route status
oc get route banking-api-mock

# Describe route
oc describe route banking-api-mock

# Test from within cluster
oc run test-pod --image=curlimages/curl --rm -it -- \
  curl http://banking-api-mock:3000/health
```

### Health Check Failures

```bash
# Check health endpoint directly
oc port-forward deployment/banking-api-mock 3000:3000

# In another terminal
curl http://localhost:3000/health

# Adjust probe timings if needed
oc set probe deployment/banking-api-mock \
  --liveness --initial-delay-seconds=15 \
  --readiness --initial-delay-seconds=10
```

## Advanced Configuration

### Use Private Git Repository

Create a secret with Git credentials:

```bash
oc create secret generic git-credentials \
  --from-literal=username=<username> \
  --from-literal=password=<token>

oc set build-secret --source bc/banking-api-mock git-credentials
```

### Use Private Container Registry

Create a pull secret:

```bash
oc create secret docker-registry registry-credentials \
  --docker-server=<registry-url> \
  --docker-username=<username> \
  --docker-password=<password>

oc secrets link default registry-credentials --for=pull
```

### Enable Horizontal Pod Autoscaling

```bash
oc autoscale deployment/banking-api-mock \
  --min=2 \
  --max=10 \
  --cpu-percent=80
```

### Add Persistent Storage (if needed)

```bash
# Create PVC
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: banking-api-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Mount to deployment
oc set volume deployment/banking-api-mock \
  --add --name=data \
  --type=persistentVolumeClaim \
  --claim-name=banking-api-data \
  --mount-path=/app/data
```

## Cleanup

Remove all resources:

```bash
# Delete all resources
oc delete all -l app=banking-api-mock

# Delete the project
oc delete project banking-api-mock
```

## Integration with IBM API Connect

Once deployed on OpenShift:

1. **Get the internal service URL**:
   ```bash
   echo "http://banking-api-mock.banking-api-mock.svc.cluster.local:3000"
   ```

2. **Or use the external route**:
   ```bash
   oc get route banking-api-mock -o jsonpath='{.spec.host}'
   ```

3. **Configure API Connect** to use this URL as the backend service

4. **Import the OpenAPI spec** from the `/api-docs` endpoint

## Monitoring and Observability

### View Metrics

```bash
# CPU and Memory usage
oc adm top pods -l app=banking-api-mock

# Node metrics
oc adm top nodes
```

### Stream Logs

```bash
# All pods
oc logs -f -l app=banking-api-mock

# Specific pod
oc logs -f <pod-name>

# Previous pod instance
oc logs --previous <pod-name>
```

### Events

```bash
# Watch events
oc get events --watch

# Filter by deployment
oc get events --field-selector involvedObject.name=banking-api-mock
```

## Security Considerations

The deployment includes:
- Non-root user execution (UID 1001)
- Dropped capabilities
- Read-only root filesystem (where applicable)
- Security context constraints
- TLS termination at the route level

To further harden:

```bash
# Apply restricted SCC
oc adm policy add-scc-to-user restricted -z default

# Enable network policies
oc apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: banking-api-mock-netpol
spec:
  podSelector:
    matchLabels:
      app: banking-api-mock
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 3000
EOF
```

## Support

For issues specific to OpenShift deployment:
- Check OpenShift documentation: https://docs.openshift.com
- Review build logs: `oc logs -f bc/banking-api-mock`
- Check pod events: `oc describe pod <pod-name>`