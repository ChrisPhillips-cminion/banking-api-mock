#!/bin/bash

##############################################################################
# Banking API - Deploy and Test Script
# 
# This script automates the complete deployment and testing workflow:
# 1. Commits all changes to Git
# 2. Pushes to remote repository
# 3. Triggers OpenShift build
# 4. Waits for build to complete
# 5. Waits for deployment to be ready
# 6. Runs test suite
#
# Usage: ./deploy-and-test.sh [commit-message]
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BUILD_CONFIG="banking-api-mock"
DEPLOYMENT_CONFIG="banking-api-mock"
NAMESPACE=$(oc project -q 2>/dev/null || echo "")
COMMIT_MESSAGE="${1:-Automated deployment $(date +%Y-%m-%d\ %H:%M:%S)}"

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Wait for build to complete
wait_for_build() {
    local build_name=$1
    local timeout=600  # 10 minutes
    local elapsed=0
    
    print_step "Waiting for build to complete..."
    
    while [ $elapsed -lt $timeout ]; do
        status=$(oc get build "$build_name" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        
        case $status in
            "Complete")
                print_success "Build completed successfully"
                return 0
                ;;
            "Failed"|"Error"|"Cancelled")
                print_error "Build failed with status: $status"
                oc logs "build/$build_name" --tail=50
                return 1
                ;;
            "Running"|"Pending"|"New")
                echo -ne "\r  Build status: $status (${elapsed}s elapsed)..."
                sleep 5
                elapsed=$((elapsed + 5))
                ;;
            *)
                print_warning "Unknown build status: $status"
                sleep 5
                elapsed=$((elapsed + 5))
                ;;
        esac
    done
    
    print_error "Build timeout after ${timeout}s"
    return 1
}

