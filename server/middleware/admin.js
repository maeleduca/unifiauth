const logger = require('../config/logger');

module.exports = (req, res, next) => {
  if (req.user.role !== 'admin') {
    logger.warn(`Unauthorized admin access attempt by user ${req.user.userId}`);
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
};