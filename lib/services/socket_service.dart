// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:driving_license_exam/services/api_config.dart';
import '../models/study_models.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  // Callbacks for real-time updates
  static Function(Category)? onCategoryCreated;
  static Function(Category)? onCategoryUpdated;
  static Function(int)? onCategoryDeleted;
  static Function(Lesson)? onLessonCreated;
  static Function(Lesson)? onLessonUpdated;
  static Function(int)? onLessonDeleted;

  // Initialize socket connection - CONNECT DIRECTLY TO STUDY SERVICE
  static void initialize() {
    if (_socket != null) return;

    try {
      _socket = IO.io(
        'http://88.222.215.134:3003', // Connect directly to study service, not gateway
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Add polling as fallback
            .disableAutoConnect()
            .setTimeout(5000)
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      _setupEventHandlers();
    } catch (e) {
      print('Socket initialization error: $e');
    }
  }

  // Rest of your code remains the same...
  // Connect to socket
  static void connect() {
    if (_socket == null) {
      initialize();
    }

    if (!_isConnected) {
      _socket?.connect();
    }
  }

  // Disconnect from socket
  static void disconnect() {
    if (_socket != null && _isConnected) {
      _socket?.disconnect();
    }
  }

  // Setup event handlers
  static void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('✅ Socket connected successfully');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('🔴 Socket connection error: $error');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('🔴 Socket error: $error');
    });

    // Category events
    _socket!.on('categoryCreated', (data) {
      print('📦 New category created: $data');
      try {
        if (data != null && data['category'] != null) {
          final category = Category.fromJson(data['category']);
          onCategoryCreated?.call(category);
        }
      } catch (e) {
        print('Error parsing category created data: $e');
      }
    });

    _socket!.on('categoryUpdated', (data) {
      print('📝 Category updated: $data');
      try {
        if (data != null && data['category'] != null) {
          final category = Category.fromJson(data['category']);
          onCategoryUpdated?.call(category);
        }
      } catch (e) {
        print('Error parsing category updated data: $e');
      }
    });

    _socket!.on('categoryDeleted', (data) {
      print('🗑️ Category deleted: $data');
      try {
        if (data != null && data['categoryId'] != null) {
          final categoryId = data['categoryId'] as int;
          onCategoryDeleted?.call(categoryId);
        }
      } catch (e) {
        print('Error parsing category deleted data: $e');
      }
    });

    // Lesson events
    _socket!.on('lessonCreated', (data) {
      print('📚 New lesson created: $data');
      try {
        if (data != null && data['lesson'] != null) {
          final lesson = Lesson.fromJson(data['lesson']);
          onLessonCreated?.call(lesson);
        }
      } catch (e) {
        print('Error parsing lesson created data: $e');
      }
    });

    _socket!.on('lessonUpdated', (data) {
      print('✏️ Lesson updated: $data');
      try {
        if (data != null && data['lesson'] != null) {
          final lesson = Lesson.fromJson(data['lesson']);
          onLessonUpdated?.call(lesson);
        }
      } catch (e) {
        print('Error parsing lesson updated data: $e');
      }
    });

    _socket!.on('lessonDeleted', (data) {
      print('🗑️ Lesson deleted: $data');
      try {
        if (data != null && data['lessonId'] != null) {
          final lessonId = data['lessonId'] as int;
          onLessonDeleted?.call(lessonId);
        }
      } catch (e) {
        print('Error parsing lesson deleted data: $e');
      }
    });
  }

  // Set category event callbacks
  static void setCategoryEventCallbacks({
    Function(Category)? onCreated,
    Function(Category)? onUpdated,
    Function(int)? onDeleted,
  }) {
    onCategoryCreated = onCreated;
    onCategoryUpdated = onUpdated;
    onCategoryDeleted = onDeleted;
  }

  // Set lesson event callbacks
  static void setLessonEventCallbacks({
    Function(Lesson)? onCreated,
    Function(Lesson)? onUpdated,
    Function(int)? onDeleted,
  }) {
    onLessonCreated = onCreated;
    onLessonUpdated = onUpdated;
    onLessonDeleted = onDeleted;
  }

  // Clear all callbacks
  static void clearCallbacks() {
    onCategoryCreated = null;
    onCategoryUpdated = null;
    onCategoryDeleted = null;
    onLessonCreated = null;
    onLessonUpdated = null;
    onLessonDeleted = null;
  }

  // Check connection status
  static bool get isConnected => _isConnected;

  // Dispose socket
  static void dispose() {
    clearCallbacks();
    disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
