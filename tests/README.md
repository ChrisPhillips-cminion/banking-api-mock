# Banking API Test Suite

Comprehensive test scripts for validating the Banking API endpoints.

## Test Scripts

### 1. test-all-endpoints.sh
Quick test suite that validates all API endpoints with basic checks.

**Features:**
- Tests all endpoints (accounts, transactions, payments, beneficiaries, statements)
- Validates HTTP status codes
- Tests authentication methods
- Tests error handling
- Provides summary statistics

**Usage:**
```bash
cd tests
chmod +x test-all-endpoints.sh
./test-all-endpoints.sh
```

### 2. test-detailed-validation.sh
Thorough validation suite that performs deep inspection of API responses.

**Features:**
- Validates HTTP status codes
- Validates response headers (Content-Type, etc.)
- Validates JSON structure
- Validates field types (string, number, array, object)
- Validates field values and patterns
- Validates data formats (ISO dates, UUIDs, IDs)
- Validates array lengths
- Validates pagination structure
- Validates error response structure
- Provides detailed pass/fail for each validation

**Usage:**
```bash
cd tests
chmod +x test-detailed-validation.sh
./test-detailed-validation.sh
```

## Configuration

Both scripts use the same configuration at the top of the file:

```bash
# Change this URL to test different servers
BASE_URL="https://small-gw-gateway-cp4i.apps.buttons.hur.hdclab.intranet.ibm.com/c62ce85c-0f44-4dc9-a9ff-c1b702f776b5/sandbox/api.bankingservices.com/v1"

# Authentication credential
CLIENT_ID="23a16f5215c8ffb1b613fc895921c91d"
```

### Testing Different Environments

To test against different environments, simply update the `BASE_URL` variable:

**Local Development:**
```bash
BASE_URL="http://localhost:3000"
```

**OpenShift Route:**
```bash
BASE_URL="https://banking-api-mock-banking-api-mock.apps.bubble.hur.hdclab.intranet.ibm.com"
```

**API Connect Gateway:**
```bash
BASE_URL="https://small-gw-gateway-cp4i.apps.buttons.hur.hdclab.intranet.ibm.com/c62ce85c-0f44-4dc9-a9ff-c1b702f776b5/sandbox/api.bankingservices.com/v1"
```

## Prerequisites

Both scripts require:
- `bash` shell
- `curl` command
- `jq` command (for JSON parsing)

### Installing jq

**macOS:**
```bash
brew install jq
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install jq
```

**Linux (RHEL/CentOS):**
```bash
sudo yum install jq
```

## Test Coverage

### Endpoints Tested

#### Health Check
- `GET /health` - No authentication required

#### Accounts
- `GET /accounts` - List all accounts
- `GET /accounts?page=1&limit=5` - Pagination
- `GET /accounts?accountType=CHECKING` - Filter by type
- `GET /accounts?status=ACTIVE` - Filter by status
- `GET /accounts/{accountId}` - Get account details
- `GET /accounts/{accountId}/balance` - Get balance
- `GET /accounts/{accountId}/transactions` - Get transactions
- `GET /accounts/{accountId}/statements` - Get statements

#### Transactions
- `GET /transactions` - List all transactions
- `GET /transactions?page=1&limit=10` - Pagination
- `GET /transactions?transactionType=DEBIT` - Filter by type
- `GET /transactions?startDate=X&endDate=Y` - Filter by date
- `GET /transactions?minAmount=X&maxAmount=Y` - Filter by amount
- `GET /transactions/{transactionId}` - Get transaction details

#### Payments
- `POST /payments` - Create payment
- `GET /payments/{paymentId}` - Get payment details
- `PUT /payments/{paymentId}/cancel` - Cancel payment

#### Beneficiaries
- `GET /beneficiaries` - List beneficiaries
- `GET /beneficiaries?beneficiaryType=INDIVIDUAL` - Filter by type
- `POST /beneficiaries` - Create beneficiary
- `GET /beneficiaries/{beneficiaryId}` - Get beneficiary details
- `PUT /beneficiaries/{beneficiaryId}` - Update beneficiary
- `DELETE /beneficiaries/{beneficiaryId}` - Delete beneficiary

