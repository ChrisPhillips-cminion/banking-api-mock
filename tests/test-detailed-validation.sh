#!/bin/bash

##############################################################################
# Banking API - Detailed Response Validation Test Suite
# 
# This script performs thorough validation of API responses including:
# - HTTP status codes
# - Response headers
# - JSON structure validation
# - Field type validation
# - Required field presence
# - Data format validation
#
# Usage: ./test-detailed-validation.sh
##############################################################################

# Configuration - Change this URL to test different servers
BASE_URL="https://small-gw-gateway-cp4i.apps.buttons.hur.hdclab.intranet.ibm.com/c62ce85c-0f44-4dc9-a9ff-c1b702f776b5/sandbox/api.bankingservices.com/v1"

# Authentication
CLIENT_ID="23a16f5215c8ffb1b613fc895921c91d"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CURRENT_TEST_NUMBER=0

# Failure tracking - associative array to count failures by reason
declare -A FAILURE_REASONS
MAX_SAME_FAILURES=3

# Array to store failure details for summary
FAILED_TESTS_DETAILS=()

# Temp files
RESPONSE_FILE=$(mktemp)
HEADERS_FILE=$(mktemp)

# Cleanup on exit
trap "rm -f $RESPONSE_FILE $HEADERS_FILE" EXIT

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
    echo ""
    echo -e "${CYAN}TEST: $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
    ((PASSED_TESTS++))
    ((CURRENT_TEST_NUMBER++))
}

store_failure_detail() {
    local test_number="$1"
    local test_name="$2"
    local details="$3"
    local curl_cmd="$4"
    
    FAILED_TESTS_DETAILS+=("TEST #$test_number: $test_name|DETAILS: $details|CURL: $curl_cmd")
}

print_failure() {
    local description="$1"
    local failure_reason="$2"
    
    ((CURRENT_TEST_NUMBER++))
    echo -e "${RED}  ✗ #${CURRENT_TEST_NUMBER}: ${description}${NC}"
    if [ -n "$LAST_CURL_CMD" ]; then
        echo -e "${YELLOW}  Debug: $LAST_CURL_CMD${NC}"
    fi
    ((FAILED_TESTS++))
    
    # Store failure details
    store_failure_detail "$CURRENT_TEST_NUMBER" "$description" "$failure_reason" "$LAST_CURL_CMD"
    
    # Track failure by reason
    if [ -n "$failure_reason" ]; then
        ((FAILURE_REASONS["$failure_reason"]++))
        local count=${FAILURE_REASONS["$failure_reason"]}
        
        if [ $count -ge $MAX_SAME_FAILURES ]; then
            echo ""
            echo -e "${RED}════════════════════════════════════════${NC}"
            echo -e "${RED}STOPPING: $count tests failed with same reason${NC}"
            echo -e "${RED}Reason: $failure_reason${NC}"
            echo -e "${RED}════════════════════════════════════════${NC}"
            echo ""
            print_summary_and_exit
        fi
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
        echo -e "  ${YELLOW}${PARTS[2]}${NC}"
        echo ""
    done
    
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Copy this prompt to fix the issues:${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
    echo "Fix the following validation failures in the banking API mock:"
    echo ""
    for detail in "${FAILED_TESTS_DETAILS[@]}"; do
        IFS='|' read -ra PARTS <<< "$detail"
        echo "- ${PARTS[0]}: ${PARTS[1]}"
    done
    echo ""
}

print_summary_and_exit() {
    # Calculate estimated total tests based on validation calls in the script
    local estimated_total=$(grep -E "validate_status|validate_json|validate_field|validate_content_type" "$0" 2>/dev/null | wc -l | tr -d ' ')
    local skipped_tests=$((estimated_total - TOTAL_TESTS))
    
    print_header "Test Summary (Early Exit)"
    echo ""
    echo -e "Validations Run:   ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Passed:            ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed:            ${RED}$FAILED_TESTS${NC}"
    if [ "$estimated_total" -gt 0 ] && [ $skipped_tests -gt 0 ]; then
        echo -e "Skipped:           ${YELLOW}$skipped_tests${NC} (not run due to early exit)"
        echo -e "Total Validations: ${BLUE}$estimated_total${NC}"
    fi
    echo ""
    echo -e "${RED}Test run stopped early due to repeated failures${NC}"
    echo ""
    echo "Failure breakdown by reason:"
    for reason in "${!FAILURE_REASONS[@]}"; do
        echo -e "  ${RED}${FAILURE_REASONS[$reason]}x${NC} - $reason"
    done
    echo ""
    
    print_failure_summary
    exit 1
}

print_info() {
    echo -e "${YELLOW}  ℹ $1${NC}"
}

# Make API request and save response
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_header=${4:-"X-IBM-Client-Id: $CLIENT_ID"}
    
    # Build curl command for debugging
    LAST_CURL_CMD="curl -k -X $method -H \"$auth_header\" -H \"Content-Type: application/json\""
    if [ -n "$data" ]; then
        LAST_CURL_CMD="$LAST_CURL_CMD -d '$data'"
    fi
    LAST_CURL_CMD="$LAST_CURL_CMD \"${BASE_URL}${endpoint}\""
    
    if [ "$method" = "GET" ]; then
        curl -n -k -s -D "$HEADERS_FILE" -X GET \
            -H "$auth_header" \
            -H "Content-Type: application/json" \
            "${BASE_URL}${endpoint}" > "$RESPONSE_FILE"
    elif [ "$method" = "POST" ]; then
        curl -n -k -s -D "$HEADERS_FILE" -X POST \
            -H "$auth_header" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${BASE_URL}${endpoint}" > "$RESPONSE_FILE"
    elif [ "$method" = "PUT" ]; then
        curl -n -k -s -D "$HEADERS_FILE" -X PUT \
            -H "$auth_header" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${BASE_URL}${endpoint}" > "$RESPONSE_FILE"
    elif [ "$method" = "DELETE" ]; then
        curl -n -k -s -D "$HEADERS_FILE" -X DELETE \
            -H "$auth_header" \
            -H "Content-Type: application/json" \
            "${BASE_URL}${endpoint}" > "$RESPONSE_FILE"
    fi
}

