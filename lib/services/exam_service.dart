import '../models/exam_models.dart';
import '../models/study_models.dart';
import 'api_config.dart';
import 'http_service.dart';

class ExamService {
  static Future<ApiResponse<List<UserLicense>>> getUserLicenses(
      String userId) async {
    try {
      final response = await HttpService.get(
          '${ApiConfig.examBaseUrl}/mock-exam/user/$userId/licenses');
      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((license) => UserLicense.fromJson(license))
            .toList(),
      );
    } catch (e) {
      return ApiResponse<List<UserLicense>>(
        success: false,
        data: null,
        message: 'Failed to get user licenses: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<MockExam>> startMockExam({
    required String userId,
    String language = 'en',
  }) async {
    try {
      final response = await HttpService.post(
        '${ApiConfig.examBaseUrl}/mock-exam/start',
        body: {
          'user_id': userId,
          'language': language,
        },
      );
      return ApiResponse.fromJson(response, (data) => MockExam.fromJson(data));
    } catch (e) {
      return ApiResponse<MockExam>(
        success: false,
        data: null,
        message: 'Failed to start mock exam: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<ExamData>> getExamQuestions(String examId) async {
    try {
      final response = await HttpService.get(
          '${ApiConfig.examBaseUrl}/mock-exam/$examId/questions');
      return ApiResponse.fromJson(
        response,
        (data) => ExamData.fromJson(data),
      );
    } catch (e) {
      return ApiResponse<ExamData>(
        success: false,
        data: null,
        message: 'Failed to get exam questions: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> submitExamAnswer({
    required String examId,
    required int questionId,
    required int selectedOption,
    int? timeTakenSeconds,
  }) async {
    try {
      final response = await HttpService.post(
        '${ApiConfig.examBaseUrl}/mock-exam/$examId/questions/$questionId/answer',
        body: {
          'selected_option': selectedOption,
          if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
        },
      );
      return ApiResponse.fromJson(response, (data) => data);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: 'Failed to submit answer: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> submitExam(
      String examId) async {
    try {
      final response = await HttpService.post(
          '${ApiConfig.examBaseUrl}/mock-exam/$examId/submit');
      return ApiResponse.fromJson(response, (data) => data);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: 'Failed to submit exam: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<ExamResult>> getExamResults(String examId) async {
    try {
      final response = await HttpService.get(
          '${ApiConfig.examBaseUrl}/mock-exam/$examId/results');
      return ApiResponse.fromJson(
          response, (data) => ExamResult.fromJson(data));
    } catch (e) {
      return ApiResponse<ExamResult>(
        success: false,
        data: null,
        message: 'Failed to get exam results: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getExamHistory({
    required String userId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await HttpService.get(
        '${ApiConfig.examBaseUrl}/mock-exam/user/$userId/history?limit=$limit&page=$page',
      );

      // Parse the response structure
      if (response['success'] && response['data'] != null) {
        final data = response['data'];
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: {
            'exam_history': (data['exam_history'] as List)
                .map((history) => ExamHistory.fromJson(history))
                .toList(),
            'statistics': ExamStatistics.fromJson(data['statistics']),
            'pagination': data['pagination'],
          },
          message: response['message'] ?? '',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          data: null,
          message: response['message'] ?? 'Failed to get exam history',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: 'Failed to get exam history: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getExamStatus(
      String examId) async {
    try {
      final response = await HttpService.get(
          '${ApiConfig.examBaseUrl}/mock-exam/$examId/status');
      return ApiResponse.fromJson(response, (data) => data);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        data: null,
        message: 'Failed to get exam status: ${e.toString()}',
      );
    }
  }

  // Helper method to check if user has any active licenses
  static Future<bool> hasActiveLicenses(String userId) async {
    try {
      final response = await getUserLicenses(userId);
      return response.success &&
          response.data != null &&
          response.data!.any((license) => license.isActive);
    } catch (e) {
      return false;
    }
  }

  // Helper method to get user's highest vehicle type
  static Future<int?> getUserHighestVehicleType(String userId) async {
    try {
      final response = await getUserLicenses(userId);
      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        // Get the license with highest hierarchy level (backend returns them ordered)
        return response.data!.first.vehicleTypeId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
