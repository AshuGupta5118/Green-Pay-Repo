class BillProvider {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String? logoUrl;
  final List<String> supportedFields;
  final bool requiresCustomerNumber;
  final bool requiresConsumerNumber;
  final bool requiresMobileNumber;
  final bool requiresEmailId;

  BillProvider({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.logoUrl,
    this.supportedFields = const [],
    this.requiresCustomerNumber = true,
    this.requiresConsumerNumber = false,
    this.requiresMobileNumber = true,
    this.requiresEmailId = false,
  });

  factory BillProvider.fromJson(Map<String, dynamic> json) {
    return BillProvider(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      supportedFields: List<String>.from(json['supportedFields'] ?? []),
      requiresCustomerNumber: json['requiresCustomerNumber'] ?? true,
      requiresConsumerNumber: json['requiresConsumerNumber'] ?? false,
      requiresMobileNumber: json['requiresMobileNumber'] ?? true,
      requiresEmailId: json['requiresEmailId'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'logoUrl': logoUrl,
      'supportedFields': supportedFields,
      'requiresCustomerNumber': requiresCustomerNumber,
      'requiresConsumerNumber': requiresConsumerNumber,
      'requiresMobileNumber': requiresMobileNumber,
      'requiresEmailId': requiresEmailId,
    };
  }
}