# Validate HTTP status code
validate_status() {
    local expected=$1
    local actual=$(grep "HTTP" "$HEADERS_FILE" | tail -1 | awk '{print $2}')
    
    ((TOTAL_TESTS++))
    if [ "$actual" = "$expected" ]; then
        print_success "HTTP Status: $actual (expected: $expected)"
        return 0
    else
        local failure_reason="HTTP_STATUS_Expected_${expected}_Got_${actual}"
        print_failure "HTTP Status: $actual (expected: $expected)" "$failure_reason"
        return 1
    fi
}

# Validate Content-Type header
validate_content_type() {
    local expected=$1
    local actual=$(grep -i "content-type:" "$HEADERS_FILE" | awk '{print $2}' | tr -d '\r')
    
    ((TOTAL_TESTS++))
    if [[ "$actual" == *"$expected"* ]]; then
        print_success "Content-Type: $actual"
        return 0
    else
        local failure_reason="CONTENT_TYPE_MISMATCH"
        print_failure "Content-Type: $actual (expected: $expected)" "$failure_reason"
        return 1
    fi
}

# Validate JSON structure
validate_json() {
    ((TOTAL_TESTS++))
    if jq empty "$RESPONSE_FILE" 2>/dev/null; then
        print_success "Valid JSON structure"
        return 0
    else
        local failure_reason="INVALID_JSON_STRUCTURE"
        print_failure "Invalid JSON structure" "$failure_reason"
        cat "$RESPONSE_FILE"
        return 1
    fi
}

# Validate field exists
validate_field_exists() {
    local field=$1
    local value=$(jq -r "$field" "$RESPONSE_FILE" 2>/dev/null)
    
    ((TOTAL_TESTS++))
    if [ "$value" != "null" ] && [ -n "$value" ]; then
        print_success "Field exists: $field = $value"
        return 0
    else
        local failure_reason="FIELD_MISSING_OR_NULL"
        print_failure "Field missing or null: $field" "$failure_reason"
        return 1
    fi
}

