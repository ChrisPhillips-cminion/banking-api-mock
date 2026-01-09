const { v4: uuidv4 } = require('uuid');

/**
 * Global error handler middleware
 */
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  const correlationId = req.headers['x-correlation-id'] || uuidv4();
  const timestamp = new Date().toISOString();

  // Default error response
  let statusCode = err.statusCode || 500;
  let errorResponse = {
    error: {
      code: err.code || 'INTERNAL_SERVER_ERROR',
      message: err.message || 'An unexpected error occurred',
      timestamp,
      correlationId
    }
  };

  // Add details if available
  if (err.details) {
    errorResponse.error.details = err.details;
  }

  res.status(statusCode).json(errorResponse);
};

/**
 * Create a custom error
 */
const createError = (statusCode, code, message, details = null) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  if (details) {
    error.details = details;
  }
  return error;
};

module.exports = { errorHandler, createError };

// Made with Bob
