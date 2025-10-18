class User {
  final String id;
  final String username;
  final String email;
  final String? university;
  final String? studentId;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.university,
    this.studentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      university: json['university'],
      studentId: json['student_id'],
    );
  }
}