const { v4: uuidv4 } = require('uuid');

/**
 * Valid API keys for testing
 * In production, these would be stored in a database
 */
const VALID_API_KEYS = [
  '23a16f5215c8ffb1b613fc895921c91d',
  'test-api-key-12345',
  'demo-api-key-67890'
];

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
          message: `Invalid or expired authentication token. Received: ${token.substring(0, 20)}...`,
          timestamp: new Date().toISOString(),
          correlationId: req.headers['x-correlation-id'] || uuidv4()
        }
      });
    }
  }
  
  // Validate API key if provided
  if (apiKey) {
    if (apiKey.length < 10) {
      return res.status(401).json({
        error: {
          code: 'INVALID_CREDENTIALS',
          message: `Invalid API key (too short). Received: ${apiKey}`,
          timestamp: new Date().toISOString(),
          correlationId: req.headers['x-correlation-id'] || uuidv4()
        }
      });
    }
    // Check if API key is in the valid list
    if (!VALID_API_KEYS.includes(apiKey)) {
      return res.status(401).json({
        error: {
          code: 'INVALID_CREDENTIALS',
          message: `Invalid API key. Received: ${apiKey}`,
          timestamp: new Date().toISOString(),
          correlationId: req.headers['x-correlation-id'] || uuidv4()
        }
      });
    }
  }
  
  // Validate Client ID if provided
  if (clientId) {
    if (clientId.length < 10) {
      return res.status(401).json({
        error: {
          code: 'INVALID_CREDENTIALS',
          message: `Invalid Client ID (too short). Received: ${clientId}`,
          timestamp: new Date().toISOString(),
          correlationId: req.headers['x-correlation-id'] || uuidv4()
        }
      });
    }
    // Check if Client ID is in the valid list
    if (!VALID_API_KEYS.includes(clientId)) {
      return res.status(401).json({
        error: {
          code: 'INVALID_CREDENTIALS',
          message: `Invalid Client ID. Received: ${clientId}`,
          timestamp: new Date().toISOString(),
          correlationId: req.headers['x-correlation-id'] || uuidv4()
        }
      });
    }
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
