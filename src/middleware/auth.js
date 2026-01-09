const { v4: uuidv4 } = require('uuid');

/**
 * Simple authentication middleware for mock API
 * In production, this would validate OAuth tokens
 */
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const apiKey = req.headers['x-api-key'];
  const clientId = req.headers['x-ibm-client-id'];

  // For mock purposes, accept any Bearer token, API key, or IBM Client ID
  // In production, validate against OAuth server or API key database
  if (!authHeader && !apiKey && !clientId) {
    return res.status(401).json({
      error: {
        code: 'UNAUTHORIZED',
        message: 'Authentication required. Please provide a valid Bearer token, API key, or Client ID.',
        timestamp: new Date().toISOString(),
        correlationId: req.headers['x-correlation-id'] || uuidv4()
      }
    });
  }

  // Mock validation - accept any non-empty token
  if (authHeader) {
    const token = authHeader.replace('Bearer ', '');
    if (!token || token.length < 10) {
      return res.status(401).json({
        error: {
          code: 'INVALID_TOKEN',
          message: 'Invalid or expired authentication token',
          timestamp: new Date().toISOString(),
          correlationId: req.headers['x-correlation-id'] || uuidv4()
        }
      });
    }
  }
  
  // Validate API key or Client ID length
  if ((apiKey && apiKey.length < 10) || (clientId && clientId.length < 10)) {
    return res.status(401).json({
      error: {
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid API key or Client ID',
        timestamp: new Date().toISOString(),
        correlationId: req.headers['x-correlation-id'] || uuidv4()
      }
    });
  }

  // Add mock user context
  req.user = {
    userId: 'user-' + uuidv4().substring(0, 8),
    customerId: 'cust-' + uuidv4().substring(0, 8),
    scopes: ['accounts:read', 'accounts:write', 'transactions:read', 'payments:read', 'payments:write', 'beneficiaries:read', 'beneficiaries:write', 'statements:read']
  };

  next();
};

module.exports = { authMiddleware };

// Made with Bob
