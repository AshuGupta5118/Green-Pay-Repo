class PaymentCardData {
  final String id;
  final String cardNumber;
  final String cardHolderName;
  final String bankName;
  final String expiryMonth;
  final String expiryYear;
  final String network;
  final bool isDefault;

  const PaymentCardData({
    required this.id,
    required this.cardNumber,
    required this.cardHolderName,
    required this.bankName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.network,
    this.isDefault = false,
  });

  factory PaymentCardData.fromJson(Map<String, dynamic> json) {
    return PaymentCardData(
      id: json['id'] as String,
      cardNumber: json['cardNumber'] as String,
      cardHolderName: json['cardHolderName'] as String,
      bankName: json['bankName'] as String,
      expiryMonth: json['expiryMonth'] as String,
      expiryYear: json['expiryYear'] as String,
      network: json['network'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'bankName': bankName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'network': network,
      'isDefault': isDefault,
    };
  }

  PaymentCardData copyWith({
    String? id,
    String? cardNumber,
    String? cardHolderName,
    String? bankName,
    String? expiryMonth,
    String? expiryYear,
    String? network,
    bool? isDefault,
  }) {
    return PaymentCardData(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      bankName: bankName ?? this.bankName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      network: network ?? this.network,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
