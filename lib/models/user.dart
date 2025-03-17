class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;

  User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
    };
  }

  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
