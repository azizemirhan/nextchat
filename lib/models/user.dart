class User {
  final int id;
  final String name;
  final String email;
  final String? apiKey;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.apiKey,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      apiKey: json['api_key'],
    );
  }
}