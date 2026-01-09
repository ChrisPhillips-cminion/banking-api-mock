const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const swaggerUi = require('swagger-ui-express');
const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

// Import routes
const healthRoutes = require('./routes/health');
const accountRoutes = require('./routes/accounts');
const transactionRoutes = require('./routes/transactions');
const paymentRoutes = require('./routes/payments');
const beneficiaryRoutes = require('./routes/beneficiaries');
const statementRoutes = require('./routes/statements');

// Import middleware
const { errorHandler } = require('./middleware/errorHandler');
const { requestLogger } = require('./middleware/requestLogger');
const { authMiddleware } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Load OpenAPI specification
let swaggerDocument;
try {
  const yamlPath = path.join(__dirname, '../config/banking-api-openapi.yaml');
  const fileContents = fs.readFileSync(yamlPath, 'utf8');
  swaggerDocument = yaml.load(fileContents);
} catch (e) {
  console.error('Error loading OpenAPI spec:', e);
}

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));
app.use(requestLogger);

// API Documentation
if (swaggerDocument) {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}

// Health check (no auth required)
app.use('/health', healthRoutes);

// Protected routes (require authentication)
app.use('/accounts', authMiddleware, accountRoutes);
app.use('/transactions', authMiddleware, transactionRoutes);
app.use('/payments', authMiddleware, paymentRoutes);
app.use('/beneficiaries', authMiddleware, beneficiaryRoutes);
app.use('/statements', authMiddleware, statementRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Banking Services API Mock',
    version: '1.0.0',
    documentation: '/api-docs',
    endpoints: {
      health: '/health',
      accounts: '/accounts',
      transactions: '/transactions',
      payments: '/payments',
      beneficiaries: '/beneficiaries',
      statements: '/statements'
    }
  });
});

// Error handling
app.use(errorHandler);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'The requested resource was not found',
      timestamp: new Date().toISOString(),
      correlationId: req.headers['x-correlation-id'] || 'N/A'
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Banking API Mock Server running on port ${PORT}`);
  console.log(`API Documentation available at http://localhost:${PORT}/api-docs`);
  console.log(`Health check available at http://localhost:${PORT}/health`);
});

module.exports = app;

// Made with Bob
