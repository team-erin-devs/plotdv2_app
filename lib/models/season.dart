class Season {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double timeRemaining; // in seconds

  Season({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.timeRemaining,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'],
      timeRemaining: (json['time_remaining'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'time_remaining': timeRemaining,
    };
  }
}

extension SeasonHelpers on Season {
  Duration get remainingDuration => Duration(seconds: timeRemaining.toInt());

  int get remainingDays => remainingDuration.inDays;

  int get remainingHours => remainingDuration.inHours % 24;

  int get remainingMinutes => remainingDuration.inMinutes % 60;
}