import 'dart:async';
import 'package:driving_license_exam/component/PreviousButton.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/component/nextbutton.dart';
import 'package:driving_license_exam/mock_result_screen.dart';
import 'package:driving_license_exam/models/study_models.dart';
import 'package:driving_license_exam/models/exam_models.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/exam_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';

import 'services/api_config.dart';
import 'services/study_service.dart';

class MockExamDo extends StatefulWidget {
  final String source;
  final String selectedLanguage;
  final String selectedLanguageCode;
  final int? lessonId;
  final int? vehicleTypeId;
  final String? userId;
  final String? examType;

  const MockExamDo({
    super.key,
    required this.selectedLanguage,
    required this.selectedLanguageCode,
    required this.source,
    this.lessonId,
    this.vehicleTypeId,
    this.userId,
    this.examType,
  });

  @override
  State<MockExamDo> createState() => _MockExamDoState();
}

class _MockExamDoState extends State<MockExamDo> {
  int selectedAnswer = -1;
  int currentQuestionIndex = 0;
  List<int> userAnswers = [];
  bool showAnswer = false;
  bool _triggerAnimation = false;
  bool isLoading = true;
  String? errorMessage;

  // Timer-related variables
  late Timer _timer;
  int _remainingSeconds = 60 * 60; // Default 60 minutes
  bool _isTimeUp = false;

  late AudioPlayer _audioPlayer;
  String sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  // For study materials
  List<Question> studyQuestions = [];

