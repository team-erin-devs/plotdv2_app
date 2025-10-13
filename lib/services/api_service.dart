import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/challenge.dart';

  Future<List<Challenge>> fetchChallenge() async {
    final response = await http.get(Uri.parse('https://localhost:8000/api/models/challenges/'));

    if (response.statusCode == 200) {
      List challengeData = json.decode(response.body);
      return challengeData.map((data) => Challenge(
        id: data['id'],
        title: data['title'],
        description: data['description'],
        difficulty: ChallengeDifficulty.values.firstWhere((e) => e.toString() == 'ChallengeDifficulty.' + data['difficulty']),
        points: data['points'],
      )).toList();
    }

    else {
      throw Exception('Failed to fetch models');
    }
  }