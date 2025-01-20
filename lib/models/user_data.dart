class UserData {
  String name;
  String email;
  String role;
  String? type;
  // Add other fields as needed

  UserData({required this.name, required this.email, required this.role, this.type = ""});

  factory UserData.fromMap(Map<String, dynamic> data) {
    return UserData(
      name: data['name'],
      email: data['email'],
      role: data['role'],
      type: data['type'],
      // Initialize other fields
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'type': type,
      // Convert other fields to map
    };
  }
}
