class UPIDetails {
  final String id;
  final String upiId;
  final String bankName;
  final String accountNumber;
  final bool isDefault;

  UPIDetails({
    required this.id,
    required this.upiId,
    required this.bankName,
    required this.accountNumber,
    this.isDefault = false,
  });

  factory UPIDetails.fromJson(Map<String, dynamic> json) {
    return UPIDetails(
      id: json['id'] as String,
      upiId: json['upiId'] as String,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'upiId': upiId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
    };
  }

  static String? validateUPIId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter UPI ID';
    }
    if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(value)) {
      return 'Invalid UPI ID format';
    }
    return null;
  }

  static String? validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter account number';
    }
    if (!RegExp(r'^\d{9,18}$').hasMatch(value)) {
      return 'Invalid account number';
    }
    return null;
  }

  UPIDetails copyWith({
    String? id,
    String? upiId,
    String? bankName,
    String? accountNumber,
    bool? isDefault,
  }) {
    return UPIDetails(
      id: id ?? this.id,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
