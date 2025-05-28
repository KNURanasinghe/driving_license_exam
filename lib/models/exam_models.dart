// lib/models/exam_models.dart

class MockExam {
  final String examId;
  final int totalQuestions;
  final int timeLimitMinutes;
  final String language;
  final int vehicleTypeId;
  final List<int> accessibleVehicleTypes;
  final String startedAt;

  MockExam({
    required this.examId,
    required this.totalQuestions,
    required this.timeLimitMinutes,
    required this.language,
    required this.vehicleTypeId,
    required this.accessibleVehicleTypes,
    required this.startedAt,
  });

  factory MockExam.fromJson(Map<String, dynamic> json) {
    return MockExam(
      examId: json['exam_id'],
      totalQuestions: json['total_questions'],
      timeLimitMinutes: json['time_limit_minutes'],
      language: json['language'],
      vehicleTypeId: json['vehicle_type_id'],
      accessibleVehicleTypes:
          List<int>.from(json['accessible_vehicle_types'] ?? []),
      startedAt: json['started_at'],
    );
  }
}

class ExamQuestion {
  final int questionOrder;
  final int id;
  final String questionText;
  final List<ExamOption> options;
  final String categoryName;
  final String lessonTitle;
  final String? imageUrl;
  final String? questionAudio;
  final int? questionAudioDuration;

  ExamQuestion({
    required this.questionOrder,
    required this.id,
    required this.questionText,
    required this.options,
    required this.categoryName,
    required this.lessonTitle,
    this.imageUrl,
    this.questionAudio,
    this.questionAudioDuration,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      questionOrder: json['question_order'],
      id: json['id'],
      questionText: json['question_text'],
      options: (json['options'] as List)
          .map((option) => ExamOption.fromJson(option))
          .toList(),
      categoryName: json['category_name'],
      lessonTitle: json['lesson_title'],
      imageUrl: json['image_url'],
      questionAudio: json['question_audio'],
      questionAudioDuration: json['question_audio_duration'],
    );
  }
}

class ExamOption {
  final int optionNumber;
  final String optionText;

  ExamOption({
    required this.optionNumber,
    required this.optionText,
  });

  factory ExamOption.fromJson(Map<String, dynamic> json) {
    return ExamOption(
      optionNumber: json['option_number'],
      optionText: json['option_text'],
    );
  }
}

class ExamData {
  final String examId;
  final int totalQuestions;
  final String language;
  final int timeLimitMinutes;
  final int remainingMinutes;
  final int remainingSeconds;
  final String startedAt;
  final List<ExamQuestion> questions;

  ExamData({
    required this.examId,
    required this.totalQuestions,
    required this.language,
    required this.timeLimitMinutes,
    required this.remainingMinutes,
    required this.remainingSeconds,
    required this.startedAt,
    required this.questions,
  });

  factory ExamData.fromJson(Map<String, dynamic> json) {
    return ExamData(
      examId: json['exam_id'],
      totalQuestions: json['total_questions'],
      language: json['language'],
      timeLimitMinutes: json['time_limit_minutes'],
      remainingMinutes: json['remaining_minutes'],
      remainingSeconds: json['remaining_seconds'],
      startedAt: json['started_at'],
      questions: (json['questions'] as List)
          .map((q) => ExamQuestion.fromJson(q))
          .toList(),
    );
  }
}

class ExamResult {
  final String examId;
  final double scorePercentage;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalQuestions;
  final bool passed;
  final String grade;
  final int? examDurationMinutes;
  final String vehicleType;
  final String language;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<CategoryPerformance> categoryPerformance;
  final List<QuestionResult> questionResults;

  ExamResult({
    required this.examId,
    required this.scorePercentage,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalQuestions,
    required this.passed,
    required this.grade,
    this.examDurationMinutes,
    required this.vehicleType,
    required this.language,
    required this.startedAt,
    this.completedAt,
    required this.categoryPerformance,
    required this.questionResults,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      examId: json['exam_id'] ?? '',
      // Handle string to double conversion
      scorePercentage:
          double.tryParse(json['score_percentage'].toString()) ?? 0.0,
      correctAnswers: json['correct_answers'] ?? 0,
      wrongAnswers: json['wrong_answers'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      passed: json['passed'] ?? false,
      grade: json['grade'] ?? 'F',
      examDurationMinutes: json['exam_duration_minutes'],
      vehicleType: json['vehicle_type'] ?? '',
      language: json['language'] ?? 'en',
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      categoryPerformance:
          (json['category_performance'] as List<dynamic>? ?? [])
              .map((item) => CategoryPerformance.fromJson(item))
              .toList(),
      questionResults: (json['question_results'] as List<dynamic>? ?? [])
          .map((item) => QuestionResult.fromJson(item))
          .toList(),
    );
  }
}

class CategoryPerformance {
  final String categoryName;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double accuracyPercentage;