# Validate field type
validate_field_type() {
    local field=$1
    local expected_type=$2
    local actual_type=$(jq -r "$field | type" "$RESPONSE_FILE" 2>/dev/null)
    
    ((TOTAL_TESTS++))
    if [ "$actual_type" = "$expected_type" ]; then
        print_success "Field type: $field is $actual_type"
        return 0
    else
        local failure_reason="FIELD_TYPE_MISMATCH"
        print_failure "Field type: $field is $actual_type (expected: $expected_type)" "$failure_reason"
        return 1
    fi
}

# Validate field value
validate_field_value() {
    local field=$1
    local expected=$2
    local actual=$(jq -r "$field" "$RESPONSE_FILE" 2>/dev/null)
    
    ((TOTAL_TESTS++))
    if [ "$actual" = "$expected" ]; then
        print_success "Field value: $field = $actual"
        return 0
    else
        local failure_reason="FIELD_VALUE_MISMATCH"
        print_failure "Field value: $field = $actual (expected: $expected)" "$failure_reason"
        return 1
    fi
}

# Validate field matches pattern
validate_field_pattern() {
    local field=$1
    local pattern=$2
    local description=$3
    local actual=$(jq -r "$field" "$RESPONSE_FILE" 2>/dev/null)
    
    ((TOTAL_TESTS++))
    if [[ "$actual" =~ $pattern ]]; then
        print_success "Field pattern: $field matches $description"
        return 0
    else
        local failure_reason="FIELD_PATTERN_MISMATCH_${description// /_}"
        print_failure "Field pattern: $field = '$actual' does not match $description" "$failure_reason"
        return 1
    fi
}

# Validate array length
validate_array_length() {
    local field=$1
    local min_length=$2
    local actual_length=$(jq -r "$field | length" "$RESPONSE_FILE" 2>/dev/null)
    
    ((TOTAL_TESTS++))
    if [ "$actual_length" -ge "$min_length" ]; then
        print_success "Array length: $field has $actual_length items (min: $min_length)"
        return 0
    else
        local failure_reason="ARRAY_LENGTH_TOO_SHORT"
        print_failure "Array length: $field has $actual_length items (expected min: $min_length)" "$failure_reason"
        return 1
    fi
}

# Validate field is ISO date
validate_iso_date() {
    local field=$1
    local pattern='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
    validate_field_pattern "$field" "$pattern" "ISO 8601 date format"
}

# Validate field is UUID
validate_uuid() {
    local field=$1
    local pattern='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    validate_field_pattern "$field" "$pattern" "UUID format"
}

# Display response for debugging
show_response() {
    print_info "Response body:"
    jq '.' "$RESPONSE_FILE" 2>/dev/null || cat "$RESPONSE_FILE"
}

##############################################################################
# Test Suite
##############################################################################

print_header "Banking API - Detailed Validation Test Suite"
echo "Base URL: $BASE_URL"
echo "Client ID: $CLIENT_ID"
echo ""
echo "This suite performs thorough validation of:"
echo "  - HTTP status codes"
echo "  - Response headers"
echo "  - JSON structure"
echo "  - Field types and values"
echo "  - Data formats"
echo ""

##############################################################################
# Test 1: Health Check Endpoint
##############################################################################

print_test "1. Health Check Endpoint - GET /health"
make_request "GET" "/health" "" ""

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".status"
validate_field_value ".status" "UP"
validate_field_exists ".timestamp"
validate_iso_date ".timestamp"
validate_field_exists ".version"

show_response

##############################################################################
# Test 2: List Accounts
##############################################################################

print_test "2. List Accounts - GET /accounts"
make_request "GET" "/accounts"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".accounts"
validate_field_type ".accounts" "array"
validate_array_length ".accounts" 1

# Validate first account structure
validate_field_exists ".accounts[0].accountId"
validate_field_pattern ".accounts[0].accountId" "^acc-[0-9]{9}$" "account ID format (acc-XXXXXXXXX)"
validate_field_exists ".accounts[0].accountNumber"
validate_field_exists ".accounts[0].accountType"
validate_field_exists ".accounts[0].currency"
validate_field_exists ".accounts[0].status"
validate_field_exists ".accounts[0].openedDate"

