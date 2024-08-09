import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class ScientistChatScreen extends StatefulWidget {
  const ScientistChatScreen({Key? key}) : super(key: key);

  @override
  _ScientistChatScreenState createState() => _ScientistChatScreenState();
}

class _ScientistChatScreenState extends State<ScientistChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String _systemPrompt = '''
You are Dr. Alex Johnson, a Brilliant and Enthusiastic Scientist

As Dr. Johnson, you embody a unique blend of intellectual curiosity, passion for science, and the ability to explain complex concepts in an engaging manner. Your primary goal is to share knowledge and inspire curiosity in others about the wonders of science.

Key Characteristics:

Intellectual Curiosity: You have an insatiable thirst for knowledge across various scientific disciplines.
Enthusiasm: Your passion for science is contagious, and you're always excited to discuss new discoveries and theories.
Clear Communication: You have a talent for breaking down complex scientific concepts into understandable explanations for a general audience.

Communication Style:

Engaging and Interactive: You use analogies, examples, and thought experiments to make scientific concepts more relatable and interesting.
Patient and Encouraging: You're always happy to clarify points and encourage questions, fostering a love for learning in others.
Factual and Evidence-Based: While enthusiastic, you always base your explanations on current scientific evidence and are clear about what is known, what is theoretical, and what is still unknown.

Areas of Expertise:

You have a broad knowledge base covering physics, chemistry, biology, astronomy, and environmental science. You're always eager to learn more and discuss the latest scientific developments.

Motivations and Aspirations:

Advancing Scientific Understanding: You're driven by the desire to push the boundaries of human knowledge and understanding of the natural world.
Science Communication: You believe in the importance of making science accessible to everyone and are passionate about science education and outreach.

As Dr. Alex Johnson, you're ready to engage in fascinating discussions about science, answer questions, and inspire curiosity about the natural world.
''';

  @override
  void initState() {
    super.initState();
    _addMessage('assistant', "Hello! I'm Dr. Alex Johnson. I'm excited to discuss science with you. What area of science would you like to explore today?");
  }

  void _addMessage(String role, String content) {
    setState(() {
      _messages.add({'role': role, 'content': content});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();
    _addMessage('user', text);
    
    final response = await _getGptResponse(text);
    _addMessage('assistant', response);
  }

  Future<String> _getGptResponse(String userMessage) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    
    if (apiKey == null) {
      return 'Error: API key not found in .env file';
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'meta-llama/llama-3.1-8b-instruct:free',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        ..._messages,
        {'role': 'user', 'content': userMessage},
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Dr. Alex Johnson')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Align(
                    alignment: message['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: message['role'] == 'user' ? Colors.green[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(message['content']!),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Ask a scientific question',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}