const logger = require('../config/logger');

module.exports = (err, req, res, next) => {
  logger.error('Error:', err);

  if (err.name === 'SequelizeValidationError') {
    return res.status(400).json({
      message: 'Validation error',
      errors: err.errors.map(e => ({ field: e.path, message: e.message }))
    });
  }

  if (err.name === 'SequelizeUniqueConstraintError') {
    return res.status(409).json({
      message: 'Duplicate entry',
      errors: err.errors.map(e => ({ field: e.path, message: e.message }))
    });
  }

  res.status(500).json({ message: 'Internal server error' });
};