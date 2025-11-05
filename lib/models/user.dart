class User {
  final String id;
  final String username;
  final String email;
  final String? university;
  final String? studentId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.university,
    this.studentId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      university: json['university'],
      studentId: json['student_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}