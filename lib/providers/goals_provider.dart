import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalsProvider extends ChangeNotifier {
  static const _kDailySteps = 'goal_daily_steps';
  static const _kTargetWeight = 'goal_target_weight';
  static const _kDailyCalories = 'goal_daily_calories';
  static const _kDailyProtein = 'goal_daily_protein';
  static const _kDailyFat = 'goal_daily_fat';
  static const _kDailyCarbs = 'goal_daily_carbs';
  static const _kSleepHours = 'goal_sleep_hours';
  static const _kWeeklyActivityMins = 'goal_weekly_activity_mins';

  int _dailySteps = 10000;
  double _targetWeight = 75.0;
  double _dailyCalories = 2000;
  double _dailyProtein = 150;
  double _dailyFat = 65;
  double _dailyCarbs = 250;
  double _sleepHours = 8.0;
  int _weeklyActivityMins = 150;

  int get dailySteps => _dailySteps;
  double get targetWeight => _targetWeight;
  double get dailyCalories => _dailyCalories;
  double get dailyProtein => _dailyProtein;
  double get dailyFat => _dailyFat;
  double get dailyCarbs => _dailyCarbs;
  double get sleepHours => _sleepHours;
  int get weeklyActivityMins => _weeklyActivityMins;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dailySteps = prefs.getInt(_kDailySteps) ?? 10000;
    _targetWeight = prefs.getDouble(_kTargetWeight) ?? 75.0;
    _dailyCalories = prefs.getDouble(_kDailyCalories) ?? 2000;
    _dailyProtein = prefs.getDouble(_kDailyProtein) ?? 150;
    _dailyFat = prefs.getDouble(_kDailyFat) ?? 65;
    _dailyCarbs = prefs.getDouble(_kDailyCarbs) ?? 250;
    _sleepHours = prefs.getDouble(_kSleepHours) ?? 8.0;
    _weeklyActivityMins = prefs.getInt(_kWeeklyActivityMins) ?? 150;
    notifyListeners();
  }

  Future<void> setDailySteps(int v) async {
    _dailySteps = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDailySteps, v);
  }

  Future<void> setTargetWeight(double v) async {
    _targetWeight = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTargetWeight, v);
  }

  Future<void> setDailyCalories(double v) async {
    _dailyCalories = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyCalories, v);
  }

  Future<void> setDailyProtein(double v) async {
    _dailyProtein = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyProtein, v);
  }

  Future<void> setDailyFat(double v) async {
    _dailyFat = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyFat, v);
  }

  Future<void> setDailyCarbs(double v) async {
    _dailyCarbs = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kDailyCarbs, v);
  }

  Future<void> setSleepHours(double v) async {
    _sleepHours = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSleepHours, v);
  }

  Future<void> setWeeklyActivityMins(int v) async {
    _weeklyActivityMins = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeeklyActivityMins, v);
  }
}
