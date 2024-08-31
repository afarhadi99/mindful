import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

    Please provide a schedule for each day of the week (Monday to Sunday) with hourly slots from 6 AM to 10 PM. 
    Include activities such as work, meditation, medication times, sleep, and other activities mentioned by the user. 
    Ensure the schedule is well-balanced and provides structure to the user's day.
    
    Format the response as a JSON array of arrays, where each inner array represents a day of the week, 
    and each element in the inner array represents an hour slot with the scheduled activity. 
    Use 'Free time' for unscheduled slots.

    Example format:
    [
      ["Monday", "6 AM: Wake up", "7 AM: Breakfast", "8 AM: Work", ...],
      ["Tuesday", "6 AM: Wake up", "7 AM: Meditation", "8 AM: Work", ...],
      ...
    ]
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
        final scheduleData = jsonDecode(content);
        setState(() {
          _schedule = List<List<String>>.from(
            scheduleData.map((day) => List<String>.from(day)),
          );
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
              : _buildScheduleTable(),
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

  Widget _buildScheduleTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Mon')),
            DataColumn(label: Text('Tue')),
            DataColumn(label: Text('Wed')),
            DataColumn(label: Text('Thu')),
            DataColumn(label: Text('Fri')),
            DataColumn(label: Text('Sat')),
            DataColumn(label: Text('Sun')),
          ],
          rows: List.generate(17, (index) {
            final time = '${index + 6}:00';
            return DataRow(
              cells: [
                DataCell(Text(time)),
                ..._schedule.map((day) {
                  final activity = day[index + 1].split(': ').last;
                  return DataCell(Text(activity));
                }),
              ],
            );
          }),
        ),
      ),
    );
  }
}


