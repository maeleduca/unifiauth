const { Controller } = require('node-unifi');
const logger = require('./logger');
require('dotenv').config();

class UniFiController {
  constructor() {
    this.controller = new Controller({
      host: process.env.UNIFI_HOST,
      port: process.env.UNIFI_PORT,
      username: process.env.UNIFI_USERNAME,
      password: process.env.UNIFI_PASSWORD,
      site: process.env.UNIFI_SITE_ID,
      ssl: process.env.UNIFI_SSL === 'true'
    });
  }

  async connect() {
    try {
      await this.controller.login();
      logger.info('Connected to UniFi Controller');
    } catch (error) {
      logger.error('Failed to connect to UniFi Controller:', error);
      throw error;
    }
  }

  async getDevices() {
    try {
      return await this.controller.getDevices();
    } catch (error) {
      logger.error('Failed to get devices:', error);
      throw error;
    }
  }

  async restartDevice(mac) {
    try {
      await this.controller.restartDevice(mac);
      logger.info(`Device ${mac} restart initiated`);
    } catch (error) {
      logger.error(`Failed to restart device ${mac}:`, error);
      throw error;
    }
  }
}

const unifiController = new UniFiController();
unifiController.connect();

module.exports = unifiController;