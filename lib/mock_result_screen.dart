import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/component/reviewbutton.dart' as review_btn;
import 'package:driving_license_exam/home.dart';
import 'package:driving_license_exam/models/exam_models.dart';
import 'package:driving_license_exam/review.dart';
import 'package:driving_license_exam/services/exam_service.dart';
import 'package:flutter/material.dart';

class MockResultScreen extends StatefulWidget {
  final int? totalQuestions; // Make optional for backward compatibility
  final int? correctAnswers; // Make optional for backward compatibility
  final String? source;
  final List<int>? userAnswers;
  final List<Map<String, dynamic>>? questions;
  final String? examId; // Add examId for fetching results from backend

  const MockResultScreen({
    super.key,
    this.totalQuestions,
    this.correctAnswers,
    this.source,
    this.userAnswers,
    this.questions,
    this.examId,
  });

  @override
  State<MockResultScreen> createState() => _MockResultScreenState();
}

class _MockResultScreenState extends State<MockResultScreen> {
  ExamResult? examResult;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.examId != null) {
      _fetchExamResults();
    } else {
      // Use passed parameters for backward compatibility
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchExamResults() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('Fetching exam results for examId: ${widget.examId}');
      final response = await ExamService.getExamResults(widget.examId!);

      if (response.success && response.data != null) {
        setState(() {
          examResult = response.data;
          isLoading = false;
        });
        print(
            'Successfully loaded exam results: ${examResult?.scorePercentage}%');
      } else {
        setState(() {
          errorMessage = response.message;
          isLoading = false;
        });
        print('Failed to load exam results: ${response.message}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading results: $e';
        isLoading = false;
      });
      print('Exception while loading exam results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Loading state
    if (isLoading) {
      return SingleChildScrollView(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              appbar(
                size: size,
                bgcolor: const Color(0xff4378DB),
                textColor: Colors.white,
                heading: "Loading Results...",
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your exam results...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (errorMessage != null) {
      return SingleChildScrollView(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                appbar(
                  size: size,
                  bgcolor: const Color(0xff4378DB),
                  textColor: Colors.white,
                  heading: "Mock Exam Results",
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading results',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            widget.examId != null ? _fetchExamResults : null,
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context, createFadeRoute(const Home()));
                        },
                        child: const Text('Go to Home'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Use examResult data if available, otherwise use passed parameters
    final totalQuestions =
        examResult?.totalQuestions ?? widget.totalQuestions ?? 0;
    final correctAnswers =
        examResult?.correctAnswers ?? widget.correctAnswers ?? 0;
    final wrongAnswers =
        examResult?.wrongAnswers ?? (totalQuestions - correctAnswers);
    final percentage = examResult?.scorePercentage ??
        ((correctAnswers / totalQuestions) * 100);
    final bool isPassed = examResult?.passed ?? (percentage >= 65);
    final String grade = examResult?.grade ?? _getGrade(percentage);

    String heading;
    Color bgcolor;
    if (widget.source == 'MockExam' || examResult != null) {
      heading = "Mock Exam \n ${examResult?.vehicleType ?? 'Exam Results'}";
      bgcolor = const Color(0xff4378DB);
    } else {
      heading = "Study Materials \n Module 01";
      bgcolor = const Color(0xFF28A164);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            appbar(
              size: size,
              bgcolor: bgcolor,
              textColor: Colors.white,
              heading: heading,
            ),
            const SizedBox(height: 20),

            // Answer Summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _summaryTile("Total Questions", totalQuestions.toString()),
                  const SizedBox(height: 8),
                  _summaryTile("Correct Answers", correctAnswers.toString(),
                      color: Colors.green),
                  const SizedBox(height: 8),
                  _summaryTile("Wrong Answers", wrongAnswers.toString(),
                      color: Colors.red),
                  const SizedBox(height: 8),
                  _summaryTile("Score", "${percentage.toStringAsFixed(1)}%",
                      color: isPassed ? Colors.green : Colors.red),
                  if (examResult != null) ...[
                    const SizedBox(height: 8),
                    _summaryTile("Grade", grade,
                        color: isPassed ? Colors.green : Colors.orange),
                    if (examResult!.examDurationMinutes != null) ...[
                      const SizedBox(height: 8),
                      _summaryTile(
                          "Duration", "${examResult!.examDurationMinutes} min",
                          color: Colors.blue),
                    ],
                  ],
                ],
              ),
            ),

            // Category Performance (if available)
            if (examResult != null &&
                examResult!.categoryPerformance.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildCategoryPerformance(),
            ],

            // Result Section
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      SingleChildScrollView(
                        child: Image.asset(
                          width: size.width,
                          fit: size.width < 400 ? BoxFit.cover : BoxFit.contain,
                          isPassed
                              ? 'assets/images/pass.png'
                              : 'assets/images/fail.png',
                        ),
                      ),
                      Positioned(
                        top: size.height * 0.29,
                        left: size.width * 0.2,
                        right: size.width * 0.2,
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                isPassed ? "Congratulations!" : "Try Again 😔",
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.bold,
                                  color: isPassed
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPassed
                                    ? "You passed the ${widget.source == 'MockExam' || examResult != null ? 'Mock Exam' : 'Study Materials'}"
                                    : "You failed the ${widget.source == 'MockExam' || examResult != null ? 'Mock Exam' : 'Study Materials'}",
                                style: const TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                              if (examResult != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "Grade: $grade",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isPassed ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  review_btn.CustomButton(
                    onPressed: () {
                      if (examResult != null) {
                        _showDetailedResults(context);
                      } else if (widget.userAnswers != null &&
                          widget.questions != null) {
                        Navigator.push(
                          context,
                          createFadeRoute(ReviewScreen(
                            source: widget.source ?? 'MockExam',
                            userAnswers: widget.userAnswers!,
                            questions: widget.questions!,
                          )),
                        );
                      }
                    },
                    text: examResult != null ? 'Details' : 'Review',
                  ),
                  review_btn.CustomButton(
                    onPressed: () {
                      Navigator.push(context, createFadeRoute(const Home()));
                    },
                    text: 'Home',
                    backgroundColor: const Color(0xff4378DB),
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Category Performance",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...examResult!.categoryPerformance.map((category) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "${category.correctAnswers}/${category.totalQuestions} correct",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${category.accuracyPercentage.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: category.accuracyPercentage >= 70
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showDetailedResults(BuildContext context) {
    if (examResult?.questionResults == null ||
        examResult!.questionResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No detailed question results available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Detailed Results",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: examResult!.questionResults.length,
                  itemBuilder: (context, index) {
                    final question = examResult!.questionResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              question.isCorrect ? Colors.green : Colors.red,
                          child: Text(
                            "${question.questionOrder}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          question.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Category: ${question.categoryName}"),
                            const SizedBox(height: 2),
                            Text(
                              "Your answer: ${question.selectedOption ?? 'Not answered'} | Correct: ${question.correctOption}",
                              style: TextStyle(
                                color: question.isCorrect
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (question.timeTakenSeconds != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Time taken: ${question.timeTakenSeconds}s",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Icon(
                          question.isCorrect
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: question.isCorrect ? Colors.green : Colors.red,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}
