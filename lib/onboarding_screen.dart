import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:animated_widgets/animated_widgets.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  int _age = 0;
  String _occupation = '';
  bool _showForm = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _name);
      await prefs.setInt('age', _age);
      await prefs.setString('occupation', _occupation);
      await prefs.setBool('isOnboarded', true);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Welcome to the Mindful App',
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
                onFinished: () {
                  setState(() {
                    _showForm = true;
                  });
                },
              ),
              const SizedBox(height: 20),
              AnimatedTextKit(
                animatedTexts: [
                  FadeAnimatedText(
                    'Mindful is your everyday companion',
                    textStyle: const TextStyle(fontSize: 18),
                    duration: const Duration(milliseconds: 2000),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              const SizedBox(height: 40),
              if (_showForm) ...[
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Please enter your details',
                      textStyle: const TextStyle(fontSize: 18),
                      speed: const Duration(milliseconds: 50),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                const SizedBox(height: 10),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Your details are private and will not be shared with anyone',
                      textStyle: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      speed: const Duration(milliseconds: 50),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                const SizedBox(height: 20),
                TranslationAnimatedWidget(
                  enabled: true,
                  values: [
                    Offset(0, 200),
                    Offset(0, 0),
                  ],
                  child: OpacityAnimatedWidget(
                    enabled: true,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                            onSaved: (value) => _name = value!,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Age'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your age';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                            onSaved: (value) => _age = int.parse(value!),
                          ),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Occupation'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your occupation';
                              }
                              return null;
                            },
                            onSaved: (value) => _occupation = value!,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitForm,
                            child: const Text('Get Started'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}