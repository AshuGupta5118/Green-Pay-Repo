import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _otpSent = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.verifyPhone(_phoneController.text);
      if (mounted) {
        if (success) {
          setState(() {
            _otpSent = true;
          });
          _showSuccessMessage('OTP sent successfully');
        } else {
          _showErrorMessage('Failed to send OTP');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _otpController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.login(
        _phoneController.text,
        _otpController.text,
      );

      if (mounted) {
        if (success) {
          // Animate out before navigation
          _animationController.reverse().then((_) {
            Navigator.pushReplacement(
              context,
              _createRoute(const HomeScreen()),
            );
          });
        } else {
          _showErrorMessage('Invalid OTP');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    _showMessage(message, CupertinoColors.activeGreen);
  }

  void _showErrorMessage(String message) {
    _showMessage(message, CupertinoColors.destructiveRed);
  }

  void _showMessage(String message, Color color) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      'Welcome to\nGreen Pay',
                      style: AppTheme.titleStyle.copyWith(
                        color: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to continue',
                      style: AppTheme.bodyStyle.copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      placeholder: 'Phone Number',
                      prefix: const Text(
                        '+91 ',
                        style: TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.label,
                        ),
                      ),
                      enabled: !_otpSent,
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        placeholder: 'OTP',
                      ),
                    ],
                    const SizedBox(height: 24),
                    CustomButton(
                      text: _otpSent ? 'Login' : 'Send OTP',
                      onPressed: _isLoading
                          ? null
                          : (_otpSent ? _login : _verifyPhone),
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
                    const Spacer(),
                    Center(
                      child: CupertinoButton(
                        onPressed: () {
                          // TODO: Navigate to registration screen
                        },
                        child: Text(
                          'Don\'t have an account? Sign Up',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom page route with Apple-like transition
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: AppTheme.mediumAnimation,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve))
            .animate(animation);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}
