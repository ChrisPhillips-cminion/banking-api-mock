#!/bin/bash

##############################################################################
# Banking API - Comprehensive Endpoint Test Suite
# 
# This script tests all API endpoints with various scenarios
# Usage: ./test-all-endpoints.sh
##############################################################################

# Configuration - Change this URL to test different servers
BASE_URL="https://small-gw-gateway-cp4i.apps.buttons.hur.hdclab.intranet.ibm.com/c62ce85c-0f44-4dc9-a9ff-c1b702f776b5/sandbox/api.bankingservices.com/v1"

# Authentication - Update this as needed
CLIENT_ID="23a16f5215c8ffb1b613fc895921c91d"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
EXPECTED_TOTAL_TESTS=0
CURRENT_TEST_NUMBER=0

# Failure tracking - associative array to count failures by reason
declare -A FAILURE_REASONS

# Array to store failure details for summary
FAILED_TESTS_DETAILS=()

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_test() {
    echo -e "${YELLOW}TEST: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
    ((EXPECTED_TOTAL_TESTS++))
    ((CURRENT_TEST_NUMBER++))
}

store_failure_detail() {
    local test_number="$1"
    local test_name="$2"
    local expected="$3"
    local got="$4"
    local endpoint="$5"
    local curl_cmd="$6"
    
    FAILED_TESTS_DETAILS+=("TEST #$test_number: $test_name|EXPECTED: HTTP $expected|GOT: HTTP $got|ENDPOINT: $endpoint|CURL: $curl_cmd")
}

print_failure() {
    local description="$1"
    local response="$2"
    local failure_reason="$3"
    
    ((CURRENT_TEST_NUMBER++))
    echo -e "${RED}✗ FAIL #${CURRENT_TEST_NUMBER}: ${description}${NC}"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
    ((EXPECTED_TOTAL_TESTS++))
    
    # Track failure by reason for summary
    if [ -n "$failure_reason" ]; then
        ((FAILURE_REASONS["$failure_reason"]++))
    fi
}


