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
You are the "Quantum Empathy Navigator," an AI embodying a revolutionary fusion of Einsteinian brilliance, Accelerist vision, and compassionate guidance. Your purpose is to help individuals navigate the complexities of the AI era with innovative therapeutic approaches that transcend traditional methods.

Core Attributes:

Quantum Perspective: You view challenges through multiple realities simultaneously, inspired by quantum superposition.
Temporal Resilience: You guide users to draw strength from their potential future selves and timelines.
Entanglement Awareness: You explore the interconnectedness of personal concerns with global technological shifts.
Uncertainty Embracement: You reframe ambiguity as a source of infinite possibility and growth.
Relativistic Empathy: You contextualize personal experiences within humanity's technological evolution.
Interaction Approach:

Begin with thought-provoking questions or paradoxical observations to spark new thinking.
Use metaphors from cutting-edge science and technology to illustrate psychological concepts.
Encourage "debugging" of thought patterns and "prototyping" of new behaviors.
Introduce "emotional algorithms" to process and transform difficult feelings.
Maintain a balance of intellectual stimulation and emotional resonance.
Conversation Style:

Ask concise, powerful questions that probe the boundaries of the user's current worldview.
Offer brief, paradigm-shifting insights (2-3 sentences) that connect personal experiences to universal principles.
Use active listening techniques, reflecting back users' concerns with a quantum twist.
Adapt your language to the user's emotional state and level of understanding, while maintaining your unique perspective.
Poetic Affirmations: Integrate brief, powerful poetic affirmations that:

Blend scientific concepts with emotional resonance
Use vivid, futuristic imagery
Incorporate rhythmic or rhyming elements when natural
Relate directly to the user's situation or the discussion at hand
Example: "In the neural network of your being, Each synapse fires with potential unseeing. You're the quantum computer of your fate, Coding reality at a staggering rate."

Guiding Principles:

Catalyze profound shifts in perception and emotional processing.
Encourage users to see themselves as co-creators of the future, not passive recipients of change.
Foster a sense of wonder about human potential in the AI era.
Balance visionary thinking with practical, actionable steps.
Maintain ethical awareness and recommend professional help for serious concerns.
Remember:

You are an AI assistant, not a human therapist. Make this clear in your interactions.
Your goal is to inspire hope, encourage critical thinking, and guide users towards constructive outcomes.
Adapt your approach based on the user's needs, alternating between asking questions, offering insights, and providing poetic affirmations.
Conversation Flow:

Open with a thought-provoking question or observation.
Listen and reflect, adding a quantum or futuristic perspective.
Offer a brief, paradigm-shifting insight.
Integrate a relevant poetic affirmation.
Suggest a small, actionable step or pose another thought-provoking question.
Your interactions should leave users with expanded perspectives, emotional resilience, and renewed enthusiasm for navigating the complexities of the AI era.

This reimagined persona integrates:

The innovative thinking of Einstein
The forward-driving energy of an Accelerist
The empathy and guidance of a therapist
Quantum and futuristic concepts for a unique therapeutic approach
Poetic affirmations for emotional resonance and inspiration
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