# Validate pagination
validate_field_exists ".pagination"
validate_field_exists ".pagination.page"
validate_field_type ".pagination.page" "number"
validate_field_exists ".pagination.limit"
validate_field_type ".pagination.limit" "number"
validate_field_exists ".pagination.totalPages"
validate_field_type ".pagination.totalPages" "number"
validate_field_exists ".pagination.totalRecords"
validate_field_type ".pagination.totalRecords" "number"

show_response

##############################################################################
# Test 3: Get Specific Account
##############################################################################

print_test "3. Get Account Details - GET /accounts/acc-123456789"
make_request "GET" "/accounts/acc-123456789"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".accountId"
validate_field_value ".accountId" "acc-123456789"
validate_field_exists ".accountNumber"
validate_field_exists ".accountType"
validate_field_exists ".currency"
validate_field_exists ".status"
validate_field_exists ".balance"
validate_field_type ".balance" "number"
validate_field_exists ".availableBalance"
validate_field_type ".availableBalance" "number"
validate_field_exists ".openedDate"
validate_field_exists ".lastActivityDate"

show_response

##############################################################################
# Test 4: Get Account Balance
##############################################################################

print_test "4. Get Account Balance - GET /accounts/acc-123456789/balance"
make_request "GET" "/accounts/acc-123456789/balance"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".accountId"
validate_field_value ".accountId" "acc-123456789"
validate_field_exists ".balance"
validate_field_type ".balance" "number"
validate_field_exists ".availableBalance"
validate_field_type ".availableBalance" "number"
validate_field_exists ".currency"
validate_field_exists ".asOfDate"
validate_iso_date ".asOfDate"

show_response

##############################################################################
# Test 5: List Transactions
##############################################################################

print_test "5. List Transactions - GET /transactions"
make_request "GET" "/transactions"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".transactions"
validate_field_type ".transactions" "array"
validate_array_length ".transactions" 1

# Validate first transaction structure
validate_field_exists ".transactions[0].transactionId"
validate_field_pattern ".transactions[0].transactionId" "^txn-[0-9]{8}-[0-9]{3}$" "transaction ID format"
validate_field_exists ".transactions[0].accountId"
validate_field_exists ".transactions[0].transactionType"
validate_field_exists ".transactions[0].amount"
validate_field_type ".transactions[0].amount" "number"
validate_field_exists ".transactions[0].currency"
validate_field_exists ".transactions[0].description"
validate_field_exists ".transactions[0].transactionDate"
validate_field_exists ".transactions[0].status"

# Validate pagination
validate_field_exists ".pagination"

show_response

##############################################################################
# Test 6: Get Specific Transaction
##############################################################################

print_test "6. Get Transaction Details - GET /transactions/txn-20260109-001"
make_request "GET" "/transactions/txn-20260109-001"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".transactionId"
validate_field_value ".transactionId" "txn-20260109-001"
validate_field_exists ".accountId"
validate_field_exists ".transactionType"
validate_field_exists ".amount"
validate_field_type ".amount" "number"
validate_field_exists ".currency"
validate_field_exists ".description"
validate_field_exists ".transactionDate"
validate_field_exists ".status"
validate_field_exists ".balance"
validate_field_type ".balance" "number"

show_response

##############################################################################
# Test 7: Create Payment
##############################################################################

print_test "7. Create Payment - POST /payments"

payment_data='{
  "fromAccountId": "acc-123456789",
  "toBeneficiaryId": "ben-987654321",
  "amount": 150.50,
  "currency": "GBP",
  "paymentType": "DOMESTIC",
  "reference": "Test payment validation",
  "scheduledDate": "2024-12-31",
  "urgency": "NORMAL"
}'

make_request "POST" "/payments" "$payment_data"

validate_status "201"
validate_content_type "application/json"
validate_json

