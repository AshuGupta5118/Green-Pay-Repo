import { Request, Response } from 'express';
import { UserSettings } from '../models/user-settings.model';
import { ApiError } from '../utils/api-error';

export class UserSettingsController {
  static async getSettings(req: Request, res: Response) {
    const userId = req.user!.id;

    let settings = await UserSettings.findOne({ userId });

    if (!settings) {
      settings = await UserSettings.create({ userId });
    }

    res.json({ data: settings });
  }

  static async updateSettings(req: Request, res: Response) {
    const userId = req.user!.id;
    const {
      biometricEnabled,
      notificationsEnabled,
      themeMode,
      notificationPreferences,
      isBiometricAvailable,
    } = req.body;

    const settings = await UserSettings.findOneAndUpdate(
      { userId },
      {
        biometricEnabled,
        notificationsEnabled,
        themeMode,
        notificationPreferences,
        isBiometricAvailable,
      },
      { new: true, upsert: true },
    );

    res.json({ data: settings });
  }

  static async updateNotificationPreferences(req: Request, res: Response) {
    const userId = req.user!.id;
    const { preferences } = req.body;

    const settings = await UserSettings.findOneAndUpdate(
      { userId },
      { notificationPreferences: preferences },
      { new: true },
    );

    if (!settings) {
      throw new ApiError('Settings not found', 404);
    }

    res.json({ data: settings });
  }

  static async toggleBiometric(req: Request, res: Response) {
    const userId = req.user!.id;
    const { enabled } = req.body;

    const settings = await UserSettings.findOneAndUpdate(
      { userId },
      { biometricEnabled: enabled },
      { new: true },
    );

    if (!settings) {
      throw new ApiError('Settings not found', 404);
    }

    res.json({ data: settings });
  }

  static async toggleNotifications(req: Request, res: Response) {
    const userId = req.user!.id;
    const { enabled } = req.body;

    const settings = await UserSettings.findOneAndUpdate(
      { userId },
      { notificationsEnabled: enabled },
      { new: true },
    );

    if (!settings) {
      throw new ApiError('Settings not found', 404);
    }

    res.json({ data: settings });
  }

  static async updateThemeMode(req: Request, res: Response) {
    const userId = req.user!.id;
    const { mode } = req.body;

    if (!['system', 'light', 'dark'].includes(mode)) {
      throw new ApiError('Invalid theme mode', 400);
    }

    const settings = await UserSettings.findOneAndUpdate(
      { userId },
      { themeMode: mode },
      { new: true },
    );

    if (!settings) {
      throw new ApiError('Settings not found', 404);
    }

    res.json({ data: settings });
  }
} 