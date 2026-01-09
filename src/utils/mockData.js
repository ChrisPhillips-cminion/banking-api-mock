const { v4: uuidv4 } = require('uuid');

/**
 * Generate mock account data
 */
const generateAccount = (accountId = null, type = 'CHECKING') => {
  const id = accountId || `acc-${uuidv4().substring(0, 13)}`;
  const accountNumber = `****${Math.floor(1000 + Math.random() * 9000)}`;
  const fullAccountNumber = `GB${Math.floor(10000000 + Math.random() * 90000000)}${Math.floor(10000000 + Math.random() * 90000000)}`;
  
  return {
    accountId: id,
    accountNumber,
    fullAccountNumber,
    accountType: type,
    currency: 'GBP',
    status: 'ACTIVE',
    nickname: type === 'CHECKING' ? 'Main Account' : type === 'SAVINGS' ? 'Savings Account' : 'Business Account',
    openedDate: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    branch: {
      branchId: `br-${uuidv4().substring(0, 8)}`,
      branchName: 'London Main Branch',
      branchCode: 'LMB001'
    },
    availableBalance: parseFloat((Math.random() * 50000 + 1000).toFixed(2)),
    currentBalance: parseFloat((Math.random() * 50000 + 1000).toFixed(2)),
    overdraftLimit: type === 'CHECKING' ? 1000 : 0,
    interestRate: type === 'SAVINGS' ? 2.5 : 0.1,
    lastTransactionDate: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString()
  };
};

/**
 * Generate mock transaction data
 */
const generateTransaction = (accountId, transactionId = null) => {
  const id = transactionId || `txn-${uuidv4().substring(0, 13)}`;
  const types = ['DEBIT', 'CREDIT', 'TRANSFER', 'PAYMENT', 'FEE'];
  const type = types[Math.floor(Math.random() * types.length)];
  const amount = parseFloat((Math.random() * 500 + 10).toFixed(2));
  
  const merchants = [
    { name: 'Amazon UK', category: 'Shopping', location: 'Online' },
    { name: 'Tesco Superstore', category: 'Groceries', location: 'London, UK' },
    { name: 'Shell Petrol Station', category: 'Fuel', location: 'Manchester, UK' },
    { name: 'Netflix', category: 'Entertainment', location: 'Online' },
    { name: 'Starbucks', category: 'Food & Drink', location: 'Birmingham, UK' }
  ];
  const merchant = merchants[Math.floor(Math.random() * merchants.length)];
  
  return {
    transactionId: id,
    accountId,
    transactionType: type,
    amount: type === 'DEBIT' ? -amount : amount,
    currency: 'GBP',
    description: `${merchant.name} - ${merchant.category}`,
    transactionDate: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
    valueDate: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
    status: 'COMPLETED',
    balance: parseFloat((Math.random() * 10000 + 1000).toFixed(2)),
    merchant,
    metadata: {
      channel: Math.random() > 0.5 ? 'ONLINE' : 'POS',
      cardLast4: Math.floor(1000 + Math.random() * 9000).toString(),
      authorizationCode: `AUTH${Math.floor(100000 + Math.random() * 900000)}`
    }
  };
};

/**
 * Generate mock payment data
 */
const generatePayment = (fromAccountId, toBeneficiaryId, amount, paymentId = null) => {
  const id = paymentId || `pmt-${uuidv4().substring(0, 13)}`;
  const statuses = ['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'];
  const status = statuses[Math.floor(Math.random() * statuses.length)];
  
  return {
    paymentId: id,
    status,
    fromAccountId,
    toBeneficiaryId,
    amount,
    currency: 'GBP',
    paymentType: 'DOMESTIC',
    reference: `Payment ${id.substring(0, 8)}`,
    scheduledDate: new Date().toISOString().split('T')[0],
    createdAt: new Date().toISOString(),
    completedAt: status === 'COMPLETED' ? new Date().toISOString() : null,
    cancelledAt: null,
    estimatedCompletionDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    transactionId: status === 'COMPLETED' ? `txn-${uuidv4().substring(0, 13)}` : null,
    cancellationReason: null
  };
};

/**
 * Generate mock beneficiary data
 */
const generateBeneficiary = (beneficiaryId = null) => {
  const id = beneficiaryId || `ben-${uuidv4().substring(0, 13)}`;
  const types = ['INDIVIDUAL', 'BUSINESS'];
  const type = types[Math.floor(Math.random() * types.length)];
  
  const names = type === 'INDIVIDUAL' 
    ? ['John Smith', 'Sarah Johnson', 'Michael Brown', 'Emma Wilson', 'David Taylor']
    : ['ABC Ltd', 'XYZ Corporation', 'Tech Solutions Inc', 'Global Services Ltd', 'Prime Enterprises'];
  
  const name = names[Math.floor(Math.random() * names.length)];
  
  return {
    beneficiaryId: id,
    beneficiaryType: type,
    name,
    nickname: type === 'INDIVIDUAL' ? name.split(' ')[0] : name.split(' ')[0],
    accountNumber: `${Math.floor(10000000 + Math.random() * 90000000)}`,
    routingNumber: `${Math.floor(100000 + Math.random() * 900000)}`,
    bankName: 'Barclays Bank',
    bankAddress: {
      street: '1 Churchill Place',
      city: 'London',
      state: 'Greater London',
      postalCode: 'E14 5HP',
      country: 'GB'
    },
    email: `${name.toLowerCase().replace(/\s+/g, '.')}@example.com`,
    phone: `+44${Math.floor(1000000000 + Math.random() * 9000000000)}`,
    status: 'ACTIVE',
    createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
    lastUsed: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString()
  };
};

/**
 * Generate mock statement data
 */
const generateStatement = (accountId, statementId = null) => {
  const id = statementId || `stmt-${uuidv4().substring(0, 13)}`;
  const endDate = new Date();
  const startDate = new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);
  
  return {
    statementId: id,
    accountId,
    period: {
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0]
    },
    generatedDate: new Date().toISOString(),
    format: 'PDF',
    size: Math.floor(100000 + Math.random() * 900000),
    status: 'AVAILABLE'
  };
};

/**
 * Generate pagination metadata
 */
const generatePagination = (page = 1, limit = 20, totalRecords = 100) => {
  return {
    page: parseInt(page),
    limit: parseInt(limit),
    totalPages: Math.ceil(totalRecords / limit),
    totalRecords
  };
};

module.exports = {
  generateAccount,
  generateTransaction,
  generatePayment,
  generateBeneficiary,
  generateStatement,
  generatePagination
};

// Made with Bob
