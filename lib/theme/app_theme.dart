import 'package:flutter/cupertino.dart';

class AppTheme {
  static const Color primaryColor = CupertinoColors.systemBlue;
  static const Color secondaryColor = CupertinoColors.systemGreen;
  static const Color errorColor = CupertinoColors.systemRed;
  static const Color backgroundColor = CupertinoColors.systemBackground;
  static const Color secondaryBackgroundColor =
      CupertinoColors.secondarySystemBackground;

  static CupertinoThemeData lightTheme = const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    barBackgroundColor: backgroundColor,
    textTheme: CupertinoTextThemeData(
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.black,
      ),
      textStyle: TextStyle(
        fontSize: 16,
        color: CupertinoColors.black,
      ),
    ),
  );

  static CupertinoThemeData darkTheme = const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: CupertinoColors.black,
    barBackgroundColor: CupertinoColors.black,
    textTheme: CupertinoTextThemeData(
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.white,
      ),
      textStyle: TextStyle(
        fontSize: 16,
        color: CupertinoColors.white,
      ),
    ),
  );

  // Common styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.41,
  );

  static const TextStyle headlineStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.34,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 17,
    letterSpacing: -0.41,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    letterSpacing: 0,
  );

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Common border radius
  static const double borderRadius = 8.0;
  static const double largeBorderRadius = 12.0;
  static BorderRadius standardBorderRadius =
      BorderRadius.circular(borderRadius);
  static BorderRadius largeBorderRadiusOnly =
      BorderRadius.circular(largeBorderRadius);

  // Common padding
  static const EdgeInsets padding = EdgeInsets.all(16.0);
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);

  // Card elevation
  static const double cardElevation = 1.0;
}
