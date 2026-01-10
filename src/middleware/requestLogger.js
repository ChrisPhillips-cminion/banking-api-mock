const { v4: uuidv4 } = require('uuid');

/**
 * Sanitize log output to remove sensitive patterns and unwanted characters
 */
const sanitizeLogOutput = (str) => {
  if (typeof str !== 'string') return str;
  
  // Remove nginx-style worker process patterns like "179#179: *31"
  str = str.replace(/\d+#\d+:\s*\*\d+/g, '[sanitized]');
  
  // Remove potential sensitive patterns
  str = str.replace(/password[=:]\s*\S+/gi, 'password=[REDACTED]');
  str = str.replace(/token[=:]\s*\S+/gi, 'token=[REDACTED]');
  str = str.replace(/secret[=:]\s*\S+/gi, 'secret=[REDACTED]');
  
  // Remove control characters except newlines and tabs
  str = str.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
  
  return str;
};

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

  // Sanitize and log request with authentication info
  const logMessage = `[${req.requestTime}] ${req.method} ${req.path} - Correlation ID: ${req.headers['x-correlation-id']}${authString}`;
  console.log(sanitizeLogOutput(logMessage));

  // Add response headers
  res.setHeader('X-Correlation-Id', req.headers['x-correlation-id']);
  res.setHeader('X-Request-Timestamp', req.requestTime);
  res.setHeader('X-API-Version', '1.0.0');

  next();
};

module.exports = { requestLogger, sanitizeLogOutput };

// Made with Bob
