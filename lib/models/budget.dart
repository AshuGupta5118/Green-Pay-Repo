import 'package:flutter/material.dart';

class Budget {
  final String id;
  final String userId;
  final String category;
  final double limit;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limit,
    required this.spent,
    required this.startDate,
    required this.endDate,
    required this.color,
  });

  double get remainingAmount => limit - spent;
  double get spentPercentage => (spent / limit * 100).clamp(0, 100);
  bool get isOverBudget => spent > limit;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['userId'],
      category: json['category'],
      limit: json['limit'].toDouble(),
      spent: json['spent'].toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'limit': limit,
      'spent': spent,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'color': color.value,
    };
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? limit,
    double? spent,
    DateTime? startDate,
    DateTime? endDate,
    Color? color,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
    );
  }
}
