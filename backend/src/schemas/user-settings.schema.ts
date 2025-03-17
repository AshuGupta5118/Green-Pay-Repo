import Joi from 'joi';

export const userSettingsSchema = {
  update: Joi.object({
    biometricEnabled: Joi.boolean(),
    notificationsEnabled: Joi.boolean(),
    themeMode: Joi.string().valid('system', 'light', 'dark'),
    notificationPreferences: Joi.object({
      transactions: Joi.boolean(),
      security: Joi.boolean(),
      promotions: Joi.boolean(),
      system: Joi.boolean(),
    }),
    isBiometricAvailable: Joi.boolean(),
  }),

  updateNotificationPreferences: Joi.object({
    preferences: Joi.object({
      transactions: Joi.boolean().required(),
      security: Joi.boolean().required(),
      promotions: Joi.boolean().required(),
      system: Joi.boolean().required(),
    }).required(),
  }),

  toggleBiometric: Joi.object({
    enabled: Joi.boolean().required(),
  }),

  toggleNotifications: Joi.object({
    enabled: Joi.boolean().required(),
  }),

  updateTheme: Joi.object({
    mode: Joi.string().valid('system', 'light', 'dark').required(),
  }),
}; 