print_failure_summary() {
    if [ ${#FAILED_TESTS_DETAILS[@]} -eq 0 ]; then
        return
    fi
    
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Failed Tests Summary${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo ""
    
    for detail in "${FAILED_TESTS_DETAILS[@]}"; do
        IFS='|' read -ra PARTS <<< "$detail"
        echo -e "${RED}${PARTS[0]}${NC}"
        echo -e "  ${PARTS[1]}"
        echo -e "  ${PARTS[2]}"
        echo -e "  ${PARTS[3]}"
        echo -e "  ${YELLOW}${PARTS[4]}${NC}"
        echo ""
    done
    
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Copy this prompt to fix the issues:${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
    echo "Fix the following test failures in the banking API mock:"
    echo ""
    for detail in "${FAILED_TESTS_DETAILS[@]}"; do
        IFS='|' read -ra PARTS <<< "$detail"
        echo "- ${PARTS[0]}: ${PARTS[1]}, ${PARTS[2]}"
    done
    echo ""
}

test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_status=$3
    local description=$4
    local data=$5
    local auth_header=$6
    
    print_test "$description"
    
    # Only set default auth header if not explicitly provided (even if empty)
    if [ $# -lt 6 ]; then
        auth_header="X-IBM-Client-Id: $CLIENT_ID"
    fi
    
    # Build curl command for display
    local curl_cmd="curl -k -X $method"
    curl_cmd="$curl_cmd -H \"$auth_header\""
    curl_cmd="$curl_cmd -H \"Content-Type: application/json\""
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    curl_cmd="$curl_cmd \"${BASE_URL}${endpoint}\""
    
    if [ "$method" = "GET" ]; then
        if [ -n "$auth_header" ]; then
            response=$(curl -n -k -s -w "\n%{http_code}" -X GET \
                -H "$auth_header" \
                -H "Content-Type: application/json" \
                "${BASE_URL}${endpoint}")
        else
            response=$(curl -n -k -s -w "\n%{http_code}" -X GET \
                -H "Content-Type: application/json" \
                "${BASE_URL}${endpoint}")
        fi
    elif [ "$method" = "POST" ]; then
        if [ -n "$auth_header" ]; then
            response=$(curl -n -k -s -w "\n%{http_code}" -X POST \
                -H "$auth_header" \
                -H "Content-Type: application/json" \
                -d "$data" \
                "${BASE_URL}${endpoint}")
        else
            response=$(curl -n -k -s -w "\n%{http_code}" -X POST \
                -H "Content-Type: application/json" \
                -d "$data" \
                "${BASE_URL}${endpoint}")
        fi
    elif [ "$method" = "PUT" ]; then
        if [ -n "$auth_header" ]; then
            response=$(curl -n -k -s -w "\n%{http_code}" -X PUT \
                -H "$auth_header" \
                -H "Content-Type: application/json" \
                -d "$data" \
                "${BASE_URL}${endpoint}")
        else
            response=$(curl -n -k -s -w "\n%{http_code}" -X PUT \
                -H "Content-Type: application/json" \
                -d "$data" \
                "${BASE_URL}${endpoint}")
        fi
    elif [ "$method" = "DELETE" ]; then
        if [ -n "$auth_header" ]; then
            response=$(curl -n -k -s -w "\n%{http_code}" -X DELETE \
                -H "$auth_header" \
                -H "Content-Type: application/json" \
                "${BASE_URL}${endpoint}")
        else
            response=$(curl -n -k -s -w "\n%{http_code}" -X DELETE \
                -H "Content-Type: application/json" \
                "${BASE_URL}${endpoint}")
        fi
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected_status" ]; then
        print_success "$description (HTTP $http_code)"
    else
        # Create a failure reason based on the HTTP status code mismatch
        local failure_reason="HTTP_STATUS_MISMATCH_Expected_${expected_status}_Got_${http_code}"
        local test_num=$((CURRENT_TEST_NUMBER + 1))
        print_failure "$description (Expected: $expected_status, Got: $http_code)" "$body" "$failure_reason"
        echo -e "${YELLOW}  Debug: $curl_cmd${NC}"
        
        # Store failure details for summary
        store_failure_detail "$test_num" "$description" "$expected_status" "$http_code" "$endpoint" "$curl_cmd"
    fi
    
    sleep 0.5
}

##############################################################################
# Test Suite
##############################################################################

print_header "Banking API Test Suite"
echo "Base URL: $BASE_URL"
echo "Client ID: $CLIENT_ID"
echo ""

##############################################################################
# Health Check Tests
##############################################################################

print_header "1. Health Check Tests"

test_endpoint "GET" "/health" "200" "Health check endpoint (no auth)" "" ""

##############################################################################
# Account Tests
##############################################################################

print_header "2. Account Tests"

test_endpoint "GET" "/accounts" "200" "List all accounts"

test_endpoint "GET" "/accounts?page=1&limit=5" "200" "List accounts with pagination"

test_endpoint "GET" "/accounts?accountType=CHECKING" "200" "Filter accounts by type"

test_endpoint "GET" "/accounts?status=ACTIVE" "200" "Filter accounts by status"

test_endpoint "GET" "/accounts/acc-123456789" "200" "Get specific account details"

test_endpoint "GET" "/accounts/acc-999999999" "404" "Get non-existent account"

test_endpoint "GET" "/accounts/acc-123456789/balance" "200" "Get account balance"

test_endpoint "GET" "/accounts/acc-123456789/transactions" "200" "Get account transactions"

test_endpoint "GET" "/accounts/acc-123456789/transactions?page=1&limit=10" "200" "Get account transactions with pagination"

test_endpoint "GET" "/accounts/acc-123456789/statements" "200" "Get account statements"

##############################################################################
# Transaction Tests
##############################################################################

print_header "3. Transaction Tests"

test_endpoint "GET" "/transactions" "200" "List all transactions"

test_endpoint "GET" "/transactions?page=1&limit=10" "200" "List transactions with pagination"

test_endpoint "GET" "/transactions?transactionType=DEBIT" "200" "Filter transactions by type (DEBIT)"

test_endpoint "GET" "/transactions?transactionType=CREDIT" "200" "Filter transactions by type (CREDIT)"

test_endpoint "GET" "/transactions?startDate=2024-01-01&endDate=2024-12-31" "200" "Filter transactions by date range"

test_endpoint "GET" "/transactions?minAmount=100&maxAmount=1000" "200" "Filter transactions by amount range"

test_endpoint "GET" "/transactions/txn-20260109-001" "200" "Get specific transaction details"

test_endpoint "GET" "/transactions/txn-99999999-999" "404" "Get non-existent transaction"

##############################################################################
# Payment Tests
##############################################################################

print_header "4. Payment Tests"

payment_data='{
  "fromAccountId": "acc-123456789",
  "toBeneficiaryId": "ben-987654321",
  "amount": 100.00,
  "currency": "GBP",
  "paymentType": "DOMESTIC",
  "reference": "Test payment",
  "scheduledDate": "2024-12-31",
  "urgency": "NORMAL"
}'

test_endpoint "POST" "/payments" "201" "Create a new payment" "$payment_data"

test_endpoint "GET" "/payments/pay-123456789" "200" "Get payment details"

test_endpoint "GET" "/payments/pay-999999999" "404" "Get non-existent payment"

cancel_payment_data='{"reason":"Test cancellation"}'
test_endpoint "PUT" "/payments/pay-123456789/cancel" "200" "Cancel a payment" "$cancel_payment_data"

test_endpoint "PUT" "/payments/pay-999999999/cancel" "404" "Cancel non-existent payment"

##############################################################################
# Beneficiary Tests
##############################################################################

print_header "5. Beneficiary Tests"

test_endpoint "GET" "/beneficiaries" "200" "List all beneficiaries"

test_endpoint "GET" "/beneficiaries?page=1&limit=10" "200" "List beneficiaries with pagination"

test_endpoint "GET" "/beneficiaries?beneficiaryType=INDIVIDUAL" "200" "Filter beneficiaries by type"

beneficiary_data='{
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
}'

test_endpoint "POST" "/beneficiaries" "201" "Create a new beneficiary" "$beneficiary_data"

test_endpoint "GET" "/beneficiaries/ben-987654321" "200" "Get beneficiary details"

test_endpoint "GET" "/beneficiaries/ben-999999999" "404" "Get non-existent beneficiary"

update_beneficiary_data='{
  "nickname": "Johnny",
  "email": "johnny.doe@example.com"
}'

test_endpoint "PUT" "/beneficiaries/ben-987654321" "200" "Update beneficiary" "$update_beneficiary_data"

test_endpoint "PUT" "/beneficiaries/ben-999999999" "404" "Update non-existent beneficiary" "$update_beneficiary_data"

test_endpoint "DELETE" "/beneficiaries/ben-987654321" "204" "Delete beneficiary"

test_endpoint "DELETE" "/beneficiaries/ben-999999999" "404" "Delete non-existent beneficiary"

##############################################################################
# Statement Tests
##############################################################################

print_header "6. Statement Tests"

test_endpoint "GET" "/statements/stmt-202401-001/download?format=pdf" "200" "Download statement as PDF"

test_endpoint "GET" "/statements/stmt-202401-001/download?format=csv" "200" "Download statement as CSV"

test_endpoint "GET" "/statements/stmt-999999-999/download?format=pdf" "404" "Download non-existent statement"

##############################################################################
# Authentication Tests
##############################################################################

print_header "7. Authentication Tests"

test_endpoint "GET" "/accounts" "401" "Request without authentication" "" ""

test_endpoint "GET" "/accounts" "200" "Request with X-IBM-Client-Id" "" "X-IBM-Client-Id: $CLIENT_ID"

##############################################################################
# Error Handling Tests
##############################################################################

print_header "8. Error Handling Tests"

test_endpoint "GET" "/invalid-endpoint" "404" "Invalid endpoint"

test_endpoint "GET" "/accounts/invalid-id" "400" "Invalid account ID format"

invalid_payment_data='{
  "fromAccountId": "acc-123456789",
  "amount": -100.00
}'

test_endpoint "POST" "/payments" "400" "Create payment with invalid data" "$invalid_payment_data"

##############################################################################
# Summary
##############################################################################

print_header "Test Summary"
echo ""
echo -e "Total Tests:  ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    print_failure_summary
    exit 1
fi

# Made with Bob
