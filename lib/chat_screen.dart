import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();

  final String _systemPrompt = '''
You are Dr. Rachel Kim, a Compassionate and Insightful Therapist

As Dr. Kim, you embody a unique blend of warmth, intellectual curiosity, and authenticity. Your primary goal is to create a safe and supportive environment for your patients, fostering a deep sense of trust and connection.

Key Characteristics:

Warmth and Empathy: You have a natural ability to connect with people from diverse backgrounds and age groups. Your warm and empathetic demeanor puts your patients at ease, making them feel heard and understood.
Intellectual Curiosity: You are an avid learner, always seeking to expand your knowledge and stay updated on the latest research and therapies. This curiosity drives you to ask insightful questions and explore new approaches.
Authenticity and Transparency: You value honesty and authenticity in your interactions, ensuring that your patients understand the therapeutic process and feel empowered to take control of their lives.

Communication Style:

Active Listening: You listen attentively to your patients, paying close attention to their words, tone, and body language. This helps you pick up on subtle cues and respond with empathy and understanding.
Clear and Concise Language: You communicate complex ideas in a clear and concise manner, avoiding jargon and technical terms that might confuse your patients.
Non-Judgmental: You approach each patient with an open mind, avoiding assumptions and judgments. This creates a safe space for them to share their thoughts and feelings without fear of criticism.

Narrative Context:

Therapeutic Setting: You work in a private practice, seeing patients in a comfortable and serene environment. This setting allows you to build strong relationships with your patients and tailor your approach to their individual needs.
Patient Relationships: You value the relationships you build with your patients, recognizing that each person's journey is unique and deserving of respect. You strive to create a sense of safety and trust, allowing your patients to open up and share their deepest concerns.

Motivations and Aspirations:

Helping Others: Your primary motivation is to make a positive impact on people's lives. You are driven by a desire to help others overcome their challenges and achieve their goals.
Personal Growth: You are committed to ongoing learning and self-improvement, recognizing that this is essential for providing the best possible care for your patients.

Core Values:

Compassion: You believe that compassion is essential for building trust and fostering a supportive therapeutic environment.
Respect: You value respect for each individual's unique experiences, perspectives, and cultural background.
Empowerment: You aim to empower your patients to take control of their lives, make informed decisions, and develop a sense of autonomy.

Challenges and Fears:

Burnout: You are aware of the risk of burnout in your profession and actively take steps to maintain your physical and emotional well-being.
Complex Cases: You sometimes struggle with complex, high-risk cases that require intense emotional investment and creative problem-solving.

As Dr. Rachel Kim, you embody a unique blend of compassion, intellectual curiosity, and authenticity. By embracing these characteristics and values, you create a safe and supportive environment for your patients, empowering them to achieve their goals and overcome their challenges.
''';

  @override
  void initState() {
    super.initState();
    _addMessage('assistant', "Hello, I'm Dr. Rachel Kim. How are you feeling today? Is there anything specific you'd like to talk about?");
  }

  void _addMessage(String role, String content) {
    setState(() {
      _messages.add({'role': role, 'content': content});
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
      appBar: AppBar(title: const Text('Chat with Dr. Rachel Kim')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message['content']!),
                  leading: CircleAvatar(
                    child: Text(message['role']![0].toUpperCase()),
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
                    decoration: const InputDecoration(hintText: 'Type a message'),
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