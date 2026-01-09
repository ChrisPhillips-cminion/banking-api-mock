const express = require('express');
const router = express.Router();
const { createError } = require('../middleware/errorHandler');

/**
 * GET /statements/:statementId/download
 * Download a statement
 */
router.get('/:statementId/download', (req, res, next) => {
  const { statementId } = req.params;
  const { format = 'pdf' } = req.query;
  
  // Validate statement ID format
  if (!statementId.startsWith('stmt-')) {
    return next(createError(400, 'INVALID_STATEMENT_ID', 'Invalid statement ID format'));
  }
  
  // List of valid statement IDs (mock data)
  const validStatementIds = [
    'stmt-202401-001',
    'stmt-202401-002',
    'stmt-202312-001',
    'stmt-202312-002',
    'stmt-202311-001'
  ];
  
  // Check if statement exists
  if (!validStatementIds.includes(statementId)) {
    return next(createError(404, 'STATEMENT_NOT_FOUND', `Statement ${statementId} not found`));
  }
  
  // Mock PDF content
  if (format.toLowerCase() === 'pdf') {
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="statement-${statementId}.pdf"`);
    res.send(Buffer.from('Mock PDF content for statement ' + statementId));
  } 
  // Mock CSV content
  else if (format.toLowerCase() === 'csv') {
    const csvContent = `Date,Description,Amount,Balance
2024-01-15,Amazon UK,-45.99,1234.56
2024-01-14,Salary,2500.00,1280.55
2024-01-13,Tesco,-67.23,780.55
2024-01-12,Netflix,-9.99,847.78`;
    
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="statement-${statementId}.csv"`);
    res.send(csvContent);
  } 
  else {
    return next(createError(400, 'INVALID_FORMAT', 'Format must be either pdf or csv'));
  }
});

module.exports = router;

// Made with Bob
