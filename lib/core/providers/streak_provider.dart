import 'package:flutter/foundation.dart';
import '../models/streak_data.dart';
import '../services/firebase_service.dart';
import '../services/streak_service.dart';

class StreakProvider extends ChangeNotifier {
  StreakData _streak = const StreakData();
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingLeaderboard = false;
  bool _freezeSuccess = false;

  StreakData get streak            => _streak;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isLoadingLeaderboard   => _isLoadingLeaderboard;
  bool get freezeSuccess          => _freezeSuccess;

  Future<void> initialize() async {
    await StreakService.instance.initialize();
    _streak = StreakService.instance.current;

    // Record daily open
    _streak = await StreakService.instance.recordDailyOpen();
    notifyListeners();
  }

  Future<void> loadLeaderboard() async {
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      _leaderboard = await FirebaseService.instance.getLeaderboard(limit: 20);
    } catch (_) {
      _leaderboard = [];
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<void> freezeStreak() async {
    final success = await StreakService.instance.freezeStreak();
    _freezeSuccess = success;
    if (success) {
      _streak = StreakService.instance.current;
    }
    notifyListeners();

    // Reset flag after short delay
    await Future<void>.delayed(const Duration(seconds: 2));
    _freezeSuccess = false;
    notifyListeners();
  }

  void refresh() {
    _streak = StreakService.instance.current;
    notifyListeners();
  }
}
