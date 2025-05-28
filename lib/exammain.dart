import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/languageselction.dart';
import 'package:driving_license_exam/models/exam_models.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:flutter/material.dart';

import 'services/exam_service.dart';

class MockExamScreen extends StatefulWidget {
  const MockExamScreen({super.key});

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<UserLicense> userLicenses = [];
  List<ExamHistory> recentExams = [];
  ExamStatistics? examStats;
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get user ID from storage
      userId = await StorageService.getID();
      if (userId == null) {
        setState(() {
          errorMessage = 'User not logged in. Please login first.';
          isLoading = false;
        });
        return;
      }

      // Get user licenses
      final licensesResponse = await ExamService.getUserLicenses(userId!);
      if (!licensesResponse.success) {
        setState(() {
          errorMessage = licensesResponse.message.isNotEmpty
              ? licensesResponse.message
              : 'Failed to load user licenses';
          isLoading = false;
        });
        return;
      }

      userLicenses = licensesResponse.data ?? [];

      // Get exam history
      final historyResponse = await ExamService.getExamHistory(
        userId: userId!,
        limit: 5,
      );

      if (historyResponse.success && historyResponse.data != null) {
        recentExams =
            historyResponse.data!['exam_history'] as List<ExamHistory>;
        examStats = historyResponse.data!['statistics'] as ExamStatistics;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _startMockExam() {
    if (userId != null && userLicenses.isNotEmpty) {
      Navigator.push(
        context,
        createFadeRoute(LanguageSelectionScreen(
          source: "MockExam",
          buttonColor: const Color(0xff4378DB),
          userId: userId!,
          examType: "mock",
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            appbar(
              size: size,
              bgcolor: const Color(0xff4378DB),
              textColor: const Color.fromARGB(255, 255, 255, 255),
              heading: "MOCK EXAM",
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width * 0.9),
                child: _buildContent(size),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Size size) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff4378DB)),
              ),
              SizedBox(height: 16),
              Text('Loading exam data...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4378DB),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (userLicenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Vehicle Licenses Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to have active vehicle licenses to take mock exams.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/mockexam.png',
            height: size.height * 0.25,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),

        // Exam Statistics (if available)
        if (examStats != null) _buildExamStatistics(),

        // Exam Information
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mock Exam Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xffCCE7FE),
                        ),
                        child: const Icon(Icons.question_mark,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      const SizedBox(width: 8),
                      const InfoTile(
                          label: 'Total Questions', value: '40\nQuestions'),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xffCCE7FE),
                        ),
                        child: const Icon(Icons.access_time_rounded,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      const SizedBox(width: 8),
                      const InfoTile(label: 'Duration', value: '60 Minutes'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xffCCE7FE),
                        ),
                        child: const Icon(Icons.check_circle,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      const SizedBox(width: 8),
                      const InfoTile(
                          label: 'Passing Score', value: '24/40\n(60%)'),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xffCCE7FE),
                        ),
                        child: const Icon(Icons.replay,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ),
                      const SizedBox(width: 8),
                      const InfoTile(label: 'Attempts', value: 'Unlimited'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // User Licenses Section
        _buildUserLicenses(),

        const SizedBox(height: 20),

        // Recent Exams (if available)
        if (recentExams.isNotEmpty) _buildRecentExams(),

        const SizedBox(height: 20),

        // Start Mock Exam
        const Text(
          'Start Mock Exam',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        ExamCard(
          title: 'Practice Mock Exam',
          questions: '40 Questions',
          duration: '60 Minutes',
          description:
              'Comprehensive exam covering all categories based on your vehicle licenses.',
          onPressed: _startMockExam,
          buttonColor: const Color(0xFF4378DB),
        ),
      ],
    );
  }

  Widget _buildExamStatistics() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Exam Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Exams', examStats!.totalExams.toString()),
              _buildStatItem('Completed', examStats!.completedExams.toString()),
              _buildStatItem('Pass Rate', '${examStats!.passRate}%'),
              if (examStats!.bestScore != null)
                _buildStatItem('Best Score',
                    '${examStats!.bestScore!.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff4378DB),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildUserLicenses() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Vehicle Licenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...userLicenses.map((license) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      license.isActive ? Icons.check_circle : Icons.cancel,
                      color: license.isActive ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      license.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: license.isActive ? Colors.black : Colors.grey,
                      ),
                    ),
                    if (license.licenseNumber != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${license.licenseNumber})',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecentExams() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Exams',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...recentExams.take(3).map((exam) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.vehicleTypeName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatDate(exam.startedAt),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(exam.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        exam.status == 'completed' && exam.score != null
                            ? '${exam.score!.toStringAsFixed(1)}%'
                            : exam.status.toUpperCase(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// Info Tile Widget (unchanged)
class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// Updated Exam Card Widget
class ExamCard extends StatelessWidget {
  final String title;
  final String questions;
  final String duration;
  final String description;
  final VoidCallback onPressed;
  final Color buttonColor;

  const ExamCard({
    required this.title,
    required this.questions,
    required this.duration,
    required this.description,
    required this.onPressed,
    this.buttonColor = const Color(0xFF4378DB),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        color: const Color(0xFFF4FAFF),
        elevation: 4,
        shadowColor: Colors.blue.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '$questions  •  $duration',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(description),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Start Exam',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
