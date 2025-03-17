class Bill {
  final String id;
  final String providerId;
  final String providerName;
  final String category;
  final String customerNumber;
  final String? consumerNumber;
  final String mobileNumber;
  final String? emailId;
  final double amount;
  final DateTime dueDate;
  final String status;
  final DateTime? paidDate;
  final String? transactionId;
  final Map<String, dynamic>? metadata;

  Bill({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.category,
    required this.customerNumber,
    this.consumerNumber,
    required this.mobileNumber,
    this.emailId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidDate,
    this.transactionId,
    this.metadata,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      category: json['category'],
      customerNumber: json['customerNumber'],
      consumerNumber: json['consumerNumber'],
      mobileNumber: json['mobileNumber'],
      emailId: json['emailId'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'],
      paidDate:
          json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      transactionId: json['transactionId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'providerName': providerName,
      'category': category,
      'customerNumber': customerNumber,
      'consumerNumber': consumerNumber,
      'mobileNumber': mobileNumber,
      'emailId': emailId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'paidDate': paidDate?.toIso8601String(),
      'transactionId': transactionId,
      'metadata': metadata,
    };
  }

  Bill copyWith({
    String? id,
    String? providerId,
    String? providerName,
    String? category,
    String? customerNumber,
    String? consumerNumber,
    String? mobileNumber,
    String? emailId,
    double? amount,
    DateTime? dueDate,
    String? status,
    DateTime? paidDate,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return Bill(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      category: category ?? this.category,
      customerNumber: customerNumber ?? this.customerNumber,
      consumerNumber: consumerNumber ?? this.consumerNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      emailId: emailId ?? this.emailId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      transactionId: transactionId ?? this.transactionId,
      metadata: metadata ?? this.metadata,
    );
  }
}
