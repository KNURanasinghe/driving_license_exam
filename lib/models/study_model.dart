// Add these classes to your existing models/study_models.dart file

class Lesson {
  final int id;
  final String title;
  final String? imageUrl;
  final int categoryId;
  final int lessonOrder;
  final int questionCount;

  Lesson({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.categoryId,
    required this.lessonOrder,
    required this.questionCount,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      lessonOrder: json['lesson_order'] ?? 0,
      questionCount: json['question_count'] ?? 0,
    );
  }
}

class Question {
  final int id;
  final String questionText;
  final int correctOption;
  final String? explanation;
  final int vehicleTypeId;
  final String vehicleTypeName;
  final String language;
  final List<QuestionOption> options;
  final String? questionAudio;
  final int? questionAudioDuration;
  final Map<String, bool> hasAudio;

  Question({
    required this.id,
    required this.questionText,
    required this.correctOption,
    this.explanation,
    required this.vehicleTypeId,
    required this.vehicleTypeName,
    required this.language,
    required this.options,
    this.questionAudio,
    this.questionAudioDuration,
    required this.hasAudio,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      questionText: json['question_text'],
      correctOption: json['correct_option'],
      explanation: json['explanation'],
      vehicleTypeId: json['vehicle_type_id'],
      vehicleTypeName: json['vehicle_type_name'],
      language: json['language'],
      options: (json['options'] as List)
          .map((option) => QuestionOption.fromJson(option))
          .toList(),
      questionAudio: json['question_audio'],
      questionAudioDuration: json['question_audio_duration'],
      hasAudio: Map<String, bool>.from(json['has_audio']),
    );
  }
}

class QuestionOption {
  final int optionNumber;
  final String optionText;
  final int optionId;
  final String? audioUrl;
  final int? audioDuration;

  QuestionOption({
    required this.optionNumber,
    required this.optionText,
    required this.optionId,
    this.audioUrl,
    this.audioDuration,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      optionNumber: json['option_number'],
      optionText: json['option_text'],
      optionId: json['option_id'],
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration'],
    );
  }
}

class Subscription {
  final String subscriptionId;
  final SubscriptionPlan plan;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;
  final bool isExpired;

  Subscription({
    required this.subscriptionId,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.isExpired,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      subscriptionId: json['subscription_id'],
      plan: SubscriptionPlan.fromJson(json['plan']),
      status: json['status'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      daysRemaining: json['days_remaining'],
      isExpired: json['is_expired'],
    );
  }
}

class SubscriptionPlan {
  final int id;
  final String name;
  final int durationMonths;
  final double price;
  final String? vehicleType;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.price,
    this.vehicleType,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      durationMonths: json['duration_months'],
      price: json['price'].toDouble(),
      vehicleType: json['vehicle_type'],
    );
  }
}
