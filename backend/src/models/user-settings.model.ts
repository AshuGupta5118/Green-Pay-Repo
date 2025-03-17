import mongoose, { Schema, Document } from 'mongoose';

export interface IUserSettings extends Document {
  userId: mongoose.Types.ObjectId;
  biometricEnabled: boolean;
  notificationsEnabled: boolean;
  themeMode: string;
  notificationPreferences: {
    transactions: boolean;
    security: boolean;
    promotions: boolean;
    system: boolean;
  };
  isBiometricAvailable: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const userSettingsSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    biometricEnabled: {
      type: Boolean,
      default: false,
    },
    notificationsEnabled: {
      type: Boolean,
      default: true,
    },
    themeMode: {
      type: String,
      enum: ['system', 'light', 'dark'],
      default: 'system',
    },
    notificationPreferences: {
      transactions: {
        type: Boolean,
        default: true,
      },
      security: {
        type: Boolean,
        default: true,
      },
      promotions: {
        type: Boolean,
        default: false,
      },
      system: {
        type: Boolean,
        default: true,
      },
    },
    isBiometricAvailable: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

userSettingsSchema.index({ userId: 1 });

export const UserSettings = mongoose.model<IUserSettings>('UserSettings', userSettingsSchema); 
 