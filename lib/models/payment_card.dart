import 'package:flutter/material.dart';

class PaymentCard {
  final String id;
  final String bank;
  final String type;
  final String number;
  final String expiry;
  final String name;
  final Color color;
  final Color textColor;

  PaymentCard({
    required this.id,
    required this.bank,
    required this.type,
    required this.number,
    required this.expiry,
    required this.name,
    required this.color,
    required this.textColor,
  });

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'] as String,
      bank: json['bank'] as String,
      type: json['type'] as String,
      number: json['number'] as String,
      expiry: json['expiry'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      textColor: Color(json['textColor'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank': bank,
      'type': type,
      'number': number,
      'expiry': expiry,
      'name': name,
      'color': color.value,
      'textColor': textColor.value,
    };
  }

  String get maskedNumber {
    if (number.length != 16) return number;
    return '**** **** **** ${number.substring(12)}';
  }

  String get cardTypeImage {
    switch (type.toLowerCase()) {
      case 'visa':
        return 'assets/images/visa.png';
      case 'mastercard':
        return 'assets/images/mastercard.png';
      case 'amex':
        return 'assets/images/amex.png';
      default:
        return 'assets/images/card.png';
    }
  }

  bool get isValid {
    if (number.length != 16) return false;
    if (expiry.length != 5) return false;

    final now = DateTime.now();
    final expiryParts = expiry.split('/');
    if (expiryParts.length != 2) return false;

    try {
      final expiryMonth = int.parse(expiryParts[0]);
      final expiryYear = 2000 + int.parse(expiryParts[1]);
      final expiryDate = DateTime(expiryYear, expiryMonth + 1, 0);

      return expiryDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  static String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    if (value.length != 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  static String? validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Invalid format (MM/YY)';
    }

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null || month < 1 || month > 12) {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final cardDate = DateTime(2000 + year, month);
    if (cardDate.isBefore(now)) {
      return 'Card has expired';
    }

    return null;
  }

  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    if (value.length < 3 || value.length > 4) {
      return 'CVV must be 3 or 4 digits';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter name on card';
    }
    if (value.length < 3) {
      return 'Name is too short';
    }
    return null;
  }
}
