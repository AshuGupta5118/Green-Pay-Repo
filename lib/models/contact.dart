class Contact {
  final String id;
  final String userId;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? upiId;
  final bool isFavorite;
  final List<String> recentTransactionIds;
  final DateTime lastInteraction;
  final String? notes;

  Contact({
    required this.id,
    required this.userId,
    required this.name,
    this.phoneNumber,
    this.email,
    this.upiId,
    this.isFavorite = false,
    this.recentTransactionIds = const [],
    required this.lastInteraction,
    this.notes,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      upiId: json['upiId'],
      isFavorite: json['isFavorite'] ?? false,
      recentTransactionIds:
          List<String>.from(json['recentTransactionIds'] ?? []),
      lastInteraction: DateTime.parse(json['lastInteraction']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'upiId': upiId,
      'isFavorite': isFavorite,
      'recentTransactionIds': recentTransactionIds,
      'lastInteraction': lastInteraction.toIso8601String(),
      'notes': notes,
    };
  }

  Contact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? email,
    String? upiId,
    bool? isFavorite,
    List<String>? recentTransactionIds,
    DateTime? lastInteraction,
    String? notes,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      upiId: upiId ?? this.upiId,
      isFavorite: isFavorite ?? this.isFavorite,
      recentTransactionIds: recentTransactionIds ?? this.recentTransactionIds,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      notes: notes ?? this.notes,
    );
  }
}