  CategoryPerformance({
    required this.categoryName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.accuracyPercentage,
  });

  factory CategoryPerformance.fromJson(Map<String, dynamic> json) {
    return CategoryPerformance(
      categoryName: json['category_name'] ?? '',
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      wrongAnswers: json['wrong_answers'] ?? 0,
      // Handle string to double conversion
      accuracyPercentage:
          double.tryParse(json['accuracy_percentage'].toString()) ?? 0.0,
    );
  }
}

class QuestionResult {
  final int questionOrder;
  final String questionText;
  final int? selectedOption;
  final bool isCorrect;
  final int? timeTakenSeconds;
  final int correctOption;
  final String categoryName;

  QuestionResult({
    required this.questionOrder,
    required this.questionText,
    this.selectedOption,
    required this.isCorrect,
    this.timeTakenSeconds,
    required this.correctOption,
    required this.categoryName,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionOrder: json['question_order'] ?? 0,
      questionText: json['question_text'] ?? '',
      selectedOption: json['selected_option'],
      // Handle 0/1 to boolean conversion
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
      timeTakenSeconds: json['time_taken_seconds'],
      correctOption: json['correct_option'] ?? 1,
      categoryName: json['category_name'] ?? '',
    );
  }
}

class UserLicense {
  final int id;
  final String userId;
  final int vehicleTypeId;
  final String? licenseNumber;
  final String name;
  final String displayName;
  final int hierarchyLevel;
  final bool isActive;

  UserLicense({
    required this.id,
    required this.userId,
    required this.vehicleTypeId,
    this.licenseNumber,
    required this.name,
    required this.displayName,
    required this.hierarchyLevel,
    required this.isActive,
  });

  factory UserLicense.fromJson(Map<String, dynamic> json) {
    return UserLicense(
      id: json['id'],
      userId: json['user_id'],
      vehicleTypeId: json['vehicle_type_id'],
      licenseNumber: json['license_number'],
      name: json['name'],
      displayName: json['display_name'],
      hierarchyLevel: json['hierarchy_level'],
      isActive: json['is_active'] == 1,
    );
  }
}

class ExamHistory {
  final String id;
  final double? score;
  final int? correctAnswers;
  final int? wrongAnswers;
  final int totalQuestions;
  final String status;
  final String language;
  final String startedAt;
  final String? completedAt;
  final String vehicleTypeName;
  final int? durationMinutes;

  ExamHistory({
    required this.id,
    this.score,
    this.correctAnswers,
    this.wrongAnswers,
    required this.totalQuestions,
    required this.status,
    required this.language,
    required this.startedAt,
    this.completedAt,
    required this.vehicleTypeName,
    this.durationMinutes,
  });

  factory ExamHistory.fromJson(Map<String, dynamic> json) {
    return ExamHistory(
      id: json['id'],
      score: json['score']?.toDouble(),
      correctAnswers: json['correct_answers'],
      wrongAnswers: json['wrong_answers'],
      totalQuestions: json['total_questions'],
      status: json['status'],
      language: json['language'],
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
      vehicleTypeName: json['vehicle_type_name'],
      durationMinutes: json['duration_minutes'],
    );
  }
}

class ExamStatistics {
  final int totalExams;
  final int completedExams;
  final double? averageScore;
  final double? bestScore;
  final int passedExams;
  final int passRate;

  ExamStatistics({
    required this.totalExams,
    required this.completedExams,
    this.averageScore,
    this.bestScore,
    required this.passedExams,
    required this.passRate,
  });

  factory ExamStatistics.fromJson(Map<String, dynamic> json) {
    return ExamStatistics(
      totalExams: json['total_exams'],
      completedExams: json['completed_exams'],
      averageScore: json['average_score']?.toDouble(),
      bestScore: json['best_score']?.toDouble(),
      passedExams: json['passed_exams'],
      passRate: json['pass_rate'],
    );
  }
}
