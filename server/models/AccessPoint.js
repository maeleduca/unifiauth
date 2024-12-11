const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const AccessPoint = sequelize.define('AccessPoint', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  mac: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: false
  },
  site: {
    type: DataTypes.STRING,
    allowNull: false
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive'),
    defaultValue: 'active'
  }
});

module.exports = AccessPoint;