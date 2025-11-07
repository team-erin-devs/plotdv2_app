import 'user.dart';

class UserProfile {
  final User user;
  final int totalPoints;
  final String? university;
  final String? studentId;
  final DateTime createdAt;

  UserProfile({
    required this.user,
    required this.totalPoints,
    this.university,
    this.studentId,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      user: User.fromJson(json['user']),
      totalPoints: json['total_points'] ?? 0,
      university: json['university'],
      studentId: json['student_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'first_name': user.firstName,
        'last_name': user.lastName,
      },
      'total_points': totalPoints,
      'university': university,
      'student_id': studentId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}