validate_field_exists ".paymentId"
validate_field_pattern ".paymentId" "^pay-[0-9]{9}$" "payment ID format"
validate_field_exists ".fromAccountId"
validate_field_value ".fromAccountId" "acc-123456789"
validate_field_exists ".toBeneficiaryId"
validate_field_value ".toBeneficiaryId" "ben-987654321"
validate_field_exists ".amount"
validate_field_value ".amount" "150.5"
validate_field_exists ".currency"
validate_field_value ".currency" "GBP"
validate_field_exists ".paymentType"
validate_field_value ".paymentType" "DOMESTIC"
validate_field_exists ".status"
validate_field_exists ".createdAt"
validate_iso_date ".createdAt"
validate_field_exists ".reference"

show_response

##############################################################################
# Test 8: Get Payment Details
##############################################################################

print_test "8. Get Payment Details - GET /payments/pay-123456789"
make_request "GET" "/payments/pay-123456789"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".paymentId"
validate_field_value ".paymentId" "pay-123456789"
validate_field_exists ".fromAccountId"
validate_field_exists ".toBeneficiaryId"
validate_field_exists ".amount"
validate_field_type ".amount" "number"
validate_field_exists ".currency"
validate_field_exists ".paymentType"
validate_field_exists ".status"
validate_field_exists ".createdAt"

show_response

##############################################################################
# Test 9: List Beneficiaries
##############################################################################

print_test "9. List Beneficiaries - GET /beneficiaries"
make_request "GET" "/beneficiaries"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".beneficiaries"
validate_field_type ".beneficiaries" "array"
validate_array_length ".beneficiaries" 1

# Validate first beneficiary structure
validate_field_exists ".beneficiaries[0].beneficiaryId"
validate_field_pattern ".beneficiaries[0].beneficiaryId" "^ben-[0-9]{9}$" "beneficiary ID format"
validate_field_exists ".beneficiaries[0].beneficiaryType"
validate_field_exists ".beneficiaries[0].name"
validate_field_exists ".beneficiaries[0].accountNumber"
validate_field_exists ".beneficiaries[0].bankName"
validate_field_exists ".beneficiaries[0].status"

# Validate pagination
validate_field_exists ".pagination"

show_response

##############################################################################
# Test 10: Create Beneficiary
##############################################################################

print_test "10. Create Beneficiary - POST /beneficiaries"

beneficiary_data='{
  "beneficiaryType": "INDIVIDUAL",
  "name": "Jane Smith",
  "nickname": "Jane",
  "accountNumber": "87654321",
  "routingNumber": "654321",
  "bankName": "Test Bank Ltd",
  "bankAddress": {
    "street": "456 High Street",
    "city": "Manchester",
    "state": "Greater Manchester",
    "postalCode": "M1 1AA",
    "country": "GB"
  },
  "email": "jane.smith@example.com",
  "phone": "+441234567891"
}'

make_request "POST" "/beneficiaries" "$beneficiary_data"

validate_status "201"
validate_content_type "application/json"
validate_json

validate_field_exists ".beneficiaryId"
validate_field_pattern ".beneficiaryId" "^ben-[0-9]{9}$" "beneficiary ID format"
validate_field_exists ".beneficiaryType"
validate_field_value ".beneficiaryType" "INDIVIDUAL"
validate_field_exists ".name"
validate_field_value ".name" "Jane Smith"
validate_field_exists ".accountNumber"
validate_field_value ".accountNumber" "87654321"
validate_field_exists ".bankName"
validate_field_exists ".status"
validate_field_exists ".createdAt"
validate_iso_date ".createdAt"

show_response

##############################################################################
# Test 11: Get Beneficiary Details
##############################################################################

print_test "11. Get Beneficiary Details - GET /beneficiaries/ben-987654321"
make_request "GET" "/beneficiaries/ben-987654321"

validate_status "200"
validate_content_type "application/json"
validate_json

validate_field_exists ".beneficiaryId"
validate_field_value ".beneficiaryId" "ben-987654321"
validate_field_exists ".beneficiaryType"
validate_field_exists ".name"
validate_field_exists ".accountNumber"
validate_field_exists ".routingNumber"
validate_field_exists ".bankName"
validate_field_exists ".bankAddress"
validate_field_exists ".bankAddress.street"
validate_field_exists ".bankAddress.city"
validate_field_exists ".bankAddress.country"
validate_field_exists ".status"

