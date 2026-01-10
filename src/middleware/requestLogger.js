const { v4: uuidv4 } = require('uuid');

/**
 * Request logging and correlation ID middleware
 */
const requestLogger = (req, res, next) => {
  // Add correlation ID if not present
  if (!req.headers['x-correlation-id']) {
    req.headers['x-correlation-id'] = uuidv4();
  }

  // Add request timestamp
  req.requestTime = new Date().toISOString();

  // Extract authentication info for logging
  const authInfo = [];
  if (req.headers.authorization) {
    const token = req.headers.authorization.replace('Bearer ', '');
    authInfo.push(`Bearer: ${token.substring(0, 10)}...`);
  }
  if (req.headers['x-api-key']) {
    authInfo.push(`API-Key: ${req.headers['x-api-key']}`);
  }
  if (req.headers['x-ibm-client-id']) {
    authInfo.push(`Client-ID: ${req.headers['x-ibm-client-id']}`);
  }
  
  const authString = authInfo.length > 0 ? ` | Auth: ${authInfo.join(', ')}` : '';

  // Log request with authentication info
  console.log(`[${req.requestTime}] ${req.method} ${req.path} - Correlation ID: ${req.headers['x-correlation-id']}${authString}`);

  // Add response headers
  res.setHeader('X-Correlation-Id', req.headers['x-correlation-id']);
  res.setHeader('X-Request-Timestamp', req.requestTime);
  res.setHeader('X-API-Version', '1.0.0');

  next();
};

module.exports = { requestLogger };

// Made with Bob
