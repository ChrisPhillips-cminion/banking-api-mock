const express = require('express');
const router = express.Router();
const { generateTransaction, generatePagination } = require('../utils/mockData');
const { createError } = require('../middleware/errorHandler');

// In-memory storage for demo purposes
const transactions = {};

// Initialize with some predefined transactions for testing with specific types
// Create 20 DEBIT transactions for acc-123456789 to ensure filtering works correctly
const predefinedTransactions = [];
for (let i = 1; i <= 20; i++) {
  predefinedTransactions.push({
    id: `txn-20260109-${String(i).padStart(3, '0')}`,
    accountId: 'acc-123456789',
    type: 'DEBIT'
  });
}

// Add some transactions for other accounts with different types
predefinedTransactions.push(
  { id: 'txn-20260109-021', accountId: 'acc-987654321', type: 'CREDIT' },
  { id: 'txn-20260109-022', accountId: 'acc-987654321', type: 'DEBIT' },
  { id: 'txn-20260109-023', accountId: 'acc-111222333', type: 'TRANSFER' },
  { id: 'txn-20260109-024', accountId: 'acc-111222333', type: 'CREDIT' }
);

predefinedTransactions.forEach(({ id, accountId, type }) => {
  const transaction = generateTransaction(accountId, id);
  transaction.transactionType = type;
  // Adjust amount sign based on type
  if (type === 'DEBIT' && transaction.amount > 0) {
    transaction.amount = -Math.abs(transaction.amount);
  } else if ((type === 'CREDIT' || type === 'TRANSFER') && transaction.amount < 0) {
    transaction.amount = Math.abs(transaction.amount);
  }
  transactions[transaction.transactionId] = transaction;
});

/**
 * GET /transactions
 * Get list of transactions
 */
router.get('/', (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const {
    accountId,
    startDate,
    endDate,
    transactionType,
    minAmount,
    maxAmount
  } = req.query;
  
  // Validate query parameters
  if (page < 1) {
    return next(createError(400, 'INVALID_PARAMETER', 'Page number must be positive'));
  }
  
  if (limit < 1 || limit > 1000) {
    return next(createError(400, 'INVALID_PARAMETER', 'Limit must be between 1 and 1000'));
  }
  
  // Validate date formats
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (startDate && !dateRegex.test(startDate)) {
    return next(createError(400, 'INVALID_PARAMETER', 'Start date must be in YYYY-MM-DD format'));
  }
  
  if (endDate && !dateRegex.test(endDate)) {
    return next(createError(400, 'INVALID_PARAMETER', 'End date must be in YYYY-MM-DD format'));
  }
  
  let transactionList = Object.values(transactions);
  
  // Filter by account ID
  if (accountId) {
    transactionList = transactionList.filter(txn => txn.accountId === accountId);
  }
  
  // Filter by transaction type
  if (transactionType) {
    transactionList = transactionList.filter(txn => txn.transactionType === transactionType);
  }
  
  // Filter by date range
  if (startDate) {
    transactionList = transactionList.filter(txn =>
      new Date(txn.transactionDate) >= new Date(startDate)
    );
  }
  
  if (endDate) {
    transactionList = transactionList.filter(txn =>
      new Date(txn.transactionDate) <= new Date(endDate)
    );
  }
  
  // Filter by amount range
  if (minAmount) {
    transactionList = transactionList.filter(txn =>
      Math.abs(txn.amount) >= parseFloat(minAmount)
    );
  }
  
  if (maxAmount) {
    transactionList = transactionList.filter(txn =>
      Math.abs(txn.amount) <= parseFloat(maxAmount)
    );
  }
  
  // Sort by date descending
  transactionList.sort((a, b) => new Date(b.transactionDate) - new Date(a.transactionDate));
  
  // Pagination
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + limit;
  const paginatedTransactions = transactionList.slice(startIndex, endIndex);
  
  res.json({
    transactions: paginatedTransactions,
    pagination: generatePagination(page, limit, transactionList.length)
  });
});

/**
 * GET /transactions/:transactionId
 * Get transaction details
 */
router.get('/:transactionId', (req, res, next) => {
  const { transactionId } = req.params;
  
  const transaction = transactions[transactionId];
  
  if (!transaction) {
    return next(createError(404, 'TRANSACTION_NOT_FOUND', `Transaction ${transactionId} not found`));
  }
  
  res.json(transaction);
});

module.exports = router;

// Made with Bob
