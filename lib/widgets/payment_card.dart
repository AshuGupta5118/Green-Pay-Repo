import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/card.dart';
import '../utils/animation_config.dart';
import 'animated_card.dart';
import 'ui_components.dart';

class PaymentCard extends StatelessWidget {
  final PaymentCardData card;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PaymentCard({
    Key? key,
    required this.card,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  String get _maskedCardNumber {
    final last4 = card.cardNumber.substring(card.cardNumber.length - 4);
    return '•••• •••• •••• $last4';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      isSelected: isSelected,
      onTap: onTap,
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Stack(
          children: [
            // Card Network Logo
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/${card.network.toLowerCase()}_logo.png',
                    height: 40,
                  ).animate().custom(
                        duration: AnimationConfig.standard,
                        curve: AnimationConfig.spring,
                        builder: (context, value, child) => Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: child,
                        ),
                      ),
                  if (card.isDefault) ...[
                    const SizedBox(width: 8),
                    Icon(
                      GreenPayUI.checkmarkCircleFill,
                      color: GreenPayUI.successColor,
                      size: 20,
                    )
                        .animate()
                        .custom(
                          duration: AnimationConfig.quick,
                          curve: AnimationConfig.spring,
                          builder: (context, value, child) => Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: child,
                          ),
                        )
                        .custom(
                          duration: AnimationConfig.quick,
                          curve: AnimationConfig.standardCurve,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: child,
                          ),
                        ),
                  ],
                ],
              ),
            ),

            // Card Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bank Name
                Text(
                  card.bankName,
                  style: GreenPayUI.calloutStyle.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().custom(
                      duration: AnimationConfig.standard,
                      curve: AnimationConfig.spring,
                      builder: (context, value, child) => Transform.translate(
                        offset: Offset(20 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      ),
                    ),

                // Card Number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _maskedCardNumber,
                      style: GreenPayUI.displaySmall.copyWith(
                        letterSpacing: 2,
                        fontFamily: 'SF Pro',
                      ),
                    ).animate().custom(
                          duration: AnimationConfig.standard,
                          curve: AnimationConfig.spring,
                          builder: (context, value, child) =>
                              Transform.translate(
                            offset: Offset(30 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          ),
                        ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          GreenPayUI.creditcardFill,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Expires ${card.expiryMonth}/${card.expiryYear}',
                          style: GreenPayUI.footnoteStyle.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ).animate().custom(
                          duration: AnimationConfig.standard,
                          curve: AnimationConfig.spring,
                          builder: (context, value, child) =>
                              Transform.translate(
                            offset: Offset(40 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          ),
                        ),
                  ],
                ),

                // Card Holder Name
                Text(
                  card.cardHolderName.toUpperCase(),
                  style: GreenPayUI.calloutStyle.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ).animate().custom(
                      duration: AnimationConfig.standard,
                      curve: AnimationConfig.spring,
                      builder: (context, value, child) => Transform.translate(
                        offset: Offset(50 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