  // For mock exams
  List<ExamQuestion> mockExamQuestions = [];
  String? currentExamId;
  ExamData? examData;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _initializeExam();
  }

  Future<void> _initializeExam() async {
    if (widget.source == "MockExam" && widget.userId != null) {
      await _startMockExam();
    } else {
      await _fetchStudyQuestions();
    }
  }

  Future<void> _startMockExam() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Start mock exam
      final startResponse = await ExamService.startMockExam(
        userId: widget.userId!,
        language: widget.selectedLanguageCode,
      );

      if (!startResponse.success) {
        setState(() {
          errorMessage = startResponse.message.isNotEmpty
              ? startResponse.message
              : 'Failed to start mock exam';
          isLoading = false;
        });
        return;
      }

      final mockExam = startResponse.data!;
      currentExamId = mockExam.examId;
      print('exam id $currentExamId');

      // Get exam questions
      final questionsResponse =
          await ExamService.getExamQuestions(currentExamId!);

      if (!questionsResponse.success) {
        setState(() {
          errorMessage = questionsResponse.message.isNotEmpty
              ? questionsResponse.message
              : 'Failed to load exam questions';
          isLoading = false;
        });
        return;
      }

      examData = questionsResponse.data!;
      mockExamQuestions = examData!.questions;

      // Set remaining time from server
      _remainingSeconds =
          (examData!.remainingMinutes * 60) + examData!.remainingSeconds;

      setState(() {
        userAnswers = List.filled(mockExamQuestions.length, -1);
        isLoading = false;
      });

      _startTimer();
      if (mockExamQuestions.isNotEmpty) {
        _loadCurrentQuestionAudio();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error starting mock exam: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchStudyQuestions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (widget.lessonId != null && widget.vehicleTypeId != null) {
        // Fetch study material questions
        final response = await StudyService.getQuestions(
          lessonId: widget.lessonId!,
          vehicleTypeId: widget.vehicleTypeId!,
          language: widget.selectedLanguageCode,
        );

        if (response.success && response.data != null) {
          setState(() {
            studyQuestions = response.data!;
            userAnswers = List.filled(studyQuestions.length, -1);
            isLoading = false;
          });

          if (studyQuestions.isNotEmpty) {
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
        // Fallback to hardcoded questions
        _initializeHardcodedQuestions();
        setState(() {
          userAnswers = List.filled(studyQuestions.length, -1);
          isLoading = false;
        });
        if (studyQuestions.isNotEmpty) {
          _loadCurrentQuestionAudio();
        }
      }

      _startTimer();
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
        // Add more hardcoded questions as needed
      ];
    }

    // Convert hardcoded data to Question objects
    studyQuestions = hardcodedData.asMap().entries.map((entry) {
      final data = entry.value;
      return Question(
        id: entry.key + 1,
        questionText: data['question'],
        correctOption: (data['correctAnswer'] as int) + 1,
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
    try {
      await _audioPlayer.stop();
      String? audioUrl;

      if (widget.source == "MockExam" && mockExamQuestions.isNotEmpty) {
        audioUrl = mockExamQuestions[currentQuestionIndex].questionAudio;
      } else if (studyQuestions.isNotEmpty) {
        audioUrl = studyQuestions[currentQuestionIndex].questionAudio;
      }

      if (audioUrl != null) {
        if (audioUrl.startsWith('assets/')) {
          await _audioPlayer.setAsset(audioUrl);
        } else {
          await _audioPlayer.setUrl(audioUrl);
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

  Future<void> _navigateToResultScreen() async {
    if (selectedAnswer != -1) {
      userAnswers[currentQuestionIndex] = selectedAnswer;
    }

    if (widget.source == "MockExam" && currentExamId != null) {
      // Submit mock exam
      await ExamService.submitExam(currentExamId!);

      // Navigate to mock exam results
      Navigator.pushReplacement(
        context,
        createFadeRoute(MockExamResultScreen(examId: currentExamId!)),
      );
    } else {
      // Handle study materials result
      List<Map<String, dynamic>> questionData = studyQuestions
          .map((q) => {
                'question': q.questionText,
                'answers': q.options.map((opt) => opt.optionText).toList(),
                'correctAnswer': q.correctOption - 1,
              })
          .toList();

      Navigator.pushReplacement(
        context,
        createFadeRoute(MockResultScreen(
          totalQuestions: studyQuestions.length,
          correctAnswers: userAnswers
              .asMap()
              .entries
              .where((entry) =>
                  entry.value == studyQuestions[entry.key].correctOption)
              .length,
          source: widget.source,
          userAnswers: userAnswers,
          questions: questionData,
        )),
      );
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  Future<void> _goToNextQuestion() async {
    setState(() {
      if (_audioPlayer.playing) {
        _audioPlayer.pause();
      }
    });

    // Submit answer for mock exam
    if (widget.source == "MockExam" &&
        currentExamId != null &&
        selectedAnswer != -1) {
      final currentQuestion = mockExamQuestions[currentQuestionIndex];
      await ExamService.submitExamAnswer(
        examId: currentExamId!,
        questionId: currentQuestion.id,
        selectedOption: selectedAnswer,
        timeTakenSeconds: 30, // You can track actual time taken
      );
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (widget.source == 'StudyMaterials') {
        setState(() {
          if (!showAnswer) {
            showAnswer = true;
          } else {
            userAnswers[currentQuestionIndex] = selectedAnswer;
            if (currentQuestionIndex < _getTotalQuestions() - 1) {
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
        if (currentQuestionIndex < _getTotalQuestions() - 1) {
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

  int _getTotalQuestions() {
    return widget.source == "MockExam"
        ? mockExamQuestions.length
        : studyQuestions.length;
  }

  dynamic _getCurrentQuestion() {
    return widget.source == "MockExam"
        ? mockExamQuestions[currentQuestionIndex]
        : studyQuestions[currentQuestionIndex];
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
                  onPressed: _initializeExam,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_getTotalQuestions() == 0) {
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

    final currentQuestion = _getCurrentQuestion();
    final isLastQuestion = currentQuestionIndex == _getTotalQuestions() - 1;

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
                            "Question ${currentQuestionIndex + 1}/${_getTotalQuestions()}",
                            style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / _getTotalQuestions(),
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
                          // Audio button
                          if (_hasQuestionAudio())
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
                            _getQuestionText(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question Image (if available)
                    if (_getImageUrl() != null)
                      Center(
                        child: _getImageUrl()!.startsWith('assets/')
                            ? Image.asset(
                                _getImageUrl()!,
                                height: 100,
                              )
                            : Image.network(
                                _getImageUrl()!,
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
                  itemCount: _getOptionsCount(),
                  itemBuilder: (context, index) {
                    final option = _getOptionAt(index);
                    bool isCorrect = _isCorrectOption(index);
                    bool showIndicator =
                        showAnswer && widget.source == 'StudyMaterials';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedAnswer == _getOptionNumber(index)
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                        color: showIndicator && isCorrect
                            ? Colors.green.shade50
                            : showIndicator &&
                                    selectedAnswer == _getOptionNumber(index) &&
                                    !isCorrect
                                ? Colors.red.shade50
                                : selectedAnswer == _getOptionNumber(index)
                                    ? Colors.blue.shade50
                                    : Colors.white,
                      ),
                      child: RadioListTile<int>(
                        value: _getOptionNumber(index),
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
                              child: Text(_getOptionText(option)),
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

  // Helper methods to handle both question types
  String _getQuestionText() {
    if (widget.source == "MockExam") {
      return mockExamQuestions[currentQuestionIndex].questionText;
    } else {
      return studyQuestions[currentQuestionIndex].questionText;
    }
  }

  String? _getImageUrl() {
    if (widget.source == "MockExam") {
      return mockExamQuestions[currentQuestionIndex].imageUrl;
    } else {
      return studyQuestions[currentQuestionIndex].imageUrl;
    }
  }

  bool _hasQuestionAudio() {
    if (widget.source == "MockExam") {
      return mockExamQuestions[currentQuestionIndex].questionAudio != null;
    } else {
      return studyQuestions[currentQuestionIndex].questionAudio != null;
    }
  }

  int _getOptionsCount() {
    if (widget.source == "MockExam") {
      return mockExamQuestions[currentQuestionIndex].options.length;
    } else {
      return studyQuestions[currentQuestionIndex].options.length;
    }
  }

  dynamic _getOptionAt(int index) {
    if (widget.source == "MockExam") {
      return mockExamQuestions[currentQuestionIndex].options[index];
    } else {
      return studyQuestions[currentQuestionIndex].options[index];
    }
  }

  int _getOptionNumber(int index) {
    final option = _getOptionAt(index);
    return option.optionNumber;
  }

  String _getOptionText(dynamic option) {
    return option.optionText;
  }

  bool _isCorrectOption(int index) {
    if (widget.source == "MockExam") {
      // For mock exams, we don't show correct answers immediately
      return false;
    } else {
      final option = _getOptionAt(index);
      return option.optionNumber ==
          studyQuestions[currentQuestionIndex].correctOption;
    }
  }
}

// Add MockExamResultScreen for handling mock exam results
class MockExamResultScreen extends StatelessWidget {
  final String examId;

  const MockExamResultScreen({required this.examId, super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiResponse<ExamResult>>(
      future: ExamService.getExamResults(examId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFF0C1A64),
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xff4378DB),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          'MOCK EXAM RESULTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // Loading content
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Loading your exam results...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.data!.success) {
          return Scaffold(
            backgroundColor: const Color(0xFF0C1A64),
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xff4378DB),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          'MOCK EXAM RESULTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // Error content
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error,
                              size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load results',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.data?.message ?? 'Unknown error occurred',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final result = snapshot.data!.data!;

        // Navigate to the comprehensive MockResultScreen with exam data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            createFadeRoute(
              MockResultScreen(
                examId: examId,
                source: 'MockExam',
              ),
            ),
          );
        });

        // Return empty container while navigating
        return const Scaffold(
          backgroundColor: Color(0xFF0C1A64),
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
    );
  }
}