#### Statements
- `GET /statements/{statementId}/download?format=pdf` - Download PDF
- `GET /statements/{statementId}/download?format=csv` - Download CSV

### Authentication Methods Tested

1. **X-IBM-Client-Id** header (primary authentication method)
2. **No authentication** (401 error validation)

### Error Scenarios Tested

1. **404 Not Found** - Non-existent resources
2. **401 Unauthorized** - Missing authentication
3. **400 Bad Request** - Invalid data
4. **Invalid endpoints** - Non-existent paths

## Validation Details (test-detailed-validation.sh)

The detailed validation script checks:

### Response Structure
- Valid JSON format
- Correct Content-Type header
- Expected HTTP status codes

### Field Validation
- **Existence**: Required fields are present
- **Type**: Fields have correct data types (string, number, array, object)
- **Value**: Fields contain expected values
- **Format**: Fields match expected patterns

### Pattern Validation
- **Account IDs**: `acc-XXXXXXXXX` format
- **Transaction IDs**: `txn-YYYYMMDD-XXX` format
- **Payment IDs**: `pay-XXXXXXXXX` format
- **Beneficiary IDs**: `ben-XXXXXXXXX` format
- **ISO Dates**: `YYYY-MM-DDTHH:MM:SS` format
- **UUIDs**: Standard UUID format

### Pagination Validation
- Page number is correct
- Limit is respected
- Total pages calculated correctly
- Total records count is present

### Array Validation
- Arrays contain expected minimum number of items
- Array items have correct structure
- Nested objects are properly formatted

## Output

Both scripts provide color-coded output:
- 🟢 **Green**: Passed tests/validations
- 🔴 **Red**: Failed tests/validations
- 🟡 **Yellow**: Informational messages
- 🔵 **Blue**: Section headers
- 🔷 **Cyan**: Test descriptions

### Example Output

```
========================================
Banking API - Detailed Validation Test Suite
========================================

TEST: 1. Health Check Endpoint - GET /health
  ✓ HTTP Status: 200 (expected: 200)
  ✓ Content-Type: application/json
  ✓ Valid JSON structure
  ✓ Field exists: .status = UP
  ✓ Field value: .status = UP
  ✓ Field exists: .timestamp = 2026-01-09T18:00:00.000Z
  ✓ Field pattern: .timestamp matches ISO 8601 date format
  ✓ Field exists: .version = 1.0.0

========================================
Test Summary
========================================

Total Validations: 150
Passed:            148
Failed:            2

Pass rate: 98%
```

## Continuous Integration

These scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run API Tests
  run: |
    cd tests
    chmod +x test-all-endpoints.sh
    ./test-all-endpoints.sh
```

```yaml
# Example Jenkins Pipeline
stage('API Tests') {
    steps {
        sh '''
            cd tests
            chmod +x test-detailed-validation.sh
            ./test-detailed-validation.sh
        '''
    }
}
```

## Troubleshooting

### Script Permission Denied
```bash
chmod +x test-all-endpoints.sh
chmod +x test-detailed-validation.sh
```

### jq Command Not Found
Install jq using your package manager (see Prerequisites section)

### Connection Refused
- Verify the BASE_URL is correct
- Ensure the API server is running
- Check network connectivity
- Verify firewall rules

### Authentication Failures
- Update CLIENT_ID, API_KEY, or BEARER_TOKEN in the script
- Verify the authentication method is supported by the server
- Check if the credentials are valid

### SSL Certificate Errors
Add `-k` flag to curl commands in the scripts:
```bash
curl -k -s -D "$HEADERS_FILE" ...
```

## Contributing

To add new tests:

1. Add test function in the appropriate section
2. Use the helper functions for validation
3. Follow the existing pattern for consistency
4. Update this README with new test coverage

## Support

For issues or questions:
- Check the main project README
- Review API documentation at `/api-docs`
- Contact: api-support@bankingservices.com