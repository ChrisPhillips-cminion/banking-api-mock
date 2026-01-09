const express = require('express');
const router = express.Router();

/**
 * GET /health
 * Health check endpoint - no authentication required
 */
router.get('/', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

module.exports = router;

// Made with Bob
