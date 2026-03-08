class UserModel {
  final String id; // This is the auth.users.id (UUID)
  final String name;
  final String email;
  final String role; // 'landlord', 'tenant', 'admin'
  final String? phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  // Create a UserModel instance from a JSON map (e.g., from Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'tenant',
      phone: json['phone'],
    );
  }

  // Convert a UserModel instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }
}