import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GreenPayUI {
  // Colors
  static const Color primaryColor = Color(0xFF000000);
  static const Color secondaryColor = Color(0xFF34C759);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color successColor = Color(0xFF34C759);

  // Text Styles
  static const String _sfProDisplay = 'SF Pro Display';
  static const String _sfProText = 'SF Pro';
  static const String _sfSymbols = 'SF Symbols';

  static TextStyle get displayLarge => const TextStyle(
        fontFamily: _sfProDisplay,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.37,
        height: 1.2,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: _sfProDisplay,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.36,
        height: 1.2,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: _sfProDisplay,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
        height: 1.2,
      );

  static TextStyle get headingStyle => const TextStyle(
        fontFamily: _sfProDisplay,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontFamily: _sfProText,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.41,
        height: 1.3,
      );

  static TextStyle get calloutStyle => const TextStyle(
        fontFamily: _sfProText,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.32,
        height: 1.3,
      );

  static TextStyle get subheadlineStyle => const TextStyle(
        fontFamily: _sfProText,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.24,
        height: 1.3,
      );

  static TextStyle get footnoteStyle => const TextStyle(
        fontFamily: _sfProText,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.08,
        height: 1.3,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontFamily: _sfProText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.3,
      );

  // SF Symbols
  static const IconData checkmarkCircleFill =
      IconData(0xF3FE, fontFamily: _sfSymbols);
  static const IconData xmarkCircleFill =
      IconData(0xF3FF, fontFamily: _sfSymbols);
  static const IconData plusCircleFill =
      IconData(0xF4E4, fontFamily: _sfSymbols);
  static const IconData minusCircleFill =
      IconData(0xF4E5, fontFamily: _sfSymbols);
  static const IconData infoCircleFill =
      IconData(0xF4E6, fontFamily: _sfSymbols);
  static const IconData questionmarkCircleFill =
      IconData(0xF4E7, fontFamily: _sfSymbols);
  static const IconData exclamationmarkCircleFill =
      IconData(0xF4E8, fontFamily: _sfSymbols);
  static const IconData creditcard = IconData(0xF4E9, fontFamily: _sfSymbols);
  static const IconData creditcardFill =
      IconData(0xF4EA, fontFamily: _sfSymbols);
  static const IconData walletPass = IconData(0xF4EB, fontFamily: _sfSymbols);
  static const IconData walletPassFill =
      IconData(0xF4EC, fontFamily: _sfSymbols);
  static const IconData qrcode = IconData(0xF4ED, fontFamily: _sfSymbols);
  static const IconData qrcodeScan = IconData(0xF4EE, fontFamily: _sfSymbols);
  static const IconData indianrupeesign =
      IconData(0xF4EF, fontFamily: _sfSymbols);
  static const IconData indianrupeesignCircle =
      IconData(0xF4F0, fontFamily: _sfSymbols);
  static const IconData indianrupeesignCircleFill =
      IconData(0xF4F1, fontFamily: _sfSymbols);

  // Animations
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOutCubic;

  // Loading Indicator
  static Widget loadingIndicator({Color? color}) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? primaryColor,
        ),
        strokeWidth: 2.5,
      ),
    );
  }

  // Success Animation
  static Widget successAnimation({VoidCallback? onComplete}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      onEnd: onComplete,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: successColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              checkmarkCircleFill,
              color: Colors.white,
              size: 32 * value,
            ),
          ),
        );
      },
    );
  }

  // Error Message
  static Widget errorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(exclamationmarkCircleFill, color: errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: bodyStyle.copyWith(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  // Page Transition
  static PageRouteBuilder pageTransition({
    required Widget page,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = defaultCurve;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: defaultDuration,
      fullscreenDialog: fullscreenDialog,
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      textStyle: bodyStyle.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
      ),
    );
  }

  // Card Style
  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Loading Overlay
  static Future<T> showLoadingOverlay<T>({
    required BuildContext context,
    required Future<T> Function() future,
    String? message,
  }) async {
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              loadingIndicator(color: Colors.white),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: bodyStyle.copyWith(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    try {
      final result = await future();
      overlayEntry.remove();
      return result;
    } catch (e) {
      overlayEntry.remove();
      rethrow;
    }
  }

  // Success Dialog
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              successAnimation(),
              const SizedBox(height: 24),
              Text(
                title,
                style: headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: primaryButtonStyle(),
                  child: Text(buttonText ?? 'Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Error Dialog
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                xmarkCircleFill,
                color: errorColor,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: primaryButtonStyle(
                    backgroundColor: errorColor,
                  ),
                  child: Text(buttonText ?? 'OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
