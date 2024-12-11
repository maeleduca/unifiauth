const express = require('express');
const router = express.Router();
const multer = require('multer');
const xlsx = require('xlsx');
const User = require('../models/User');
const AccessPoint = require('../models/AccessPoint');
const auth = require('../middleware/auth');
const admin = require('../middleware/admin');
const unifiController = require('../config/unifi');

const upload = multer({ storage: multer.memoryStorage() });

// Bulk user import
router.post('/users/import', auth, admin, upload.single('file'), async (req, res) => {
  try {
    const workbook = xlsx.read(req.file.buffer);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const users = xlsx.utils.sheet_to_json(sheet);

    for (const user of users) {
      await User.create({
        fullName: user.fullName,
        cpf: user.cpf,
        phone: user.phone,
        email: user.email,
        password: user.password // Will be hashed by model hooks
      });
    }

    res.json({ message: `${users.length} users imported successfully` });
  } catch (error) {
    res.status(500).json({ message: 'Import failed' });
  }
});

// Access point management
router.get('/access-points', auth, admin, async (req, res) => {
  try {
    const devices = await unifiController.getDevices();
    res.json(devices);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch access points' });
  }
});

router.post('/access-points/:mac/restart', auth, admin, async (req, res) => {
  try {
    await unifiController.restartDevice(req.params.mac);
    res.json({ message: 'Device restart initiated' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to restart device' });
  }
});

module.exports = router;