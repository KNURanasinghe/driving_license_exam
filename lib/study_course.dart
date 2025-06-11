import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/backbutton.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/languageselction.dart';
import 'package:driving_license_exam/models/study_models.dart';
import 'package:driving_license_exam/models/subscription_models.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/study_service.dart';
import 'package:flutter/material.dart';

import 'services/subscription_service.dart';

class StudyCourseScreen extends StatefulWidget {
  final Size size;
  final String categoryTitle;
  final int categoryId;

  const StudyCourseScreen({
    super.key,
    required this.size,
    required this.categoryTitle,
    required this.categoryId,
  });

  @override
  State<StudyCourseScreen> createState() => _StudyCourseScreenState();
}

class _StudyCourseScreenState extends State<StudyCourseScreen> {
  List<Lesson> lessons = [];
  bool isLoading = true;
  String? errorMessage;
  int? vehicleTypeId;
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchLessons();
  }

  Future<void> _initializeAndFetchLessons() async {
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

      // Get user's vehicle type from subscription
      vehicleTypeId = await _getUserVehicleTypeId();
      if (vehicleTypeId == null) {
        setState(() {
          errorMessage =
              'No active subscription found. Please subscribe to access lessons.';
          isLoading = false;
        });
        return;
      }

      // Fetch lessons for this vehicle type and category
      await _fetchLessons();
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<int?> _getUserVehicleTypeId() async {
    try {
      if (userId == null) return null;

      // Get user's active subscriptions
      final subscriptionResponse =
          await SubscriptionService.getUserSubscriptions(
        userId: userId!,
        status: 'active',
      );

      if (subscriptionResponse.success &&
          subscriptionResponse.data != null &&
          subscriptionResponse.data!.isNotEmpty) {
        final subscription = subscriptionResponse.data!.first;

        // Get detailed subscription info to get vehicle type
        final detailedResponse = await SubscriptionService.getSubscription(
          subscription.subscriptionId,
        );

        if (detailedResponse.success && detailedResponse.data != null) {
          final vehicleType = detailedResponse.data!.plan.vehicleType;

          // Map vehicle type string to ID based on your system
          switch (vehicleType.toLowerCase()) {
            case 'motorcycle':
              return 1;
            case 'light_vehicle':
              return 2;
            case 'heavy_vehicle':
              return 3;
            case 'special':
              return 4;
            default:
              return 0; // Default fallback
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting vehicle type: $e');
      return null;
    }
  }

  Future<void> _fetchLessons() async {
    try {
      if (vehicleTypeId == null) return;

      // Use your existing StudyService method
      final response = await StudyService.getLessons(
        vehicleTypeId: vehicleTypeId!,
        categoryId: widget.categoryId,
      );

      if (response.success && response.data != null) {
        setState(() {
          lessons = response.data!;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load lessons';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading lessons: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _retryFetch() async {
    await _initializeAndFetchLessons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          appbar(
            size: widget.size,
            bgcolor: const Color(0xff28A164),
            textColor: const Color.fromARGB(255, 255, 255, 255),
            heading: widget.categoryTitle,
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),

          backbutton(size: widget.size)
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff28A164)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading lessons...',
              style: TextStyle(fontSize: 16),
            ),
          ],
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
                onPressed: _retryFetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff28A164),
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

    if (lessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No lessons available for this category',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return Card(
          color: Colors.white,
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xff28A164).withOpacity(0.1),
              ),
              child: lesson.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        lesson.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.book,
                            size: 30,
                            color: Color(0xff28A164),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff28A164),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.book,
                      size: 30,
                      color: Color(0xff28A164),
                    ),
            ),
            title: Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${lesson.questionCount} questions available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (lesson.lessonOrder > 0)
                  Text(
                    'Lesson ${lesson.lessonOrder}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xff28A164),
            ),
            onTap: () {
              if (vehicleTypeId != null && userId != null) {
                Navigator.push(
                  context,
                  createFadeRoute(LanguageSelectionScreen(
                    source: "StudyMaterials",
                    buttonColor: const Color(0xff28A164),
                    lessonId: lesson.id,
                    lessonTitle: lesson.title,
                    vehicleTypeId: vehicleTypeId!,
                    userId: userId!,
                  )),
                );
              }
            },
          ),
        );
      },
    );
  }
}