# Wait for deployment to be ready
wait_for_deployment() {
    local timeout=300  # 5 minutes
    local elapsed=0
    
    print_step "Waiting for deployment to be ready..."
    
    while [ $elapsed -lt $timeout ]; do
        ready=$(oc get dc "$DEPLOYMENT_CONFIG" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        desired=$(oc get dc "$DEPLOYMENT_CONFIG" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        if [ "$ready" = "$desired" ] && [ "$ready" != "0" ]; then
            print_success "Deployment is ready ($ready/$desired replicas)"
            return 0
        fi
        
        echo -ne "\r  Deployment status: $ready/$desired replicas ready (${elapsed}s elapsed)..."
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    print_error "Deployment timeout after ${timeout}s"
    return 1
}

##############################################################################
# Main Script
##############################################################################

print_header "Banking API - Deploy and Test"
echo "Commit Message: $COMMIT_MESSAGE"
echo "Namespace: ${NAMESPACE:-Not connected}"
echo ""

##############################################################################
# Step 1: Pre-flight Checks
##############################################################################

print_header "Step 1: Pre-flight Checks"

# Check for required commands
print_step "Checking required commands..."

if ! command_exists git; then
    print_error "git is not installed"
    exit 1
fi
print_success "git found"

if ! command_exists oc; then
    print_error "OpenShift CLI (oc) is not installed"
    exit 1
fi
print_success "oc found"

if ! command_exists jq; then
    print_warning "jq is not installed (optional, but recommended for tests)"
fi

# Check OpenShift connection
print_step "Checking OpenShift connection..."
if ! oc whoami &>/dev/null; then
    print_error "Not logged in to OpenShift"
    echo "Please login using: oc login <cluster-url>"
    exit 1
fi
print_success "Connected to OpenShift as $(oc whoami)"

# Check if in git repository
print_step "Checking git repository..."
if ! git rev-parse --git-dir &>/dev/null; then
    print_error "Not in a git repository"
    exit 1
fi
print_success "Git repository found"

##############################################################################
# Step 2: Git Operations
##############################################################################

print_header "Step 2: Git Operations"

# Check for uncommitted changes
print_step "Checking for changes..."
if git diff-index --quiet HEAD --; then
    print_info "No changes to commit"
else
    print_success "Changes detected"
    
    # Show status
    print_step "Git status:"
    git status --short
    echo ""
    
    # Add all changes
    print_step "Adding all changes..."
    git add -A
    print_success "Changes staged"
    
    # Commit changes
    print_step "Committing changes..."
    git commit -m "$COMMIT_MESSAGE"
    print_success "Changes committed"
fi

# Push to remote
print_step "Pushing to remote repository..."
if git push; then
    print_success "Pushed to remote repository"
else
    print_error "Failed to push to remote repository"
    print_info "Continuing with local changes..."
fi

##############################################################################
# Step 3: Clean Up Completed Pods
##############################################################################

print_header "Step 3: Clean Up Completed Pods"

print_step "Removing completed and failed pods..."
completed_count=$(oc get pods --field-selector=status.phase==Succeeded -o name 2>/dev/null | wc -l | tr -d ' ')
failed_count=$(oc get pods --field-selector=status.phase==Failed -o name 2>/dev/null | wc -l | tr -d ' ')

if [ "$completed_count" -gt 0 ]; then
    oc delete pods --field-selector=status.phase==Succeeded 2>/dev/null || true
    print_success "Removed $completed_count completed pod(s)"
else
    print_info "No completed pods to remove"
fi

if [ "$failed_count" -gt 0 ]; then
    oc delete pods --field-selector=status.phase==Failed 2>/dev/null || true
    print_success "Removed $failed_count failed pod(s)"
else
    print_info "No failed pods to remove"
fi

##############################################################################
# Step 4: OpenShift Build
##############################################################################

print_header "Step 4: OpenShift Build"

# Start new build
print_step "Starting new build..."
build_output=$(oc start-build "$BUILD_CONFIG" 2>&1)

if [ $? -eq 0 ]; then
    # Extract build name - format is usually "build.build.openshift.io/banking-api-mock-X created"
    # or "build/banking-api-mock-X"
    build_name=$(echo "$build_output" | grep -oE "${BUILD_CONFIG}-[0-9]+" | head -1)
    
    if [ -z "$build_name" ]; then
        # Try alternative format
        build_name=$(echo "$build_output" | awk '{print $1}' | grep -oE "${BUILD_CONFIG}-[0-9]+")
    fi
    
    if [ -z "$build_name" ]; then
        print_error "Could not parse build name from output:"
        echo "$build_output"
        exit 1
    fi
    
    print_success "Build started: $build_name"
    
    # Follow build logs in background
    print_step "Following build logs..."
    oc logs -f "build/$build_name" &
    log_pid=$!
    
    # Wait for build to complete
    if wait_for_build "$build_name"; then
        # Kill log following process
        kill $log_pid 2>/dev/null || true
        wait $log_pid 2>/dev/null || true
        echo ""
    else
        kill $log_pid 2>/dev/null || true
        wait $log_pid 2>/dev/null || true
        print_error "Build failed"
        exit 1
    fi
else
    print_error "Failed to start build"
    echo "$build_output"
    exit 1
fi

##############################################################################
# Step 5: Wait for Deployment
##############################################################################

print_header "Step 5: Wait for Deployment"

if wait_for_deployment; then
    echo ""
    
    # Show pod status
    print_step "Pod status:"
    oc get pods -l app="$BUILD_CONFIG"
    echo ""
else
    print_error "Deployment failed"
    print_step "Pod status:"
    oc get pods -l app="$BUILD_CONFIG"
    print_step "Recent events:"
    oc get events --sort-by='.lastTimestamp' | tail -10
    exit 1
fi

# Get route URL
print_step "Getting route URL..."
ROUTE_URL=$(oc get route "$BUILD_CONFIG" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -n "$ROUTE_URL" ]; then
    print_success "Route URL: https://$ROUTE_URL"
else
    print_warning "No route found"
fi

##############################################################################
# Step 6: Health Check
##############################################################################

print_header "Step 6: Health Check"

if [ -n "$ROUTE_URL" ]; then
    print_step "Testing health endpoint..."
    sleep 5  # Give the app a moment to fully start
    
    if curl -n -k -s -f "https://$ROUTE_URL/health" > /dev/null; then
        print_success "Health check passed"
        curl -n -k -s "https://$ROUTE_URL/health" | jq '.' 2>/dev/null || curl -n -k -s "https://$ROUTE_URL/health"
    else
        print_error "Health check failed"
        print_info "The application may still be starting up..."
    fi
else
    print_warning "Skipping health check (no route found)"
fi

##############################################################################
# Step 7: Run Tests
##############################################################################

print_header "Step 7: Run Test Suite"

if [ -f "tests/test-all-endpoints.sh" ]; then
    print_step "Running quick test suite..."
    echo ""
    
    cd tests
    chmod +x test-all-endpoints.sh
    
    if ./test-all-endpoints.sh; then
        print_success "Quick tests passed"
    else
        print_warning "Some quick tests failed (see above for details)"
    fi
    
    cd ..
else
    print_warning "Test script not found: tests/test-all-endpoints.sh"
fi

echo ""

if [ -f "tests/test-detailed-validation.sh" ]; then
    print_step "Running detailed validation suite..."
    echo ""
    
    read -p "Run detailed validation tests? (y/N) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd tests
        chmod +x test-detailed-validation.sh
        
        if ./test-detailed-validation.sh; then
            print_success "Detailed validation passed"
        else
            print_warning "Some detailed validations failed (see above for details)"
        fi
        
        cd ..
    else
        print_info "Skipping detailed validation tests"
    fi
else
    print_warning "Test script not found: tests/test-detailed-validation.sh"
fi

##############################################################################
# Summary
##############################################################################

print_header "Deployment Summary"
echo ""
echo -e "Build Config:     ${CYAN}$BUILD_CONFIG${NC}"
echo -e "Deployment:       ${CYAN}$DEPLOYMENT_CONFIG${NC}"
echo -e "Namespace:        ${CYAN}$NAMESPACE${NC}"
if [ -n "$ROUTE_URL" ]; then
    echo -e "Route URL:        ${GREEN}https://$ROUTE_URL${NC}"
    echo -e "Health Check:     ${GREEN}https://$ROUTE_URL/health${NC}"
    echo -e "API Docs:         ${GREEN}https://$ROUTE_URL/api-docs${NC}"
fi
echo ""
print_success "Deployment and testing complete!"
echo ""

# Made with Bob
