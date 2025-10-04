import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/task.dart';
import 'widgets/task_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final pixelFont = GoogleFonts.pressStart2p();

    return MaterialApp(
      title: 'Challenge App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        cardColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: Colors.white,
          secondary: Colors.grey,
        ),
        textTheme: TextTheme(
          headlineLarge: pixelFont.copyWith(fontSize: 16, color: Colors.white),
          bodyMedium: pixelFont.copyWith(fontSize: 10, color: Colors.white70),
        ),
        useMaterial3: false, // retro vibe
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pixelFont = GoogleFonts.pressStart2p(
      textStyle: const TextStyle(color: Colors.white),
    );

    final List<Task> challenges = [
      Task(
        id: '1',
        title: 'Morning Workout',
        description: 'Complete a 30-minute morning exercise routine',
        difficulty: TaskDifficulty.easy,
      ),
      Task(
        id: '2',
        title: 'Cook a New Recipe',
        description: 'Try cooking a dish you\'ve never made before',
        difficulty: TaskDifficulty.medium,
      ),
      Task(
        id: '3',
        title: 'Learn a Dance Routine',
        description: 'Master a full choreographed dance routine',
        difficulty: TaskDifficulty.hard,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DA2ILY CHALLENGES',
          style: pixelFont.copyWith(fontSize: 12),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: Colors.grey[800], height: 2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY\'S CHALLENGES',
              style: pixelFont.copyWith(fontSize: 10, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TaskCard(task: challenges[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
