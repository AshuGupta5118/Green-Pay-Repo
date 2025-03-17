import 'package:flutter/material.dart';

class UserSettings {
  final bool biometricEnabled;
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final Map<String, bool> notificationPreferences;
  final bool isBiometricAvailable;

  UserSettings({
    this.biometricEnabled = false,
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.system,
    this.notificationPreferences = const {
      'transactions': true,
      'security': true,
      'promotions': false,
      'system': true,
    },
    this.isBiometricAvailable = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      biometricEnabled: json['biometricEnabled'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      notificationPreferences:
          Map<String, bool>.from(json['notificationPreferences'] ?? {}),
      isBiometricAvailable: json['isBiometricAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biometricEnabled': biometricEnabled,
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.index,
      'notificationPreferences': notificationPreferences,
      'isBiometricAvailable': isBiometricAvailable,
    };
  }

  UserSettings copyWith({
    bool? biometricEnabled,
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    Map<String, bool>? notificationPreferences,
    bool? isBiometricAvailable,
  }) {
    return UserSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
    );
  }
}
