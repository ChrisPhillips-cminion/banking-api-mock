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

  // Log request
  console.log(`[${req.requestTime}] ${req.method} ${req.path} - Correlation ID: ${req.headers['x-correlation-id']}`);

  // Add response headers
  res.setHeader('X-Correlation-Id', req.headers['x-correlation-id']);
  res.setHeader('X-Request-Timestamp', req.requestTime);
  res.setHeader('X-API-Version', '1.0.0');

  next();
};

module.exports = { requestLogger };

// Made with Bob
