const User = require('../server/models/User');
const sequelize = require('../server/config/database');
require('dotenv').config();

async function createAdmin() {
  try {
    await sequelize.sync();
    
    const admin = await User.create({
      fullName: 'Administrador',
      cpf: '00000000000',
      phone: '0000000000',
      email: 'admin@example.com',
      password: 'admin123',
      role: 'admin'
    });

    console.log('Admin user created successfully!');
    console.log('Email: admin@example.com');
    console.log('Password: admin123');
    console.log('\nPlease change these credentials after first login!');
    
    process.exit(0);
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
}

createAdmin();