import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/component/reviewbutton.dart' as review_btn;
import 'package:driving_license_exam/home.dart';
import 'package:driving_license_exam/review.dart';
import 'package:flutter/material.dart';

class MockResultScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final String? source;
  final List<int>? userAnswers; // Add userAnswers
  final List<Map<String, dynamic>>? questions;

  const MockResultScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    this.source,
    this.userAnswers,
    this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    int wrongAnswers = totalQuestions - correctAnswers;
    final percentage = (correctAnswers / totalQuestions) * 100;
    bool isPassed = percentage >= 65;

    String heading;
    Color bgcolor;
    if (source == 'MockExam') {
      heading = "Mock Exam \n Exam paper 01";
      bgcolor = const Color(0xff4378DB);
    } else {
      heading =
          "Result \n Paper 01"; // Default heading if source is null or unexpected
      bgcolor = const Color(0xFF28A164);
      heading = "Study Materials \n     Module 01"; // Default bgcolor
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          appbar(
              size: size,
              bgcolor: bgcolor,
              textColor: Colors.white,
              heading: heading),
          // Header

          const SizedBox(height: 20),
          // Answer Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _summaryTile("Total Question", totalQuestions.toString()),
                const SizedBox(height: 8),
                _summaryTile("Correct Answer", correctAnswers.toString(),
                    color: Colors.green),
                const SizedBox(height: 8),
                _summaryTile("Wrong Answer", wrongAnswers.toString(),
                    color: Colors.red),
              ],
            ),
          ),
          //const SizedBox(height: 8),
          // Result Section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    // Image
                    Image.asset(
                      width: size.width,
                      fit: size.width < 400 ? BoxFit.cover : BoxFit.contain,
                      isPassed
                          ? 'assets/images/pass.png' // use your pass image
                          : 'assets/images/fail.png', // use your fail image
                      // height: size.height,
                    ),
                    const SizedBox(height: 16),
                    Positioned(
                      top: size.height * 0.29,
                      left: size.width * 0.2,
                      right: size.width * 0.2,
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              isPassed ? "Congratulations" : "Try Again 😔",
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color:
                                    isPassed ? Colors.green : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPassed
                                  ? "You Pass the ${source == 'MockExam' ? 'Mock Exam' : 'StudyMaterials'}"
                                  : "You are Fail the ${source == 'MockExam' ? 'Mock Exam' : 'StudyMaterials'}",
                              style: const TextStyle(fontSize: 20),
                            ),
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
                    if (userAnswers != null && questions != null) {
                      Navigator.push(
                        context,
                        createFadeRoute(ReviewScreen(
                          source: source ?? 'MockExam',
                          userAnswers: userAnswers!,
                          questions: questions!,
                        )),
                      );
                    }
                  },
                  text: 'Review',
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
    );
  }

  Widget _summaryTile(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(
          vertical: 4), // Added margin for shadow visibility
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 2), // Shadow position
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 0, 0, 0), // Slightly muted title color
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
}
