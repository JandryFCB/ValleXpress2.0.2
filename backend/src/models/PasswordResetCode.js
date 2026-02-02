const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database'); 

const PasswordResetCode = sequelize.define('PasswordResetCode', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },

  userId: {
    type: DataTypes.UUID,
    allowNull: true,
  },

  email: {
    type: DataTypes.STRING(200),
    allowNull: false,
  },

  codeHash: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },

  expiresAt: {
    type: DataTypes.DATE,
    allowNull: false,
  },

  attempts: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },

  usedAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'password_reset_codes',
  timestamps: true, // createdAt / updatedAt
});

module.exports = PasswordResetCode;
