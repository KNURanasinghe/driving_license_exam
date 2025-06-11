import 'dart:io';

import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/backbutton.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user_models.dart';
import 'services/user_service.dart';

class Editprofile extends StatefulWidget {
  final String userId;
  final String? name;
  final String? dateOfBirth;
  final String? profileImageUrl;

  const Editprofile({
    super.key,
    required this.userId,
    this.name,
    this.dateOfBirth,
    required this.profileImageUrl,
  });

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? _selectedImage;
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  DateTime? _selectedDate;
  bool _showPasswordFields = false;

  // Store original values for comparison
  String? _originalName;
  String? _originalDateOfBirth;
  String? _originalProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCurrentUserData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.name ?? '');
    _dobController = TextEditingController(text: widget.dateOfBirth ?? '');
    _currentProfileImageUrl = widget.profileImageUrl;

    // Store original values
    _originalName = widget.name ?? '';
    _originalDateOfBirth = widget.dateOfBirth ?? '';
    _originalProfileImageUrl = widget.profileImageUrl;

    if (widget.dateOfBirth != null && widget.dateOfBirth!.isNotEmpty) {
      try {
        _selectedDate = _parseDateFromString(widget.dateOfBirth!);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final user = await StorageService.getUser();
      if (user != null && mounted) {
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name ?? '';
            _originalName = user.name ?? '';
          }
          _currentProfileImageUrl ??= user.profilePhotoUrl;
          _originalProfileImageUrl ??= user.profilePhotoUrl;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  DateTime? _parseDateFromString(String dateString) {
    try {
      if (dateString.contains('-')) {
        return DateTime.parse(dateString);
      } else if (dateString.contains('/')) {
        List<String> parts = dateString.split('/');
        if (parts.length == 3) {
          return DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else {
        List<String> parts = dateString.split(' ');
        if (parts.length == 3) {
          int day = int.parse(parts[0]);
          int year = int.parse(parts[2]);
          Map<String, int> months = {
            'Jan': 1,
            'Feb': 2,
            'Mar': 3,
            'Apr': 4,
            'May': 5,
            'Jun': 6,
            'Jul': 7,
            'Aug': 8,
            'Sep': 9,
            'Oct': 10,
            'Nov': 11,
            'Dec': 12
          };
          int month = months[parts[1]] ?? 1;
          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _currentProfileImageUrl =
              null; // Clear network image to show local file
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _currentProfileImageUrl =
              null; // Clear network image to show local file
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error taking picture: $e');
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Check if profile data has changed
  bool _hasProfileDataChanged() {
    bool nameChanged =
        _nameController.text.trim() != (_originalName ?? '').trim();
    bool dateChanged =
        _dobController.text.trim() != (_originalDateOfBirth ?? '').trim();
    bool passwordChanged =
        _showPasswordFields && _passwordController.text.isNotEmpty;

    return nameChanged || dateChanged || passwordChanged;
  }

  // Check if image has changed
  bool _hasImageChanged() {
    return _selectedImage != null;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate password match if password fields are shown
    if (_showPasswordFields &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool hasProfileDataChanges = _hasProfileDataChanged();
      bool hasImageChanges = _hasImageChanged();

      // Track what was updated for success message
      List<String> updatedItems = [];
      User? updatedUser;

      // Update profile data if there are changes
      if (hasProfileDataChanges) {
        String? dateOfBirthForApi;
        if (_selectedDate != null) {
          dateOfBirthForApi = _selectedDate!.toIso8601String().split('T')[0];
        }

        final updateResponse = await UserService.updateUser(
          userId: widget.userId,
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          password: (_showPasswordFields && _passwordController.text.isNotEmpty)
              ? _passwordController.text
              : null,
          dateOfBirth: dateOfBirthForApi,
        );

        if (!updateResponse.success) {
          throw Exception(
              updateResponse.message ?? 'Failed to update profile data');
        }

        updatedUser = updateResponse.data;
        updatedItems.add('profile information');
      }

      // Update profile image if there's a new image
      if (hasImageChanges) {
        final uploadResponse = await UserService.uploadProfilePhoto(
          userId: widget.userId,
          photoFile: _selectedImage!,
        );

        if (!uploadResponse.success) {
          throw Exception(
              uploadResponse.message ?? 'Failed to upload profile photo');
        }

        updatedUser = uploadResponse.data;
        updatedItems.add('profile image');
      }

      // Ensure proper data synchronization
      if (updatedUser != null) {
        // 1. Save complete updated user to StorageService
        await StorageService.saveUser(updatedUser);

        // 2. Update SharedPreferences with latest profile image URL
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'profile_image_url', updatedUser.profilePhotoUrl ?? '');

        // 3. Update local state
        setState(() {
          if (hasImageChanges) {
            _currentProfileImageUrl = updatedUser!.profilePhotoUrl;
            _selectedImage = null;
            _originalProfileImageUrl = updatedUser.profilePhotoUrl;
          }
          if (hasProfileDataChanges) {
            _originalName = _nameController.text.trim();
            _originalDateOfBirth = _dobController.text;
            // Clear password fields after successful update
            if (_showPasswordFields) {
              _passwordController.clear();
              _confirmPasswordController.clear();
              _showPasswordFields = false;
            }
          }
        });

        print('Data synchronization completed:');
        print(
            'StorageService user: ${updatedUser.name}, ${updatedUser.profilePhotoUrl}');
        print(
            'SharedPreferences profile_image_url: ${updatedUser.profilePhotoUrl}');
      }

      // Show appropriate message based on what was updated
      if (updatedItems.isNotEmpty) {
        String message = 'Updated: ${updatedItems.join(' and ')}';
        _showSuccessSnackBar(message);
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar('No changes detected');
      }
    } catch (e) {
      print('Error updating profile: $e');
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to save only profile image
  Future<void> _saveImageOnly() async {
    if (_selectedImage == null) {
      _showErrorSnackBar('No image selected');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uploadResponse = await UserService.uploadProfilePhoto(
        userId: widget.userId,
        photoFile: _selectedImage!,
      );

      if (!uploadResponse.success) {
        throw Exception(
            uploadResponse.message ?? 'Failed to upload profile photo');
      }

      final updatedUser = uploadResponse.data;
      if (updatedUser != null) {
        // 1. Save updated user to StorageService
        await StorageService.saveUser(updatedUser);

        // 2. Save profile image URL to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'profile_image_url', updatedUser.profilePhotoUrl ?? '');

        // 3. Update local state
        setState(() {
          _currentProfileImageUrl = updatedUser.profilePhotoUrl;
          _selectedImage = null;
          _originalProfileImageUrl = updatedUser.profilePhotoUrl;
        });

        print('Image saved successfully:');
        print('StorageService user updated: ${updatedUser.profilePhotoUrl}');
        print('SharedPreferences updated: ${updatedUser.profilePhotoUrl}');
      }

      _showSuccessSnackBar('Profile image updated successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      print('Error updating profile image: $e');
      _showErrorSnackBar('Failed to update profile image: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    bool hasProfileChanges = _hasProfileDataChanged();
    bool hasImageChanges = _hasImageChanged();

    return Scaffold(
      bottomNavigationBar: backbutton(size: size),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              appbar(
                textColor: Colors.black,
                size: size,
                bgcolor: const Color(0xFFEBF6FF),
                heading: "EDIT PROFILE INFORMATION",
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size.width * 0.9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (_currentProfileImageUrl != null &&
                                              _currentProfileImageUrl!
                                                  .isNotEmpty)
                                          ? NetworkImage(
                                              'http://88.222.215.134:3000$_currentProfileImageUrl')
                                          : const AssetImage(
                                                  'assets/images/profile.png')
                                              as ImageProvider,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xff219EBC),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                child: ElevatedButton(
                                  onPressed: _showImagePickerDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEBF6FF),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: const Text(
                                    'Change Image',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              // Add button to save image only if image is selected
                              if (hasImageChanges) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _saveImageOnly,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff219EBC),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    child: const Text(
                                      'Save Image',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
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
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Full name:',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                style: const TextStyle(fontSize: 15),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Date of birth:',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                style: const TextStyle(fontSize: 15),
                                onTap: () => _selectDate(context),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Change Password:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  Switch(
                                    value: _showPasswordFields,
                                    onChanged: (value) {
                                      setState(() {
                                        _showPasswordFields = value;
                                        if (!value) {
                                          _passwordController.clear();
                                          _confirmPasswordController.clear();
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xff219EBC),
                                  ),
                                ],
                              ),
                              if (_showPasswordFields) ...[
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon: IconButton(
                                      icon: Icon(_isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordFields &&
                                        (value == null || value.length < 6)) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_isConfirmPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon: IconButton(
                                      icon: Icon(_isConfirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordFields &&
                                        value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Main save button - only show if there are profile data changes
                      if (hasProfileChanges) ...[
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff219EBC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Saving...'),
                                    ],
                                  )
                                : const Text(
                                    'Save Changes',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Alternative save all button if no individual changes detected
                      if (!hasProfileChanges && !hasImageChanges) ...[
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: ElevatedButton(
                            onPressed: () {
                              _showErrorSnackBar('No changes detected');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'No Changes to Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: size.height * 0.1),
                    ],
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