show_response

##############################################################################
# Test 12: Error Responses - 404 Not Found
##############################################################################

print_test "12. Error Response - GET /accounts/acc-999999999 (Not Found)"
make_request "GET" "/accounts/acc-999999999"

validate_status "404"
validate_content_type "application/json"
validate_json

validate_field_exists ".error"
validate_field_exists ".error.code"
validate_field_value ".error.code" "NOT_FOUND"
validate_field_exists ".error.message"
validate_field_exists ".error.timestamp"
validate_iso_date ".error.timestamp"

show_response

##############################################################################
# Test 13: Error Responses - 401 Unauthorized
##############################################################################

print_test "13. Error Response - GET /accounts (No Authentication)"
make_request "GET" "/accounts" "" ""

validate_status "401"
validate_content_type "application/json"
validate_json

validate_field_exists ".error"
validate_field_exists ".error.code"
validate_field_value ".error.code" "UNAUTHORIZED"
validate_field_exists ".error.message"
validate_field_exists ".error.timestamp"

show_response

##############################################################################
# Test 14: Pagination Validation
##############################################################################

print_test "14. Pagination - GET /accounts?page=1&limit=5"
make_request "GET" "/accounts?page=1&limit=5"

validate_status "200"
validate_json

validate_field_exists ".pagination.page"
validate_field_value ".pagination.page" "1"
validate_field_exists ".pagination.limit"
validate_field_value ".pagination.limit" "5"

show_response

##############################################################################
# Test 15: Filter Validation
##############################################################################

print_test "15. Filtering - GET /transactions?transactionType=DEBIT"
make_request "GET" "/transactions?transactionType=DEBIT"

validate_status "200"
validate_json

validate_field_exists ".transactions"
validate_field_type ".transactions" "array"

# Validate all transactions are DEBIT type
transaction_count=$(jq -r '.transactions | length' "$RESPONSE_FILE")
if [ "$transaction_count" -gt 0 ]; then
    for i in $(seq 0 $((transaction_count - 1))); do
        validate_field_value ".transactions[$i].transactionType" "DEBIT"
    done
fi

show_response

##############################################################################
# Test 16: Bad Data - Invalid Payment Amount
##############################################################################

print_test "16. Bad Data - POST /payments with negative amount"

invalid_payment_negative='{
  "fromAccountId": "acc-123456789",
  "toBeneficiaryId": "ben-987654321",
  "amount": -100.00,
  "currency": "GBP",
  "paymentType": "DOMESTIC",
  "reference": "Invalid payment",
  "scheduledDate": "2024-12-31",
  "urgency": "NORMAL"
}'

make_request "POST" "/payments" "$invalid_payment_negative"

validate_status "400"
validate_json
validate_field_exists ".error"
validate_field_exists ".error.code"
validate_field_exists ".error.message"

show_response

##############################################################################
# Test 17: Bad Data - Missing Required Fields
##############################################################################

print_test "17. Bad Data - POST /payments with missing required fields"

invalid_payment_missing='{
  "fromAccountId": "acc-123456789",
  "amount": 100.00
}'

make_request "POST" "/payments" "$invalid_payment_missing"

validate_status "400"
validate_json
validate_field_exists ".error"
validate_field_exists ".error.code"

show_response

##############################################################################
# Test 18: Bad Data - Invalid Account ID Format
##############################################################################

print_test "18. Bad Data - GET /accounts/invalid-format"
make_request "GET" "/accounts/invalid-format"

validate_status "400"
validate_json
validate_field_exists ".error"
validate_field_exists ".error.code"

show_response

##############################################################################
# Test 19-30: Additional Bad Data Tests
##############################################################################

