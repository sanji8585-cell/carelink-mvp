import 'package:flutter/foundation.dart';
import 'api_service.dart';

class HealthService extends ChangeNotifier {
  final ApiService _api;
  int _todaySteps = 0;
  double? _lastSleepHours;
  Map<String, dynamic>? _todayData;
  Map<String, dynamic>? _weeklyData;
  Map<String, dynamic>? _dashboard;

  HealthService(this._api);

  int get todaySteps => _todaySteps;
  double? get lastSleepHours => _lastSleepHours;
  Map<String, dynamic>? get todayData => _todayData;
  Map<String, dynamic>? get weeklyData => _weeklyData;
  Map<String, dynamic>? get dashboard => _dashboard;

  void updateSteps(int steps) {
    _todaySteps = steps;
    notifyListeners();
  }

  Future<void> submitDailyData(String seniorId) async {
    try {
      await _api.submitDeviceData({
        'seniorId': seniorId,
        'steps': _todaySteps,
        'sleepHours': _lastSleepHours,
      });
    } catch (e) {
      debugPrint('Failed to submit health data: $e');
    }
  }

  Future<void> loadTodayData(String seniorId) async {
    try {
      _todayData = await _api.getTodayHealth(seniorId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load today data: $e');
    }
  }

  Future<void> loadWeeklyData(String seniorId) async {
    try {
      _weeklyData = await _api.getWeeklyHealth(seniorId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load weekly data: $e');
    }
  }

  Future<void> loadDashboard(String seniorId) async {
    try {
      _dashboard = await _api.getDashboard(seniorId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load dashboard: $e');
    }
  }
}
