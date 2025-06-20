import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/study_course.dart';
import 'package:driving_license_exam/services/socket_service.dart';
import 'package:flutter/material.dart';

import 'models/study_models.dart';
import 'services/study_service.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  List<Category> categories = [];
  bool isLoading = true;
  String? errorMessage;

  // Map category names to icons and colors
  final Map<String, Map<String, dynamic>> categoryConfig = {
    'alertness': {
      'icon': Icons.visibility,
      'borderColor': Colors.orange,
    },
    'attitud': {
      'icon': Icons.emoji_emotions,
      'borderColor': Colors.indigo,
    },
    'attitude': {
      'icon': Icons.emoji_emotions,
      'borderColor': Colors.indigo,
    },
    'hazard_awareness': {
      'icon': Icons.warning_amber,
      'borderColor': Colors.red,
    },
    'safety_procedures': {
      'icon': Icons.shield,
      'borderColor': Colors.green,
    },
    'equipment_operations': {
      'icon': Icons.construction,
      'borderColor': Colors.amber,
    },
    'emergency_response': {
      'icon': Icons.health_and_safety,
      'borderColor': Colors.deepOrange,
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeSocketAndFetchData();
  }

  @override
  void dispose() {
    // Clear socket callbacks when this screen is disposed
    SocketService.clearCallbacks();
    super.dispose();
  }

  Future<void> _initializeSocketAndFetchData() async {
    // Initialize socket connection
    _setupSocketConnection();

    // Fetch initial categories
    await _fetchCategories();
  }

  void _setupSocketConnection() {
    // Initialize socket if not already done
    SocketService.initialize();
    SocketService.connect();

    // Set up category event callbacks
    SocketService.setCategoryEventCallbacks(
      onCreated: _onCategoryCreated,
      onUpdated: _onCategoryUpdated,
      onDeleted: _onCategoryDeleted,
    );
  }

  // Socket event handlers
  void _onCategoryCreated(Category newCategory) {
    if (mounted) {
      setState(() {
        categories.add(newCategory);
      });

      // Show a snackbar to notify user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New category "${newCategory.displayName}" added!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Optionally scroll to the new category or highlight it
              _highlightNewCategory(newCategory.id);
            },
          ),
        ),
      );
    }
  }

  void _onCategoryUpdated(Category updatedCategory) {
    if (mounted) {
      setState(() {
        final index =
            categories.indexWhere((cat) => cat.id == updatedCategory.id);
        if (index != -1) {
          categories[index] = updatedCategory;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "${updatedCategory.displayName}" updated!'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onCategoryDeleted(int categoryId) {
    if (mounted) {
      final deletedCategory = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () =>
            Category(id: -1, name: '', displayName: 'Unknown', lessonCount: 0),
      );

      setState(() {
        categories.removeWhere((cat) => cat.id == categoryId);
      });

      if (deletedCategory.id != -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${deletedCategory.displayName}" removed!'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _highlightNewCategory(int categoryId) {
    // You can implement category highlighting logic here
    // For example, scroll to the category or show a brief animation
    print('Highlighting category with ID: $categoryId');
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await StudyService.getAllCategories();

      if (response.success && response.data != null) {
        setState(() {
          categories = response.data!;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load categories';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading categories: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Get icon for category
  IconData _getCategoryIcon(String categoryName) {
    return categoryConfig[categoryName.toLowerCase()]?['icon'] ?? Icons.book;
  }

  // Get border color for category
  Color _getCategoryBorderColor(String categoryName) {
    return categoryConfig[categoryName.toLowerCase()]?['borderColor'] ??
        Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              appbar(
                  size: size,
                  bgcolor: const Color(0xff28A164),
                  textColor: Colors.white,
                  heading: 'STUDY  MATERIALS'),

              // Search and Featured Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            "Explore categories to enhance your knowledge",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey),
                          ),
                        ),
                        // Socket connection indicator
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: SocketService.isConnected
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SocketService.isConnected
                                  ? Colors.green
                                  : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                SocketService.isConnected
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                size: 14,
                                color: SocketService.isConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                SocketService.isConnected ? 'Live' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: SocketService.isConnected
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 16),
                    // Featured Banner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Image.asset('assets/images/studymaterial.png',
                              width: double.infinity, fit: BoxFit.cover),
                          Container(
                            padding: const EdgeInsets.all(8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent
                                ],
                                begin: Alignment.center,
                                end: Alignment.topCenter,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: const Color(0xff219EBC),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  child: const Text(
                                    'Featured ',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                const Text(
                                  'Complete Safety Training',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Categories",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            if (isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            if (errorMessage != null)
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _fetchCategories,
                                iconSize: 20,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Category Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCategoryGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final size = MediaQuery.of(context).size;
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
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
              onPressed: _fetchCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No categories available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              SocketService.isConnected
                  ? 'New categories will appear here automatically'
                  : 'Check your connection and try again',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                createFadeRoute(StudyCourseScreen(
                  size: MediaQuery.of(context).size,
                  categoryTitle: category.displayName,
                  categoryId: category.id,
                )));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              border: Border.all(
                  color: _getCategoryBorderColor(category.name), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03, vertical: size.height * 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_getCategoryIcon(category.name), size: 28),
                const SizedBox(height: 8),
                Text(
                  category.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const Text("View lessons",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
