const express = require('express');
const router = express.Router();
const { generateBeneficiary, generatePagination } = require('../utils/mockData');
const { createError } = require('../middleware/errorHandler');

// In-memory storage for demo purposes
const beneficiaries = {};

// Initialize with some mock beneficiaries with predictable IDs
const predefinedBeneficiaries = [
  { id: 'ben-987654321', type: 'INDIVIDUAL' },
  { id: 'ben-111222333', type: 'BUSINESS' },
  { id: 'ben-444555666', type: 'INDIVIDUAL' },
  { id: 'ben-777888999', type: 'BUSINESS' },
  { id: 'ben-123123123', type: 'INDIVIDUAL' }
];

predefinedBeneficiaries.forEach(({ id, type }) => {
  const beneficiary = generateBeneficiary(id, type);
  beneficiaries[beneficiary.beneficiaryId] = beneficiary;
});

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
  
  const errors = [];
  
  // Required field validation
  if (!beneficiaryType) {
    errors.push({ field: 'beneficiaryType', message: 'Beneficiary type is required' });
  } else if (!['INDIVIDUAL', 'BUSINESS'].includes(beneficiaryType)) {
    errors.push({ field: 'beneficiaryType', message: 'Beneficiary type must be INDIVIDUAL or BUSINESS' });
  }
  
  if (!name) {
    errors.push({ field: 'name', message: 'Name is required' });
  } else if (name.length < 2 || name.length > 100) {
    errors.push({ field: 'name', message: 'Name must be between 2 and 100 characters' });
  }
  
  if (!accountNumber) {
    errors.push({ field: 'accountNumber', message: 'Account number is required' });
  } else if (!/^\d{8,17}$/.test(accountNumber)) {
    errors.push({ field: 'accountNumber', message: 'Account number must be 8-17 digits' });
  }
  
  if (!routingNumber) {
    errors.push({ field: 'routingNumber', message: 'Routing number is required' });
  } else if (!/^\d{6,9}$/.test(routingNumber)) {
    errors.push({ field: 'routingNumber', message: 'Routing number must be 6-9 digits' });
  }
  
  if (!bankName) {
    errors.push({ field: 'bankName', message: 'Bank name is required' });
  }
  
  // Optional field validation
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    errors.push({ field: 'email', message: 'Invalid email format' });
  }
  
  if (phone && !/^\+?[\d\s\-()]{10,20}$/.test(phone)) {
    errors.push({ field: 'phone', message: 'Invalid phone number format' });
  }
  
  if (errors.length > 0) {
    return next(createError(400, 'VALIDATION_ERROR', 'Validation failed', errors));
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
  
  // For testing purposes, allow deletion of all beneficiaries
  // In production, this would check for actual pending payments
  delete beneficiaries[beneficiaryId];
  
  res.status(204).send();
});

module.exports = router;

// Made with Bob
