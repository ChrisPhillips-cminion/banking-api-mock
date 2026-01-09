const express = require('express');
const router = express.Router();
const { generatePayment } = require('../utils/mockData');
const { createError } = require('../middleware/errorHandler');

// In-memory storage for demo purposes
const payments = {};

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
  
  if (payment.status === 'CANCELLED') {
    return next(createError(422, 'PAYMENT_ALREADY_CANCELLED', 'Payment is already cancelled'));
  }
  
  if (!reason || reason.length < 5) {
    return next(createError(400, 'VALIDATION_ERROR', 'Cancellation reason must be at least 5 characters'));
  }
  
  // Update payment status
  payment.status = 'CANCELLED';
  payment.cancelledAt = new Date().toISOString();
  payment.cancellationReason = reason;
  
  res.json(payment);
});

module.exports = router;

// Made with Bob
