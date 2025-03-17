import { Router } from 'express';
import { UserSettingsController } from '../controllers/user-settings.controller';
import { authenticate } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { userSettingsSchema } from '../schemas/user-settings.schema';

const router = Router();

router.use(authenticate);

router.get('/', UserSettingsController.getSettings);

router.put(
  '/',
  validate(userSettingsSchema.update),
  UserSettingsController.updateSettings,
);

router.put(
  '/notification-preferences',
  validate(userSettingsSchema.updateNotificationPreferences),
  UserSettingsController.updateNotificationPreferences,
);

router.put(
  '/biometric',
  validate(userSettingsSchema.toggleBiometric),
  UserSettingsController.toggleBiometric,
);

router.put(
  '/notifications',
  validate(userSettingsSchema.toggleNotifications),
  UserSettingsController.toggleNotifications,
);

router.put(
  '/theme',
  validate(userSettingsSchema.updateTheme),
  UserSettingsController.updateThemeMode,
);

export default router; 