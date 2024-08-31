import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({Key? key}) : super(key: key);

  @override
  _WeeklyScheduleScreenState createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  List<List<String>> _schedule = [];
  bool _isLoading = false;
  final List<String> _questions = [
    "What are your typical work hours?",
    "Do you like to meditate? If so, how often?",
    "Do you have any medications to take? If yes, what times?",
    "What other activities do you enjoy or need to include in your schedule?",
    "How many hours of sleep do you aim for each night?",
    "Do you have any regular commitments (e.g., classes, meetings)?",
    "What time do you usually wake up and go to bed?",
  ];
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _controllers.addAll(List.generate(_questions.length, (_) => TextEditingController()));
    _loadSchedule();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = prefs.getString('weekly_schedule');
    if (scheduleJson != null) {
      setState(() {
        _schedule = List<List<String>>.from(
          json.decode(scheduleJson).map((day) => List<String>.from(day)),
        );
      });
    }
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weekly_schedule', json.encode(_schedule));
  }

  Future<void> _generateSchedule() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final apiKey = dotenv.env['OPENROUTER_API'];

    if (apiKey == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: API key not found')),
      );
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final userResponses = _controllers.map((controller) => controller.text).toList();
    final prompt = '''
    Based on the following user information, create a well-balanced weekly schedule:
    ${_questions.asMap().entries.map((entry) => "${entry.key + 1}. ${entry.value}\nAnswer: ${userResponses[entry.key]}").join('\n\n')}

    Please provide a schedule for each day of the week (Monday to Sunday). 
    Focus on important activities such as meditation, workouts, medication times, and unique entries.
    Do not include mundane activities like sleep, free time, or routine daily tasks.
    
    Format the response as a list of days, where each day starts with the day name followed by important activities.

    Example format:
    Monday
    1 PM: Meditate
    5 PM: Take medication

    Tuesday
    8 AM: Workout
    5 PM: Take medication

    (Continue for all days of the week)
    ''';

    final body = jsonEncode({
      'model': 'mistralai/mistral-7b-instruct:free',
      'messages': [
        {'role': 'system', 'content': 'You are a helpful AI assistant that creates well-balanced weekly schedules.'},
        {'role': 'user', 'content': prompt},
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Parse the text response into our required format
        final List<List<String>> parsedSchedule = [];
        List<String> currentDay = [];
        
        for (String line in content.split('\n')) {
          if (line.trim().isEmpty) continue;
          if (line.contains(':')) {
            currentDay.add(line.trim());
          } else {
            if (currentDay.isNotEmpty) {
              parsedSchedule.add(currentDay);
            }
            currentDay = [line.trim()];
          }
        }
        if (currentDay.isNotEmpty) {
          parsedSchedule.add(currentDay);
        }

        // Ensure we have 7 days in the schedule
        while (parsedSchedule.length < 7) {
          parsedSchedule.add(['Empty Day']);
        }

        setState(() {
          _schedule = parsedSchedule;
          _isLoading = false;
        });
        await _saveSchedule();
      } else {
        throw Exception('Failed to generate schedule');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _schedule.isEmpty ? null : _generateSchedule,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedule.isEmpty
              ? _buildQuestionnaireForm()
              : _buildScheduleList(),
    );
  }

  Widget _buildQuestionnaireForm() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ..._questions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _controllers[entry.key],
              decoration: InputDecoration(
                labelText: entry.value,
                border: const OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          );
        }).toList(),
        ElevatedButton(
          onPressed: _generateSchedule,
          child: const Text('Generate Schedule'),
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    final List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final currentDayIndex = DateTime.now().weekday - 1; // 0 for Monday, 6 for Sunday

    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final adjustedIndex = (index + currentDayIndex) % 7;
        final day = _schedule[adjustedIndex];
        final dayName = daysOfWeek[adjustedIndex];

        return ExpansionTile(
          title: Text(dayName, style: TextStyle(fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal)),
          initiallyExpanded: index == 0,
          children: day.skip(1).map((activity) {
            final parts = activity.split(':');
            if (parts.length < 2) return const SizedBox.shrink();
            final time = parts[0].trim();
            final description = parts.sublist(1).join(':').trim();
            return ListTile(
              title: Text(description),
              subtitle: Text(time),
            );
          }).toList(),
        );
      },
    );
  }
}