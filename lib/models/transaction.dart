enum TransactionType { credit, debit }

enum TransactionCategory {
  food,
  shopping,
  transport,
  entertainment,
  bills,
  others,
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionCategory category;
  final String? description;
  final String? payeeId;
  final String? upiId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.category,
    this.description,
    this.payeeId,
    this.upiId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: TransactionType.values
          .firstWhere((e) => e.toString() == json['type'] as String),
      category: TransactionCategory.values
          .firstWhere((e) => e.toString() == json['category'] as String),
      description: json['description'] as String?,
      payeeId: json['payeeId'] as String?,
      upiId: json['upiId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'category': category.toString(),
      'description': description,
      'payeeId': payeeId,
      'upiId': upiId,
    };
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? timestamp,
    TransactionType? type,
    TransactionCategory? category,
    String? description,
    String? payeeId,
    String? upiId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      payeeId: payeeId ?? this.payeeId,
      upiId: upiId ?? this.upiId,
    );
  }
}
