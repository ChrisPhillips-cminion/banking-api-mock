#!/bin/bash

##############################################################################
# Banking Composite API - Detailed Test Suite
# 
# Tests the composite API that combines account and transaction data
# into XML responses
#
# Usage: ./test-composite-api.sh
##############################################################################

# Configuration
BASE_URL="https://small-gw-gateway-cp4i.apps.buttons.hur.hdclab.intranet.ibm.com/c62ce85c-0f44-4dc9-a9ff-c1b702f776b5/sandbox/api.bankingservices.com/composite/v1"
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
        echo -e "  ${YELLOW}${PARTS[2]}${NC}"
        echo ""
    done
    
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}Copy this prompt to fix the issues:${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""
    echo "Fix the following test failures in the banking API composite endpoint:"
    echo ""
    for detail in "${FAILED_TESTS_DETAILS[@]}"; do
        IFS='|' read -ra PARTS <<< "$detail"
        echo "- ${PARTS[0]}: ${PARTS[1]}"
    done
    echo ""
}


print_info() {
    echo -e "${YELLOW}  ℹ $1${NC}"
}

# Make API request
make_request() {
    local endpoint=$1
    local auth_header=${2:-"X-IBM-Client-Id: $CLIENT_ID"}
    
    # Store curl command for debugging
    LAST_CURL_CMD="curl -k -X GET -H \"$auth_header\" \"${BASE_URL}${endpoint}\""
    
    curl -n -k -s -D "$HEADERS_FILE" -X GET \
        -H "$auth_header" \
        "${BASE_URL}${endpoint}" > "$RESPONSE_FILE"
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

# Validate Content-Type is XML
validate_xml_content_type() {
    local actual=$(grep -i "content-type:" "$HEADERS_FILE" | awk '{print $2}' | tr -d '\r')
    
    ((TOTAL_TESTS++))
    if [[ "$actual" == *"xml"* ]]; then
        print_success "Content-Type: $actual (contains xml)"
        return 0
    else
        local failure_reason="CONTENT_TYPE_NOT_XML"
        print_failure "Content-Type: $actual (expected xml)" "$failure_reason"
        return 1
    fi
}

# Validate XML structure
validate_xml() {
    ((TOTAL_TESTS++))
    if xmllint --noout "$RESPONSE_FILE" 2>/dev/null; then
        print_success "Valid XML structure"
        return 0
    else
        local failure_reason="INVALID_XML_STRUCTURE"
        print_failure "Invalid XML structure" "$failure_reason"
        cat "$RESPONSE_FILE"
        return 1
    fi
}

# Validate XML element exists
validate_xml_element() {
    local xpath=$1
    local description=$2
    
    ((TOTAL_TESTS++))
    if xmllint --xpath "$xpath" "$RESPONSE_FILE" >/dev/null 2>&1; then
        local value=$(xmllint --xpath "$xpath/text()" "$RESPONSE_FILE" 2>/dev/null)
        print_success "Element exists: $description = $value"
        return 0
    else
        local failure_reason="XML_ELEMENT_MISSING_${description// /_}"
        print_failure "Element missing: $description" "$failure_reason"
        return 1
    fi
}

# Validate XML element value
validate_xml_value() {
    local xpath=$1
    local expected=$2
    local description=$3
    
    ((TOTAL_TESTS++))
    local actual=$(xmllint --xpath "$xpath/text()" "$RESPONSE_FILE" 2>/dev/null)
    
    if [ "$actual" = "$expected" ]; then
        print_success "Element value: $description = $actual"
        return 0
    else
        local failure_reason="XML_VALUE_MISMATCH_${description// /_}"
        print_failure "Element value: $description = $actual (expected: $expected)" "$failure_reason"
        return 1
    fi
}

# Validate XML element matches pattern
validate_xml_pattern() {
    local xpath=$1
    local pattern=$2
    local description=$3
    
    ((TOTAL_TESTS++))
    local actual=$(xmllint --xpath "$xpath/text()" "$RESPONSE_FILE" 2>/dev/null)
    
    if [[ "$actual" =~ $pattern ]]; then
        print_success "Element pattern: $description matches ($actual)"
        return 0
    else
        local failure_reason="XML_PATTERN_MISMATCH_${description// /_}"
        print_failure "Element pattern: $description = '$actual' does not match pattern" "$failure_reason"
        return 1
    fi
}

# Count XML elements
count_xml_elements() {
    local xpath=$1
    xmllint --xpath "count($xpath)" "$RESPONSE_FILE" 2>/dev/null
}

# Display response
show_response() {
    print_info "Response body:"
    xmllint --format "$RESPONSE_FILE" 2>/dev/null || cat "$RESPONSE_FILE"
}

##############################################################################
# Test Suite
##############################################################################

print_header "Banking Composite API - Detailed Test Suite"
echo "Base URL: $BASE_URL"
echo "Client ID: $CLIENT_ID"
echo ""

# Check for xmllint
if ! command -v xmllint &> /dev/null; then
    print_info "xmllint not found - XML validation will be limited"
    print_info "Install with: brew install libxml2 (macOS) or apt-get install libxml2-utils (Linux)"
fi

##############################################################################
# Test 1: Successful Account Summary
##############################################################################

print_test "1. Get Account Summary - Valid Account"
make_request "/account-summary/acc-123456789"

validate_status "200"
validate_xml_content_type

if command -v xmllint &> /dev/null; then
    validate_xml
    
    # Validate Account section
    validate_xml_element "//AccountSummary/Account/AccountId" "Account ID"
    validate_xml_value "//AccountSummary/Account/AccountId" "acc-123456789" "Account ID"
    validate_xml_element "//AccountSummary/Account/AccountNumber" "Account Number"
    validate_xml_element "//AccountSummary/Account/AccountType" "Account Type"
    validate_xml_element "//AccountSummary/Account/Currency" "Currency"
    validate_xml_value "//AccountSummary/Account/Currency" "GBP" "Currency"
    validate_xml_element "//AccountSummary/Account/Status" "Status"
    validate_xml_value "//AccountSummary/Account/Status" "ACTIVE" "Status"
    
    # Validate Balance section
    validate_xml_element "//AccountSummary/Account/Balance/Available" "Available Balance"
    validate_xml_element "//AccountSummary/Account/Balance/Current" "Current Balance"
    
    # Validate Transactions section
    validate_xml_element "//AccountSummary/RecentTransactions" "Recent Transactions"
    
    # Count transactions
    txn_count=$(count_xml_elements "//AccountSummary/RecentTransactions/Transaction")
    ((TOTAL_TESTS++))
    if [ "$txn_count" -gt 0 ]; then
        print_success "Transaction count: $txn_count transactions found"
    else
        local failure_reason="NO_TRANSACTIONS_FOUND"
        print_failure "Transaction count: No transactions found" "$failure_reason"
    fi
    
    # Validate first transaction structure
    if [ "$txn_count" -gt 0 ]; then
        validate_xml_element "//AccountSummary/RecentTransactions/Transaction[1]/TransactionId" "Transaction ID"
        validate_xml_pattern "//AccountSummary/RecentTransactions/Transaction[1]/TransactionId" "^txn-" "Transaction ID format"
        validate_xml_element "//AccountSummary/RecentTransactions/Transaction[1]/Type" "Transaction Type"
        validate_xml_element "//AccountSummary/RecentTransactions/Transaction[1]/Amount" "Transaction Amount"
        validate_xml_element "//AccountSummary/RecentTransactions/Transaction[1]/Currency" "Transaction Currency"
        validate_xml_element "//AccountSummary/RecentTransactions/Transaction[1]/Description" "Transaction Description"
        validate_xml_element "//AccountSummary/RecentTransactions/Transaction[1]/Date" "Transaction Date"
        validate_xml_element "//AccountSummary/RecentTransactions/Transaction[1]/Status" "Transaction Status"
    fi
fi

show_response

##############################################################################
# Test 2: Different Account
##############################################################################

print_test "2. Get Account Summary - Different Account"
make_request "/account-summary/acc-987654321"

validate_status "200"
validate_xml_content_type

if command -v xmllint &> /dev/null; then
    validate_xml
    validate_xml_value "//AccountSummary/Account/AccountId" "acc-987654321" "Account ID"
    validate_xml_value "//AccountSummary/Account/AccountType" "SAVINGS" "Account Type"
fi

show_response

##############################################################################
# Test 3: Invalid Account ID Format
##############################################################################

print_test "3. Invalid Account ID Format"
make_request "/account-summary/invalid-id"

validate_status "400"
validate_xml_content_type

if command -v xmllint &> /dev/null; then
    validate_xml
    validate_xml_element "//Error/Code" "Error Code"
    validate_xml_element "//Error/Message" "Error Message"
    validate_xml_element "//Error/Timestamp" "Error Timestamp"
fi

show_response

##############################################################################
# Test 4: Non-existent Account
##############################################################################

print_test "4. Non-existent Account"
make_request "/account-summary/acc-999999999"

validate_status "404"
validate_xml_content_type

if command -v xmllint &> /dev/null; then
    validate_xml
    validate_xml_element "//Error/Code" "Error Code"
    validate_xml_value "//Error/Code" "ACCOUNT_NOT_FOUND" "Error Code"
    validate_xml_element "//Error/Message" "Error Message"
fi

show_response

##############################################################################
# Test 5: Missing Authentication
##############################################################################

print_test "5. Missing Authentication"
make_request "/account-summary/acc-123456789" ""

validate_status "401"
validate_xml_content_type

if command -v xmllint &> /dev/null; then
    validate_xml
    validate_xml_element "//Error/Code" "Error Code"
    validate_xml_value "//Error/Code" "UNAUTHORIZED" "Error Code"
fi

show_response

##############################################################################
# Test 6: XML Special Characters Handling
##############################################################################

print_test "6. XML Special Characters in Response"
make_request "/account-summary/acc-111222333"

validate_status "200"

if command -v xmllint &> /dev/null; then
    validate_xml
    
    # Check that XML is well-formed even with special characters in descriptions
    ((TOTAL_TESTS++))
    if xmllint --noout "$RESPONSE_FILE" 2>/dev/null; then
        print_success "XML properly escapes special characters"
    else
        local failure_reason="XML_SPECIAL_CHARS_NOT_ESCAPED"
        print_failure "XML contains unescaped special characters" "$failure_reason"
    fi
fi

show_response

##############################################################################
# Test 7: Response Structure Completeness
##############################################################################

print_test "7. Response Structure Completeness"
make_request "/account-summary/acc-444555666"

validate_status "200"

if command -v xmllint &> /dev/null; then
    validate_xml
    
    # Verify all required elements are present
    required_elements=(
        "//AccountSummary"
        "//AccountSummary/Account"
        "//AccountSummary/Account/AccountId"
        "//AccountSummary/Account/AccountNumber"
        "//AccountSummary/Account/AccountType"
        "//AccountSummary/Account/Currency"
        "//AccountSummary/Account/Status"
        "//AccountSummary/Account/Balance"
        "//AccountSummary/Account/Balance/Available"
        "//AccountSummary/Account/Balance/Current"
        "//AccountSummary/RecentTransactions"
    )
    
    for element in "${required_elements[@]}"; do
        validate_xml_element "$element" "$element"
    done
fi

show_response

##############################################################################
# Test 8: Numeric Values Validation
##############################################################################

print_test "8. Numeric Values Validation"
make_request "/account-summary/acc-777888999"

validate_status "200"

if command -v xmllint &> /dev/null; then
    validate_xml
    
    # Validate that balance values are numeric
    available=$(xmllint --xpath "//AccountSummary/Account/Balance/Available/text()" "$RESPONSE_FILE" 2>/dev/null)
    current=$(xmllint --xpath "//AccountSummary/Account/Balance/Current/text()" "$RESPONSE_FILE" 2>/dev/null)
    
    ((TOTAL_TESTS++))
    if [[ "$available" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        print_success "Available balance is numeric: $available"
    else
        local failure_reason="BALANCE_NOT_NUMERIC"
        print_failure "Available balance is not numeric: $available" "$failure_reason"
    fi
    
    ((TOTAL_TESTS++))
    if [[ "$current" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        print_success "Current balance is numeric: $current"
    else
        local failure_reason="BALANCE_NOT_NUMERIC"
        print_failure "Current balance is not numeric: $current" "$failure_reason"
    fi
    
    # Validate transaction amounts are numeric
    txn_count=$(count_xml_elements "//AccountSummary/RecentTransactions/Transaction")
    if [ "$txn_count" -gt 0 ]; then
        amount=$(xmllint --xpath "//AccountSummary/RecentTransactions/Transaction[1]/Amount/text()" "$RESPONSE_FILE" 2>/dev/null)
        ((TOTAL_TESTS++))
        if [[ "$amount" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
            print_success "Transaction amount is numeric: $amount"
        else
            local failure_reason="AMOUNT_NOT_NUMERIC"
            print_failure "Transaction amount is not numeric: $amount" "$failure_reason"
        fi
    fi
fi

show_response

##############################################################################
# Test 9: Date Format Validation
##############################################################################

print_test "9. Date Format Validation"
make_request "/account-summary/acc-123456789"

validate_status "200"

if command -v xmllint &> /dev/null; then
    validate_xml
    
    # Validate ISO 8601 date format in transactions
    txn_count=$(count_xml_elements "//AccountSummary/RecentTransactions/Transaction")
    if [ "$txn_count" -gt 0 ]; then
        date=$(xmllint --xpath "//AccountSummary/RecentTransactions/Transaction[1]/Date/text()" "$RESPONSE_FILE" 2>/dev/null)
        validate_xml_pattern "//AccountSummary/RecentTransactions/Transaction[1]/Date" "^[0-9]{4}-[0-9]{2}-[0-9]{2}T" "ISO 8601 date format"
    fi
fi

show_response

##############################################################################
# Test 10: Transaction Limit
##############################################################################

print_test "10. Transaction Limit (Max 10)"
make_request "/account-summary/acc-123456789"

validate_status "200"

if command -v xmllint &> /dev/null; then
    validate_xml
    
    txn_count=$(count_xml_elements "//AccountSummary/RecentTransactions/Transaction")
    ((TOTAL_TESTS++))
    if [ "$txn_count" -le 10 ]; then
        print_success "Transaction count within limit: $txn_count <= 10"
    else
        local failure_reason="TRANSACTION_COUNT_EXCEEDS_LIMIT"
        print_failure "Transaction count exceeds limit: $txn_count > 10" "$failure_reason"
    fi
fi

show_response

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
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}   All tests passed! ✓${NC}"
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
