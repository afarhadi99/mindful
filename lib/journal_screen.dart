import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> _entries = [];
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  late Deepgram _deepgram;
  StreamSubscription<DeepgramSttResult>? _transcriptionSubscription;
  String _currentTranscription = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _initializeDeepgram();
  }

  void _initializeDeepgram() {
    final apiKey = dotenv.env['DEEPGRAM_API_KEY'];
    if (apiKey == null) {
      print('Deepgram API key not found');
      return;
    }

    _deepgram = Deepgram(apiKey, baseQueryParams: {
      'model': 'nova-2-general',
      'language': 'en-US',
      'smart_format': true,
      'filler_words': false,
      'punctuate': true,
    });
  }

  void _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getString('journal_entries') ?? '[]';
    final entriesList = json.decode(entriesJson) as List;
    setState(() {
      _entries = entriesList.map((e) => JournalEntry.fromJson(e)).toList();
    });
  }

  void _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString('journal_entries', entriesJson);
  }

  void _addEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JournalEntryScreen()),
    );

    if (result != null && result is JournalEntry) {
      setState(() {
        _entries.add(result);
        _entries.sort((a, b) => b.date.compareTo(a.date));
      });
      _saveEntries();
    }
  }

  void _addAudioEntry() async {
    if (!_isRecording) {
      await _startRecording();
    } else {
      await _stopRecording();
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JournalEntryScreen(initialContent: _currentTranscription),
        ),
      );

      if (result != null && result is JournalEntry) {
        setState(() {
          _entries.add(result);
          _entries.sort((a, b) => b.date.compareTo(a.date));
        });
        _saveEntries();
      }
      _currentTranscription = '';
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Start the recording
        final stream = await _audioRecorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ));

        final streamParams = {
          'encoding': 'linear16',
          'sample_rate': 16000,
        };

        final transcriptionStream = _deepgram.transcribeFromLiveAudioStream(stream, queryParams: streamParams);

        _transcriptionSubscription = transcriptionStream.listen((result) {
          setState(() {
            _currentTranscription += result.transcript ?? '';
          });
        });

        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      await _transcriptionSubscription?.cancel();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _transcriptionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addEntry,
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _addAudioEntry,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Recording: $_currentTranscription',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ListTile(
                  title: Text(entry.title),
                  subtitle: Text(entry.date.toString().split(' ')[0]),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalEntryScreen(entry: entry),
                      ),
                    );

                    if (result != null && result is JournalEntry) {
                      setState(() {
                        _entries[index] = result;
                        _entries.sort((a, b) => b.date.compareTo(a.date));
                      });
                      _saveEntries();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;
  final String? initialContent;

  const JournalEntryScreen({Key? key, this.entry, this.initialContent}) : super(key: key);

  @override
  _JournalEntryScreenState createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  late Deepgram _deepgram;
  StreamSubscription<DeepgramSttResult>? _transcriptionSubscription;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: widget.entry?.content ?? widget.initialContent ?? '');
    _initializeDeepgram();
  }

  void _initializeDeepgram() {
    final apiKey = dotenv.env['DEEPGRAM_API_KEY'];
    if (apiKey == null) {
      print('Deepgram API key not found');
      return;
    }

    _deepgram = Deepgram(apiKey, baseQueryParams: {
      'model': 'nova-2-general',
      'language': 'en-US',
      'smart_format': true,
      'filler_words': false,
      'punctuate': true,
    });
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      await _startRecording();
    } else {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final stream = await _audioRecorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ));

        final streamParams = {
          'encoding': 'linear16',
          'sample_rate': 16000,
        };

        final transcriptionStream = _deepgram.transcribeFromLiveAudioStream(stream, queryParams: streamParams);

        _transcriptionSubscription = transcriptionStream.listen((result) {
          setState(() {
            _contentController.text += result.transcript ?? '';
          });
        });

        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      await _transcriptionSubscription?.cancel();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioRecorder.dispose();
    _transcriptionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _toggleRecording,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final entry = JournalEntry(
                id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch,
                title: _titleController.text,
                content: _contentController.text,
                date: widget.entry?.date ?? DateTime.now(),
              );
              Navigator.pop(context, entry);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalEntry {
  final int id;
  final String title;
  final String content;
  final DateTime date;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
    };
  }
}