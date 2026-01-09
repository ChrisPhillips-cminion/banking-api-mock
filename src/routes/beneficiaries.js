const express = require('express');
const router = express.Router();
const { generateBeneficiary, generatePagination } = require('../utils/mockData');
const { createError } = require('../middleware/errorHandler');

// In-memory storage for demo purposes
const beneficiaries = {};

// Initialize with some mock beneficiaries
for (let i = 0; i < 10; i++) {
  const beneficiary = generateBeneficiary();
  beneficiaries[beneficiary.beneficiaryId] = beneficiary;
}

/**
 * GET /beneficiaries
 * Get list of beneficiaries
 */
router.get('/', (req, res) => {
  const { page = 1, limit = 20, beneficiaryType, status } = req.query;
  
  let beneficiaryList = Object.values(beneficiaries);
  
  // Filter by beneficiary type
  if (beneficiaryType) {
    beneficiaryList = beneficiaryList.filter(ben => ben.beneficiaryType === beneficiaryType);
  }
  
  // Filter by status
  if (status) {
    beneficiaryList = beneficiaryList.filter(ben => ben.status === status);
  }
  
  // Pagination
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + parseInt(limit);
  const paginatedBeneficiaries = beneficiaryList.slice(startIndex, endIndex);
  
  res.json({
    beneficiaries: paginatedBeneficiaries.map(ben => ({
      beneficiaryId: ben.beneficiaryId,
      beneficiaryType: ben.beneficiaryType,
      name: ben.name,
      nickname: ben.nickname,
      accountNumber: ben.accountNumber,
      bankName: ben.bankName,
      status: ben.status,
      createdAt: ben.createdAt
    })),
    pagination: generatePagination(page, limit, beneficiaryList.length)
  });
});

/**
 * POST /beneficiaries
 * Create a new beneficiary
 */
router.post('/', (req, res, next) => {
  const {
    beneficiaryType,
    name,
    nickname,
    accountNumber,
    routingNumber,
    bankName,
    bankAddress,
    email,
    phone
  } = req.body;
  
  // Validation
  if (!beneficiaryType || !name || !accountNumber || !routingNumber || !bankName) {
    return next(createError(400, 'VALIDATION_ERROR', 'Missing required fields', [
      { field: 'beneficiaryType', message: 'Beneficiary type is required' },
      { field: 'name', message: 'Name is required' },
      { field: 'accountNumber', message: 'Account number is required' },
      { field: 'routingNumber', message: 'Routing number is required' },
      { field: 'bankName', message: 'Bank name is required' }
    ]));
  }
  
  // Create beneficiary
  const beneficiary = generateBeneficiary();
  beneficiary.beneficiaryType = beneficiaryType;
  beneficiary.name = name;
  beneficiary.nickname = nickname || name;
  beneficiary.accountNumber = accountNumber;
  beneficiary.routingNumber = routingNumber;
  beneficiary.bankName = bankName;
  beneficiary.bankAddress = bankAddress || beneficiary.bankAddress;
  beneficiary.email = email || beneficiary.email;
  beneficiary.phone = phone || beneficiary.phone;
  
  beneficiaries[beneficiary.beneficiaryId] = beneficiary;
  
  res.status(201).json(beneficiary);
});

/**
 * GET /beneficiaries/:beneficiaryId
 * Get beneficiary details
 */
router.get('/:beneficiaryId', (req, res, next) => {
  const { beneficiaryId } = req.params;
  
  const beneficiary = beneficiaries[beneficiaryId];
  
  if (!beneficiary) {
    return next(createError(404, 'BENEFICIARY_NOT_FOUND', `Beneficiary ${beneficiaryId} not found`));
  }
  
  res.json(beneficiary);
});

/**
 * PUT /beneficiaries/:beneficiaryId
 * Update beneficiary
 */
router.put('/:beneficiaryId', (req, res, next) => {
  const { beneficiaryId } = req.params;
  const { nickname, email, phone } = req.body;
  
  const beneficiary = beneficiaries[beneficiaryId];
  
  if (!beneficiary) {
    return next(createError(404, 'BENEFICIARY_NOT_FOUND', `Beneficiary ${beneficiaryId} not found`));
  }
  
  // Update fields
  if (nickname) beneficiary.nickname = nickname;
  if (email) beneficiary.email = email;
  if (phone) beneficiary.phone = phone;
  
  res.json(beneficiary);
});

/**
 * DELETE /beneficiaries/:beneficiaryId
 * Delete beneficiary
 */
router.delete('/:beneficiaryId', (req, res, next) => {
  const { beneficiaryId } = req.params;
  
  const beneficiary = beneficiaries[beneficiaryId];
  
  if (!beneficiary) {
    return next(createError(404, 'BENEFICIARY_NOT_FOUND', `Beneficiary ${beneficiaryId} not found`));
  }
  
  // Check if beneficiary has pending payments (mock check)
  const hasPendingPayments = Math.random() > 0.8; // 20% chance of having pending payments
  
  if (hasPendingPayments) {
    return next(createError(422, 'BENEFICIARY_HAS_PENDING_PAYMENTS', 
      'Cannot delete beneficiary with pending payments'));
  }
  
  delete beneficiaries[beneficiaryId];
  
  res.status(204).send();
});

module.exports = router;

// Made with Bob
