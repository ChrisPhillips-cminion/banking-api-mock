const express = require('express');
const router = express.Router();
const { generateAccount, generatePagination } = require('../utils/mockData');
const { createError } = require('../middleware/errorHandler');

// In-memory storage for demo purposes
const accounts = {};

// Initialize with some mock accounts with predictable IDs
const predefinedAccounts = [
  { id: 'acc-123456789', type: 'CHECKING' },
  { id: 'acc-987654321', type: 'SAVINGS' },
  { id: 'acc-111222333', type: 'BUSINESS' },
  { id: 'acc-444555666', type: 'CHECKING' },
  { id: 'acc-777888999', type: 'SAVINGS' }
];

predefinedAccounts.forEach(({ id, type }) => {
  const account = generateAccount(id, type);
  accounts[account.accountId] = account;
});

/**
 * GET /accounts
 * Get list of accounts
 */
router.get('/', (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const { accountType } = req.query;
  
  // Validate query parameters
  if (page < 1) {
    return next(createError(400, 'INVALID_PARAMETER', 'Page number must be positive'));
  }
  
  if (limit < 1 || limit > 1000) {
    return next(createError(400, 'INVALID_PARAMETER', 'Limit must be between 1 and 1000'));
  }
  
  let accountList = Object.values(accounts);
  
  // Filter by account type if provided
  if (accountType) {
    accountList = accountList.filter(acc => acc.accountType === accountType);
  }
  
  // Pagination
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  const paginatedAccounts = accountList.slice(startIndex, endIndex);
  
  res.json({
    accounts: paginatedAccounts.map(acc => ({
      accountId: acc.accountId,
      accountNumber: acc.accountNumber,
      accountType: acc.accountType,
      currency: acc.currency,
      status: acc.status,
      nickname: acc.nickname,
      openedDate: acc.openedDate
    })),
    pagination: generatePagination(page, limit, accountList.length)
  });
});

/**
 * GET /accounts/:accountId
 * Get account details
 */
router.get('/:accountId', (req, res, next) => {
  const { accountId } = req.params;
  
  // Validate account ID format
  if (!accountId.match(/^acc-\d{9}$/)) {
    return next(createError(400, 'INVALID_ACCOUNT_ID', 'Invalid account ID format. Expected format: acc-XXXXXXXXX'));
  }
  
  const account = accounts[accountId];
  
  if (!account) {
    return next(createError(404, 'NOT_FOUND', `Account ${accountId} not found`));
  }
  
  // Return account with additional fields for compatibility
  res.json({
    ...account,
    balance: account.currentBalance,  // Add balance field (alias for currentBalance)
    lastActivityDate: account.lastTransactionDate  // Add lastActivityDate (alias for lastTransactionDate)
  });
});

/**
 * GET /accounts/:accountId/balance
 * Get account balance
 */
router.get('/:accountId/balance', (req, res, next) => {
  const { accountId } = req.params;
  
  // Validate account ID format
  if (!accountId.match(/^acc-\d{9}$/)) {
    return next(createError(400, 'INVALID_ACCOUNT_ID', 'Invalid account ID format. Expected format: acc-XXXXXXXXX'));
  }
  
  const account = accounts[accountId];
  
  if (!account) {
    return next(createError(404, 'NOT_FOUND', `Account ${accountId} not found`));
  }
  
  res.json({
    accountId: account.accountId,
    currency: account.currency,
    balance: account.currentBalance,  // Add balance field for test compatibility
    availableBalance: account.availableBalance,
    currentBalance: account.currentBalance,
    pendingBalance: 0,
    overdraftLimit: account.overdraftLimit,
    asOfDate: new Date().toISOString(),  // Add asOfDate field for test compatibility
    lastUpdated: new Date().toISOString()
  });
});

/**
 * GET /accounts/:accountId/transactions
 * Get transactions for a specific account
 */
router.get('/:accountId/transactions', (req, res, next) => {
  const { accountId } = req.params;
  const { page = 1, limit = 20, startDate, endDate } = req.query;
  
  // Validate account ID format
  if (!accountId.match(/^acc-\d{9}$/)) {
    return next(createError(400, 'INVALID_ACCOUNT_ID', 'Invalid account ID format. Expected format: acc-XXXXXXXXX'));
  }
  
  const account = accounts[accountId];
  
  if (!account) {
    return next(createError(404, 'ACCOUNT_NOT_FOUND', `Account ${accountId} not found`));
  }
  
  // Generate mock transactions
  const { generateTransaction } = require('../utils/mockData');
  const totalTransactions = 50;
  const transactions = [];
  
  for (let i = 0; i < Math.min(totalTransactions, limit); i++) {
    transactions.push(generateTransaction(accountId));
  }
  
  // Sort by date descending
  transactions.sort((a, b) => new Date(b.transactionDate) - new Date(a.transactionDate));
  
  res.json({
    transactions,
    pagination: generatePagination(page, limit, totalTransactions)
  });
});

/**
 * GET /accounts/:accountId/statements
 * Get statements for a specific account
 */
router.get('/:accountId/statements', (req, res, next) => {
  const { accountId } = req.params;
  const { year, month } = req.query;
  
  // Validate account ID format
  if (!accountId.match(/^acc-\d{9}$/)) {
    return next(createError(400, 'INVALID_ACCOUNT_ID', 'Invalid account ID format. Expected format: acc-XXXXXXXXX'));
  }
  
  const account = accounts[accountId];
  
  if (!account) {
    return next(createError(404, 'ACCOUNT_NOT_FOUND', `Account ${accountId} not found`));
  }
  
  // Generate mock statements
  const { generateStatement } = require('../utils/mockData');
  const statements = [];
  
  // Generate statements for last 12 months
  for (let i = 0; i < 12; i++) {
    statements.push(generateStatement(accountId));
  }
  
  res.json({ statements });
});

module.exports = router;

// Made with Bob
