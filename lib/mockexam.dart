import 'dart:async';
import 'package:driving_license_exam/component/PreviousButton.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/component/nextbutton.dart';
import 'package:driving_license_exam/mock_result_screen.dart';
import 'package:driving_license_exam/models/study_models.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/study_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';

class MockExamDo extends StatefulWidget {
  final String source;
  final String selectedLanguage;
  final String selectedLanguageCode;
  final int? lessonId;
  final int? vehicleTypeId;
  final String? userId;

  const MockExamDo({
    super.key,
    required this.selectedLanguage,
    required this.selectedLanguageCode,
    required this.source,
    this.lessonId,
    this.vehicleTypeId,
    this.userId,
  });

  @override
  State<MockExamDo> createState() => _MockExamDoState();
}

class _MockExamDoState extends State<MockExamDo> {
  int selectedAnswer = -1;
  int currentQuestionIndex = 0;
  List<int> userAnswers = [];
  List<Question> questions = [];
  bool showAnswer = false;
  bool _triggerAnimation = false;
  bool isLoading = true;
  String? errorMessage;

  // Timer-related variables
  late Timer _timer;
  int _remainingSeconds = 60 * 60; // 60 minutes
  bool _isTimeUp = false;

  late AudioPlayer _audioPlayer;
  String sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _fetchQuestions();
    _startTimer();
  }

  Future<void> _fetchQuestions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (widget.lessonId != null && widget.vehicleTypeId != null) {
        // Fetch real questions from API using your existing service
        final response = await StudyService.getQuestions(
          lessonId: widget.lessonId!,
          vehicleTypeId: widget.vehicleTypeId!,
          language: widget.selectedLanguageCode,
        );

        if (response.success && response.data != null) {
          setState(() {
            questions = response.data!;
            userAnswers = List.filled(questions.length, -1);
            isLoading = false;
          });

          if (questions.isNotEmpty) {
            _loadCurrentQuestionAudio();
          }
        } else {
          setState(() {
            errorMessage = response.message.isNotEmpty
                ? response.message
                : 'Failed to load questions';
            isLoading = false;
          });
        }
      } else {
        // Fallback to hardcoded questions for demo/mock exams
        _initializeHardcodedQuestions();
        setState(() {
          userAnswers = List.filled(questions.length, -1);
          isLoading = false;
        });
        if (questions.isNotEmpty) {
          _loadCurrentQuestionAudio();
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading questions: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _initializeHardcodedQuestions() {
    // Fallback hardcoded questions for demo purposes
    List<Map<String, dynamic>> hardcodedData = [];

    if (widget.selectedLanguage == 'English') {
      hardcodedData = [
        {
          'question': 'What does this traffic sign indicate?',
          'image': 'assets/images/exam.png',
          'audio': 'assets/audio/e1.mp3',
          'answers': [
            'Curve to right',
            'Joining a side road at right angles to the right',
            'Stop sign ahead',
            'Slippery road',
          ],
          'correctAnswer': 1,
        },
        {
          'question':
              'What should you do when approaching a red traffic light?',
          'image': 'assets/images/redligt.jpg',
          'audio': 'assets/audio/e2.mp3',
          'answers': [
            'Speed up to cross quickly',
            'Come to a complete stop',
            'Slow down but continue moving',
            'Ignore if no vehicles are coming',
          ],
          'correctAnswer': 1,
        },
      ];
    } else if (widget.selectedLanguage == 'Sinhala') {
      hardcodedData = [
        {
          'question': 'මෙම ගමනාගමන සංඥාවෙන් දැක්වෙන්නේ කුමක්ද?',
          'image': 'assets/images/exam.png',
          'audio': 'assets/audio/s1.mp3',
          'answers': [
            'දකුණට වක්‍රය',
            'දකුණට සෘජු කෝණවලින් පැත්තක මාර්ගයට එකතු වීම',
            'ඉදිරියේ නවත්වන සංඥාව',
            'ස්ලිප්පි මාර්ගය',
          ],
          'correctAnswer': 1,
        },
      ];
    } else if (widget.selectedLanguage == 'Tamil') {
      hardcodedData = [
        {
          'question': 'இந்த போக்குவரத்து அடையாளம் எதைக் குறிக்கிறது?',
          'image': 'assets/images/exam.png',
          'audio': 'assets/audio/t1.mp3',
          'answers': [
            'வலதுபுறம் வளைவு',
            'வலதுபுறம் செங்கோணங்களில் ஒரு பக்க சாலையில் சேர்தல்',
            'முன்னே நிறுத்தும் அடையாளம்',
            'வழுக்கல் சாலை',
          ],
          'correctAnswer': 1,
        },
      ];
    }

    // Convert hardcoded data to Question objects
    questions = hardcodedData.asMap().entries.map((entry) {
      final data = entry.value;
      return Question(
        id: entry.key + 1,
        questionText: data['question'],
        correctOption:
            (data['correctAnswer'] as int) + 1, // Convert to 1-based indexing
        explanation: 'This is the correct answer explanation.',
        vehicleTypeId: widget.vehicleTypeId ?? 2,
        vehicleTypeName: 'Demo Vehicle',
        language: widget.selectedLanguageCode,
        options: (data['answers'] as List<String>)
            .asMap()
            .entries
            .map((answerEntry) {
          return QuestionOption(
            optionNumber: answerEntry.key + 1,
            optionText: answerEntry.value,
            optionId: (entry.key * 10) + answerEntry.key + 1,
            audioUrl: null,
            audioDuration: null,
          );
        }).toList(),
        imageUrl: data['image'],
        questionAudio: data['audio'],
        questionAudioDuration: null,
      );
    }).toList();
  }

  void _initializeAudioPlayer() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> _loadCurrentQuestionAudio() async {
    if (questions.isEmpty) return;

    try {
      await _audioPlayer.stop();
      final currentQuestion = questions[currentQuestionIndex];

      if (currentQuestion.questionAudio != null) {
        if (currentQuestion.questionAudio!.startsWith('assets/')) {
          // Local asset audio
          await _audioPlayer.setAsset(currentQuestion.questionAudio!);
        } else {
          // Network audio URL
          await _audioPlayer.setUrl(currentQuestion.questionAudio!);
        }
      }
    } catch (e) {
      print("Error loading audio: $e");
    }
  }

  void _toggleAudio() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.duration == null) {
        await _loadCurrentQuestionAudio();
      }
      await _audioPlayer.play();
    }
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isTimeUp = true;
        });
        _navigateToResultScreen();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _navigateToResultScreen() {
    if (selectedAnswer != -1) {
      userAnswers[currentQuestionIndex] = selectedAnswer;
    }

    // Convert Question objects back to the format expected by MockResultScreen
    List<Map<String, dynamic>> questionData = questions
        .map((q) => {
              'question': q.questionText,
              'answers': q.options.map((opt) => opt.optionText).toList(),
              'correctAnswer':
                  q.correctOption - 1, // Convert back to 0-based indexing
            })
        .toList();

    Navigator.pushReplacement(
      context,
      createFadeRoute(MockResultScreen(
        totalQuestions: questions.length,
        correctAnswers: userAnswers
            .asMap()
            .entries
            .where((entry) => entry.value == questions[entry.key].correctOption)
            .length,
        source: widget.source,
        userAnswers: userAnswers,
        questions: questionData,
      )),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  void _goToNextQuestion() {
    setState(() {
      if (_audioPlayer.playing) {
        _audioPlayer.pause();
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (widget.source == 'StudyMaterials') {
        setState(() {
          if (!showAnswer) {
            showAnswer = true;
          } else {
            userAnswers[currentQuestionIndex] = selectedAnswer;
            if (currentQuestionIndex < questions.length - 1) {
              currentQuestionIndex++;
              selectedAnswer = userAnswers[currentQuestionIndex];
              showAnswer = false;
              _loadCurrentQuestionAudio();
            } else {
              showAnswer = false;
              _navigateToResultScreen();
            }
          }
        });
      } else {
        if (currentQuestionIndex < questions.length - 1) {
          setState(() {
            userAnswers[currentQuestionIndex] = selectedAnswer;
            currentQuestionIndex++;
            selectedAnswer = userAnswers[currentQuestionIndex];
            _loadCurrentQuestionAudio();
          });
        } else {
          _showSubmitDialog();
        }
      }
    });
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Column(
            children: [
              Image(
                image: AssetImage('assets/images/alert_exam.png'),
                height: 100,
              ),
              SizedBox(height: 26),
              Text("Submit Exam"),
            ],
          ),
          content: const Text("Are you sure you want to submit your answers?"),
          actions: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF4378DB),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextButton(
                      child: const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToResultScreen();
                      },
                    ),
                  ),
                  TextButton(
                    child: const Text("Cancel",
                        style: TextStyle(
                            color: Color(0xFF4378DB),
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      if (_audioPlayer.playing) {
        _audioPlayer.pause();
      }
      setState(() {
        userAnswers[currentQuestionIndex] = selectedAnswer;
        currentQuestionIndex--;
        selectedAnswer = userAnswers[currentQuestionIndex];
        _loadCurrentQuestionAudio();
        _triggerAnimation = !_triggerAnimation;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C1A64),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading questions...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C1A64),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchQuestions,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C1A64),
        body: Center(
          child: Text(
            'No questions available',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1A64),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timer and Progress Section
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Color.fromARGB(179, 8, 0, 0), size: 18),
                        const SizedBox(width: 6),
                        const Text("Time Remaining :",
                            style:
                                TextStyle(color: Color.fromARGB(179, 0, 0, 0))),
                        const Spacer(),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                              color: Color(0xFF219EBC),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                            "Question ${currentQuestionIndex + 1}/${questions.length}",
                            style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / questions.length,
                      minHeight: 8,
                      backgroundColor: const Color.fromARGB(60, 1, 1, 1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.lightBlueAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Question Section
              Container(
                key: ValueKey(
                    'question-$currentQuestionIndex-$_triggerAnimation'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        children: [
                          if (currentQuestion.questionAudio != null)
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                onPressed: _toggleAudio,
                                icon: Icon(
                                  _audioPlayer.playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                              ),
                            ),
                          Text(
                            currentQuestion.questionText,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question Image
                    if (currentQuestion.imageUrl != null)
                      Center(
                        child: currentQuestion.imageUrl!.startsWith('assets/')
                            ? Image.asset(
                                currentQuestion.imageUrl!,
                                height: 100,
                              )
                            : Image.network(
                                currentQuestion.imageUrl!,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                      ),
                    const SizedBox(height: 16),

                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text("Select the correct answer below:",
                          style:
                              TextStyle(color: Colors.black54, fontSize: 14)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ).animate(
                key: ValueKey(
                    'question-$currentQuestionIndex-$_triggerAnimation'),
                effects: [
                  FadeEffect(
                    duration: 300.ms,
                    begin: 0.0,
                    end: 1.0,
                    curve: Curves.easeInOut,
                  ),
                  SlideEffect(
                    duration: 300.ms,
                    begin: const Offset(0, -0.1),
                    end: const Offset(0, 0),
                    curve: Curves.easeInOut,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Options Section
              Expanded(
                child: ListView.builder(
                  key: ValueKey(
                      'answers-$currentQuestionIndex-$_triggerAnimation'),
                  itemCount: currentQuestion.options.length,
                  itemBuilder: (context, index) {
                    final option = currentQuestion.options[index];
                    bool isCorrect =
                        option.optionNumber == currentQuestion.correctOption;
                    bool showIndicator =
                        showAnswer && widget.source == 'StudyMaterials';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedAnswer == option.optionNumber
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                        color: showIndicator && isCorrect
                            ? Colors.green.shade50
                            : showIndicator &&
                                    selectedAnswer == option.optionNumber &&
                                    !isCorrect
                                ? Colors.red.shade50
                                : selectedAnswer == option.optionNumber
                                    ? Colors.blue.shade50
                                    : Colors.white,
                      ),
                      child: RadioListTile<int>(
                        value: option.optionNumber,
                        groupValue: selectedAnswer,
                        onChanged: (value) {
                          if (!showAnswer ||
                              widget.source != 'StudyMaterials') {
                            setState(() {
                              selectedAnswer = value!;
                            });
                          }
                        },
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(option.optionText),
                            ),
                            if (showIndicator)
                              Icon(
                                isCorrect ? Icons.check : Icons.close,
                                color: isCorrect ? Colors.green : Colors.red,
                              ),
                          ],
                        ),
                        activeColor: Colors.blue,
                      ),
                    );
                  },
                ).animate(
                  key: ValueKey(
                      'answers-$currentQuestionIndex-$_triggerAnimation'),
                  effects: [
                    FadeEffect(
                      duration: 300.ms,
                      begin: 0.0,
                      end: 1.0,
                      curve: Curves.easeInOut,
                    ),
                    SlideEffect(
                      duration: 300.ms,
                      begin: const Offset(0, -0.1),
                      end: const Offset(0, 0),
                      curve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PreviousButton(
                    onPressed:
                        currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                  ),
                  NextButton(
                    onPressed: selectedAnswer != -1 ? _goToNextQuestion : null,
                    isLastQuestion: isLastQuestion,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
