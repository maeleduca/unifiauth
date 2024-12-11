const xlsx = require('xlsx');
const { validateCPF, validateEmail, validatePhone } = require('./validators');
const logger = require('../config/logger');

const parseExcelUsers = (buffer) => {
  try {
    const workbook = xlsx.read(buffer);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const users = xlsx.utils.sheet_to_json(sheet);

    const validUsers = [];
    const errors = [];

    users.forEach((user, index) => {
      const rowNumber = index + 2; // Excel starts at 1 and has header
      const error = validateUser(user, rowNumber);
      
      if (error) {
        errors.push(error);
      } else {
        validUsers.push(user);
      }
    });

    return { validUsers, errors };
  } catch (error) {
    logger.error('Excel parsing error:', error);
    throw new Error('Invalid Excel file format');
  }
};

const validateUser = (user, rowNumber) => {
  if (!user.fullName?.trim()) {
    return { row: rowNumber, message: 'Nome completo é obrigatório' };
  }
  
  if (!user.cpf || !validateCPF(user.cpf)) {
    return { row: rowNumber, message: 'CPF inválido' };
  }
  
  if (!user.phone || !validatePhone(user.phone)) {
    return { row: rowNumber, message: 'Telefone inválido' };
  }
  
  if (!user.email || !validateEmail(user.email)) {
    return { row: rowNumber, message: 'Email inválido' };
  }
  
  if (!user.password || user.password.length < 8) {
    return { row: rowNumber, message: 'Senha deve ter no mínimo 8 caracteres' };
  }
  
  return null;
};

module.exports = {
  parseExcelUsers
};