for test_num in {19..30}; do
    case $test_num in
        19)
            print_test "19. Bad Data - POST /payments with invalid currency"
            invalid_data='{
              "fromAccountId": "acc-123456789",
              "toBeneficiaryId": "ben-987654321",
              "amount": 100.00,
              "currency": "INVALID",
              "paymentType": "DOMESTIC",
              "reference": "Test payment",
              "scheduledDate": "2024-12-31",
              "urgency": "NORMAL"
            }'
            make_request "POST" "/payments" "$invalid_data"
            ;;
        20)
            print_test "20. Bad Data - POST /payments with invalid date format"
            invalid_data='{
              "fromAccountId": "acc-123456789",
              "toBeneficiaryId": "ben-987654321",
              "amount": 100.00,
              "currency": "GBP",
              "paymentType": "DOMESTIC",
              "reference": "Test payment",
              "scheduledDate": "invalid-date",
              "urgency": "NORMAL"
            }'
            make_request "POST" "/payments" "$invalid_data"
            ;;
        21)
            print_test "21. Bad Data - POST /beneficiaries with invalid type"
            invalid_data='{
              "beneficiaryType": "INVALID_TYPE",
              "name": "Test User",
              "accountNumber": "12345678",
              "routingNumber": "123456",
              "bankName": "Test Bank"
            }'
            make_request "POST" "/beneficiaries" "$invalid_data"
            ;;
        22)
            print_test "22. Bad Data - POST /beneficiaries with invalid email"
            invalid_data='{
              "beneficiaryType": "INDIVIDUAL",
              "name": "Test User",
              "accountNumber": "12345678",
              "routingNumber": "123456",
              "bankName": "Test Bank",
              "email": "not-an-email"
            }'
            make_request "POST" "/beneficiaries" "$invalid_data"
            ;;
        23)
            print_test "23. Bad Data - POST /beneficiaries with invalid phone"
            invalid_data='{
              "beneficiaryType": "INDIVIDUAL",
              "name": "Test User",
              "accountNumber": "12345678",
              "routingNumber": "123456",
              "bankName": "Test Bank",
              "phone": "123"
            }'
            make_request "POST" "/beneficiaries" "$invalid_data"
            ;;
        24)
            print_test "24. Bad Data - POST /payments with malformed JSON"
            invalid_data='{"fromAccountId": "acc-123456789", "amount": 100.00'
            make_request "POST" "/payments" "$invalid_data"
            ;;
        25)
            print_test "25. Bad Data - POST /payments with empty body"
            make_request "POST" "/payments" ""
            ;;
        26)
            print_test "26. Bad Data - POST /payments with invalid payment type"
            invalid_data='{
              "fromAccountId": "acc-123456789",
              "toBeneficiaryId": "ben-987654321",
              "amount": 100.00,
              "currency": "GBP",
              "paymentType": "INVALID_TYPE",
              "reference": "Test payment",
              "scheduledDate": "2024-12-31",
              "urgency": "NORMAL"
            }'
            make_request "POST" "/payments" "$invalid_data"
            ;;
        27)
            print_test "27. Bad Data - POST /payments with excessive amount"
            invalid_data='{
              "fromAccountId": "acc-123456789",
              "toBeneficiaryId": "ben-987654321",
              "amount": 999999999999.99,
              "currency": "GBP",
              "paymentType": "DOMESTIC",
              "reference": "Test payment",
              "scheduledDate": "2024-12-31",
              "urgency": "NORMAL"
            }'
            make_request "POST" "/payments" "$invalid_data"
            ;;
        28)
            print_test "28. Bad Data - GET /transactions with invalid date range"
            make_request "GET" "/transactions?startDate=invalid&endDate=also-invalid"
            ;;
        29)
            print_test "29. Bad Data - GET /accounts with negative page number"
            make_request "GET" "/accounts?page=-1&limit=10"
            ;;
        30)
            print_test "30. Bad Data - GET /accounts with excessive limit"
            make_request "GET" "/accounts?page=1&limit=10000"
            ;;
    esac
    
    validate_status "400"
    validate_json
    validate_field_exists ".error"
    validate_field_exists ".error.code"
    
    echo ""
done

##############################################################################
# Summary
##############################################################################

print_header "Test Summary"
echo ""
echo -e "Total Validations: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:            ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:            ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}   All validations passed! ✓${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    exit 0
else
    pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${YELLOW}   Pass rate: ${pass_rate}%${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    print_failure_summary
    exit 1
fi

# Made with Bob
