import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';

class ErrorHandler {
  ErrorHandler._();

  /// Converts any error into a user-friendly message.
  static String toUserMessage(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('socketexception') ||
        msg.contains('network') ||
        msg.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('unauthorized') || msg.contains('403') || msg.contains('401')) {
      return 'Authentication error. Please restart the app.';
    }
    if (msg.contains('404')) {
      return 'Information not found. Try a different search.';
    }
    if (msg.contains('429') || msg.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (msg.contains('500') || msg.contains('server')) {
      return 'Server error. Please try again in a few minutes.';
    }
    if (msg.contains('format') || msg.contains('parse') || msg.contains('json')) {
      return 'Unexpected response format. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Records error to Crashlytics and prints to debug console.
  static Future<void> record(dynamic error, [StackTrace? stack]) async {
    debugPrint('ERROR: $error');
    if (stack != null) debugPrint('STACK: $stack');
    await FirebaseService.instance.recordError(error, stack);
  }

  /// Whether the error is a network connectivity issue.
  static bool isNetworkError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout');
  }
}
