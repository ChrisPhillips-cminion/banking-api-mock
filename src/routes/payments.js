const express = require('express');
const router = express.Router();
const { generatePayment } = require('../utils/mockData');
const { createError } = require('../middleware/errorHandler');

// In-memory storage for demo purposes
const payments = {};

// Initialize with some mock payments with predictable IDs
const predefinedPayments = [
  { id: 'pay-123456789', fromAccount: 'acc-123456789', toBeneficiary: 'ben-987654321', amount: 250.00, status: 'PENDING' },
  { id: 'pay-987654321', fromAccount: 'acc-987654321', toBeneficiary: 'ben-111222333', amount: 500.00, status: 'PENDING' },
  { id: 'pay-111222333', fromAccount: 'acc-111222333', toBeneficiary: 'ben-444555666', amount: 150.00, status: 'COMPLETED' }
];

predefinedPayments.forEach(({ id, fromAccount, toBeneficiary, amount, status }) => {
  const payment = generatePayment(fromAccount, toBeneficiary, amount, id, status);
  payments[payment.paymentId] = payment;
});

/**
 * POST /payments
 * Create a new payment
 */
router.post('/', (req, res, next) => {
  const {
    fromAccountId,
    toBeneficiaryId,
    amount,
    currency,
    paymentType,
    reference,
    scheduledDate,
    urgency = 'NORMAL'
  } = req.body;
  
  // Validation
  if (!fromAccountId || !toBeneficiaryId || !amount || !currency || !paymentType || !reference) {
    return next(createError(400, 'VALIDATION_ERROR', 'Missing required fields', [
      { field: 'fromAccountId', message: 'From account ID is required' },
      { field: 'toBeneficiaryId', message: 'To beneficiary ID is required' },
      { field: 'amount', message: 'Amount is required' },
      { field: 'currency', message: 'Currency is required' },
      { field: 'paymentType', message: 'Payment type is required' },
      { field: 'reference', message: 'Reference is required' }
    ]));
  }
  
  if (amount <= 0) {
    return next(createError(422, 'INVALID_AMOUNT', 'Amount must be greater than zero'));
  }
  
  // Create payment
  const payment = generatePayment(fromAccountId, toBeneficiaryId, amount);
  payment.currency = currency;
  payment.paymentType = paymentType;
  payment.reference = reference;
  payment.scheduledDate = scheduledDate || new Date().toISOString().split('T')[0];
  payment.urgency = urgency;
  
  payments[payment.paymentId] = payment;
  
  res.status(201).json(payment);
});

/**
 * GET /payments/:paymentId
 * Get payment details
 */
router.get('/:paymentId', (req, res, next) => {
  const { paymentId } = req.params;
  
  const payment = payments[paymentId];
  
  if (!payment) {
    return next(createError(404, 'PAYMENT_NOT_FOUND', `Payment ${paymentId} not found`));
  }
  
  res.json(payment);
});

/**
 * PUT /payments/:paymentId/cancel
 * Cancel a payment
 */
router.put('/:paymentId/cancel', (req, res, next) => {
  const { paymentId } = req.params;
  const { reason } = req.body;
  
  const payment = payments[paymentId];
  
  if (!payment) {
    return next(createError(404, 'PAYMENT_NOT_FOUND', `Payment ${paymentId} not found`));
  }
  
  if (payment.status === 'COMPLETED') {
    return next(createError(422, 'PAYMENT_ALREADY_COMPLETED', 'Cannot cancel a completed payment'));
  }
  
  if (!reason || reason.length < 5) {
    return next(createError(400, 'VALIDATION_ERROR', 'Cancellation reason must be at least 5 characters'));
  }
  
  // If already cancelled, return success with current state (idempotent operation)
  if (payment.status === 'CANCELLED') {
    return res.json(payment);
  }
  
  // Update payment status
  payment.status = 'CANCELLED';
  payment.cancelledAt = new Date().toISOString();
  payment.cancellationReason = reason;
  
  res.json(payment);
});

module.exports = router;

// Made with Bob
