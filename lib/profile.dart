import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/editprofile.dart';
import 'package:driving_license_exam/models/subscription_models.dart';
import 'package:driving_license_exam/premium.dart';
import 'package:driving_license_exam/screen/login/login.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  String? date;
  String? profileImageUrl;
  // Subscription related state
  UserSubscription? currentActivePlan;
  bool isSubscriptionLoading = true;
  bool hasSubscriptionError = false;
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoadingProfile = true;
    });

    await Future.wait([
      getData(),
      _fetchUserSubscription(),
    ]);

    setState(() {
      isLoadingProfile = false;
    });
  }

  String formatBirthdaySimple(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not provided';
    }

    try {
      DateTime date = DateTime.parse(dateString);

      List<String> months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  Future<void> getData() async {
    try {
      print('=== Getting User Data for Profile ===');

      // Get both sources of data
      final user = await StorageService.getUser();
      final prefs = await SharedPreferences.getInstance();

      // Priority order for profile image URL:
      // 1. SharedPreferences (most recent update)
      // 2. User object from StorageService
      // 3. Fallback to null
      String? savedProfileImageUrl = prefs.getString('profile_image_url');
      String? userProfileImageUrl = user?.profilePhotoUrl;

      // Use SharedPreferences value if it exists and is not empty, otherwise use user data
      String? finalProfileImageUrl;
      if (savedProfileImageUrl != null && savedProfileImageUrl.isNotEmpty) {
        finalProfileImageUrl = savedProfileImageUrl;
        print(
            'Using profile image from SharedPreferences: $savedProfileImageUrl');
      } else if (userProfileImageUrl != null &&
          userProfileImageUrl.isNotEmpty) {
        finalProfileImageUrl = userProfileImageUrl;
        print('Using profile image from User object: $userProfileImageUrl');
        // Sync SharedPreferences with user data
        await prefs.setString('profile_image_url', userProfileImageUrl);
      } else {
        finalProfileImageUrl = null;
        print('No profile image found');
      }

      if (user != null) {
        print('User found: ${user.name}, ${user.email}, ${user.dateOfBirth}');
        print('Final profile image URL: $finalProfileImageUrl');

        setState(() {
          name = user.name;
          email = user.email;
          date = user.dateOfBirth;
          profileImageUrl = finalProfileImageUrl;
        });

        // If there's a mismatch, update the user object with the latest profile image
        if (finalProfileImageUrl != userProfileImageUrl) {
          print('Updating user object with latest profile image URL');
          // Create updated user object and save it
          final updatedUser = User(
            id: user.id,
            name: user.name,
            email: user.email,
            dateOfBirth: user.dateOfBirth,
            profilePhotoUrl: finalProfileImageUrl,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            // Add other user properties as needed
          );
          await StorageService.saveUser(updatedUser);
        }
      } else {
        print('No user data found in storage');
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  // Method to refresh profile data (called after returning from edit profile)
  Future<void> _refreshProfileData() async {
    try {
      print('=== Refreshing Profile Data ===');

      // Force refresh from both sources
      final user = await StorageService.getUser();
      final prefs = await SharedPreferences.getInstance();
      final String? latestProfileImageUrl =
          prefs.getString('profile_image_url');

      print('Refreshed user: ${user?.name}');
      print('Refreshed profile image URL: $latestProfileImageUrl');

      if (user != null) {
        setState(() {
          name = user.name;
          email = user.email;
          date = user.dateOfBirth;
          profileImageUrl = latestProfileImageUrl ?? user.profilePhotoUrl;
        });
      }
    } catch (e) {
      print('Error refreshing profile data: $e');
    }
  }

  Future<void> _fetchUserSubscription() async {
    try {
      setState(() {
        isSubscriptionLoading = true;
        hasSubscriptionError = false;
      });

      final userId = await StorageService.getID();
      print("Fetching user subscription for profile, userId: $userId");

      if (userId == null) {
        print("User ID is null, cannot fetch subscription");
        setState(() {
          isSubscriptionLoading = false;
          hasSubscriptionError = true;
        });
        return;
      }

      final response = await SubscriptionService.getUserSubscriptions(
        userId: userId,
        status: 'active',
      );

      print("User subscription response for profile: ${response.data}");

      if (response.success && response.data != null) {
        setState(() {
          currentActivePlan = _getCurrentActivePlan(response.data!);
          isSubscriptionLoading = false;
        });

        print(
            "Current active plan for profile: ${currentActivePlan?.plan.name}");
      } else {
        print("Failed to fetch user subscription: ${response.message}");
        setState(() {
          isSubscriptionLoading = false;
          hasSubscriptionError = true;
        });
      }
    } catch (e) {
      print("Error fetching user subscription: $e");
      setState(() {
        isSubscriptionLoading = false;
        hasSubscriptionError = true;
      });
    }
  }

  // Helper method to determine the current active plan
  UserSubscription? _getCurrentActivePlan(
      List<UserSubscription> subscriptions) {
    if (subscriptions.isEmpty) return null;

    // Filter only active and non-expired subscriptions
    final activeSubscriptions = subscriptions
        .where((sub) => sub.status.toLowerCase() == 'active' && !sub.isExpired)
        .toList();

    if (activeSubscriptions.isEmpty) return null;

    // If multiple active subscriptions, return the one with the latest end date
    activeSubscriptions.sort((a, b) => b.endDate.compareTo(a.endDate));
    return activeSubscriptions.first;
  }

  Future<void> _navigateToEditProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');

    if (userId != null) {
      // Navigate to edit profile and wait for result
      final result = await Navigator.push(
        context,
        createFadeRoute(Editprofile(
          userId: userId,
          name: name,
          dateOfBirth: formatBirthdaySimple(date),
          profileImageUrl: profileImageUrl,
        )),
      );

      // If profile was updated successfully, refresh the data
      if (result == true) {
        print('Returned from edit profile, refreshing data...');
        await _refreshProfileData();
        await _fetchUserSubscription(); // Also refresh subscription in case of any changes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                // Clear storage before logout
                await StorageService.clearStorage();

                // Also clear SharedPreferences to ensure clean state
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Navigate to login and clear all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  createFadeRoute(const LoginScreen()),
                  (Route<dynamic> route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            appbar(
              textColor: Colors.black,
              size: size,
              bgcolor: const Color(0xFFEBF6FF),
              heading: "PROFILE INFORMATION",
            ),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width * 0.9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Enhanced profile image with better error handling
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: ClipOval(
                        child: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                            ? Image.network(
                                'http://88.222.215.134:3000$profileImageUrl',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading profile image: $error');
                                  return Image.asset(
                                    'assets/images/profile.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/profile.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name ?? 'Loading...',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Personal Info Box
                    Container(
                      width: size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xffEBF6FF),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Personal Information',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 10),
                            const Text('Full name:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(name ?? 'Loading...',
                                style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 8),
                            const Text('Email address:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(email ?? 'Loading...',
                                style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 8),
                            const Text('Date of birth:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(formatBirthdaySimple(date),
                                style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: ElevatedButton(
                        onPressed: _navigateToEditProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEBF6FF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Subscription Box
                    _buildSubscriptionCard(size),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: size.width,
                      child: ElevatedButton(
                        onPressed: () => _showLogoutDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Log out'),
                      ),
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

  Widget _buildSubscriptionCard(Size size) {
    return Card(
      color: const Color(0xFFE7F4FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Subscription',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSubscriptionContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionContent() {
    if (isSubscriptionLoading) {
      return const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loading...'),
              CircularProgressIndicator(),
            ],
          ),
          SizedBox(height: 10),
          Text('Fetching subscription details...'),
        ],
      );
    }

    if (hasSubscriptionError || currentActivePlan == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('No Active Plan'),
              Text('Rs. 0',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Get premium access to unlock all features'),
          const Divider(),
          const ListTile(
            dense: true,
            leading: Icon(Icons.close, color: Colors.red),
            title: Text('Limited access to practice tests'),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.close, color: Colors.red),
            title: Text('No download access'),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.close, color: Colors.red),
            title: Text('Basic progress tracking'),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff219EBC)),
              child: const Text('Get Premium',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(currentActivePlan!.plan.name),
            Text(currentActivePlan!.plan.formattedPrice,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Expires in ${currentActivePlan!.formattedTimeRemaining}'),
        const Divider(),
        ...currentActivePlan!.plan.displayFeatures.map(
          (feature) => ListTile(
            dense: true,
            leading:
                const Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text(feature),
          ),
        ),
        if (currentActivePlan!.plan.displayFeatures.isEmpty) ...[
          const ListTile(
            dense: true,
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text('Full access to practice tests'),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text('Download past exam handbook'),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text('Progress tracking'),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text('Personalized study plan'),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff219EBC)),
            child: const Text('Manage Subscription',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
