import 'package:driving_license_exam/component/backbutton.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/mockexam.dart';
import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final Color buttonColor;
  final String source;
  final int? lessonId;
  final String? lessonTitle;
  final int? vehicleTypeId;
  final String? userId;

  const LanguageSelectionScreen({
    super.key,
    required this.buttonColor,
    required this.source,
    this.lessonId,
    this.lessonTitle,
    this.vehicleTypeId,
    this.userId,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String selectedLanguage = 'English';

  final Map<String, String> languageMapping = {
    'English': 'en',
    'Sinhala': 'si',
    'Tamil': 'ta',
  };

  final List<String> languages = ['English', 'Sinhala', 'Tamil'];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.15),

                    // Show lesson title if available
                    if (widget.lessonTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: widget.buttonColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.buttonColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.book,
                                color: widget.buttonColor,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.lessonTitle!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: widget.buttonColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Text(
                      "Select Your Language",
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 30),

                    // Language Buttons
                    ...languages.map((lang) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => selectedLanguage = lang),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  vertical: size.height * 0.02),
                              decoration: BoxDecoration(
                                color: selectedLanguage == lang
                                    ? widget.buttonColor.withOpacity(0.1)
                                    : Colors.white,
                                border: Border.all(
                                  color: selectedLanguage == lang
                                      ? widget.buttonColor
                                      : Colors.grey.shade300,
                                  width: selectedLanguage == lang ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  lang,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: selectedLanguage == lang
                                        ? widget.buttonColor
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )),

                    const SizedBox(height: 15),
                    const Text(
                      "You can change the language later in settings",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),

                    SizedBox(height: size.height * 0.06),

                    // Start Button
                    ElevatedButton(
                      onPressed: () {
                        String languageCode =
                            languageMapping[selectedLanguage] ?? 'en';

                        Navigator.push(
                          context,
                          createFadeRoute(MockExamDo(
                            selectedLanguage: selectedLanguage,
                            selectedLanguageCode: languageCode,
                            source: widget.source,
                            lessonId: widget.lessonId,
                            vehicleTypeId: widget.vehicleTypeId,
                            userId: widget.userId,
                          )),
                        );

                        print(
                            "Starting ${widget.source} in $selectedLanguage ($languageCode)");
                        if (widget.lessonId != null) {
                          print(
                              "Lesson ID: ${widget.lessonId}, Vehicle Type: ${widget.vehicleTypeId}");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.buttonColor,
                        padding:
                            EdgeInsets.symmetric(vertical: size.height * 0.021),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.source == "StudyMaterials"
                            ? "Start Learning"
                            : "Start Exam",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          backbutton(size: size)
        ],
      ),
    );
  }
}
