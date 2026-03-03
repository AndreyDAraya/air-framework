/// User model returned by JSONPlaceholder API
class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String website;
  final String company;
  final String city;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
    required this.company,
    required this.city,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      company:
          (json['company'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      city:
          (json['address'] as Map<String, dynamic>?)?['city'] as String? ?? '',
    );
  }
}
