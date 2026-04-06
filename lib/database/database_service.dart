import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity_model.dart';
import '../models/user_profile_model.dart';

/// Database service for managing Hive local storage
class DatabaseService {
  static const String _activityBoxName = 'activities';
  static const String _userProfileBoxName = 'userProfile';
  static const String _settingsBoxName = 'settings';
  static Box<Activity>? _activityBox;
  static Box<UserProfile>? _userProfileBox;
  static Box? _settingsBox;

  /// Initialize Hive database
  static Future<void> init() async {
    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ActivityTypeAdapter());
    Hive.registerAdapter(CoordinateAdapter());
    Hive.registerAdapter(ActivityAdapter());
    Hive.registerAdapter(UserProfileAdapter());

    // Open boxes
    _activityBox = await Hive.openBox<Activity>(_activityBoxName);
    _userProfileBox = await Hive.openBox<UserProfile>(_userProfileBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  /// Get activities box
  static Box<Activity> get activitiesBox {
    if (_activityBox == null) {
      throw Exception('Database not initialized. Call DatabaseService.init() first.');
    }
    return _activityBox!;
  }

  /// Get user profile box
  static Box<UserProfile> get userProfileBox {
    if (_userProfileBox == null) {
      throw Exception('Database not initialized. Call DatabaseService.init() first.');
    }
    return _userProfileBox!;
  }

  /// Get settings box
  static Box get settingsBox {
    if (_settingsBox == null) {
      throw Exception('Database not initialized. Call DatabaseService.init() first.');
    }
    return _settingsBox!;
  }

  // ============ USER PROFILE ============

  /// Save user profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    await userProfileBox.put('profile', profile);
  }

  /// Get user profile (returns default if not set)
  static UserProfile getUserProfile() {
    final profile = userProfileBox.get('profile');
    return profile ?? UserProfile.defaultProfile();
  }

  // ============ ACTIVITIES ============

  /// Save a new activity
  static Future<void> saveActivity(Activity activity) async {
    await activitiesBox.put(activity.id, activity);
  }

  /// Get all activities sorted by date (newest first)
  static List<Activity> getAllActivities() {
    final activities = activitiesBox.values.toList();
    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities;
  }

  /// Get activity by ID
  static Activity? getActivity(String id) {
    return activitiesBox.get(id);
  }

  /// Update an activity
  static Future<void> updateActivity(Activity activity) async {
    await activitiesBox.put(activity.id, activity);
  }

  /// Delete an activity
  static Future<void> deleteActivity(String id) async {
    await activitiesBox.delete(id);
  }

  /// Get total activities count
  static int getActivitiesCount() {
    return activitiesBox.length;
  }

  /// Get total distance in meters
  static double getTotalDistance() {
    return activitiesBox.values
        .fold(0.0, (sum, activity) => sum + activity.distanceMeters);
  }

  /// Get total duration in seconds
  static int getTotalDuration() {
    return activitiesBox.values
        .fold(0, (sum, activity) => sum + activity.durationSeconds);
  }

  /// Get activities for a specific date range
  static List<Activity> getActivitiesInRange(DateTime start, DateTime end) {
    return activitiesBox.values
        .where((activity) =>
            activity.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            activity.date.isBefore(end.add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ============ ENHANCED QUERIES ============

  /// Get activities by type
  static List<Activity> getActivitiesByType(ActivityType type) {
    return activitiesBox.values
        .where((activity) => activity.activityType == type)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get activities for today
  static List<Activity> getTodayActivities() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getActivitiesInRange(startOfDay, endOfDay);
  }

  /// Get activities for this week
  static List<Activity> getWeekActivities() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return getActivitiesInRange(start, now);
  }

  /// Get activities for this month
  static List<Activity> getMonthActivities() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return getActivitiesInRange(start, now);
  }

  /// Get activities by year
  static List<Activity> getYearActivities(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    return getActivitiesInRange(start, end);
  }

  // ============ STATISTICS ============

  /// Get comprehensive statistics
  static Map<String, dynamic> getStatistics() {
    final activities = getAllActivities();
    
    if (activities.isEmpty) {
      return {
        'totalActivities': 0,
        'totalDistance': 0.0,
        'totalDistanceKm': 0.0,
        'totalDuration': 0,
        'totalDurationFormatted': '00:00:00',
        'totalCalories': 0.0,
        'totalSteps': 0,
        'totalElevationGain': 0.0,
        'averageDistance': 0.0,
        'averageDuration': 0,
        'averagePace': 0.0,
        'longestActivity': null,
        'fastestPace': 0.0,
        'activitiesByType': <ActivityType, int>{},
      };
    }

    final totalDistance = activities.fold<double>(0, (sum, a) => sum + a.distanceMeters);
    final totalDuration = activities.fold<int>(0, (sum, a) => sum + a.durationSeconds);
    final totalCalories = activities.fold<double>(0, (sum, a) => sum + (a.caloriesBurned ?? 0));
    final totalSteps = activities.fold<int>(0, (sum, a) => sum + (a.steps ?? 0));
    final totalElevationGain = activities.fold<double>(0, (sum, a) => sum + (a.elevationGain ?? 0));

    // Activities by type
    final activitiesByType = <ActivityType, int>{};
    for (final activity in activities) {
      activitiesByType[activity.activityType] = 
          (activitiesByType[activity.activityType] ?? 0) + 1;
    }

    // Find longest activity
    Activity? longest;
    for (final activity in activities) {
      if (longest == null || activity.distanceMeters > longest.distanceMeters) {
        longest = activity;
      }
    }

    // Find fastest pace
    double fastestPace = double.infinity;
    for (final activity in activities) {
      if (activity.averagePaceSecondsPerKm > 0 && 
          activity.averagePaceSecondsPerKm < fastestPace) {
        fastestPace = activity.averagePaceSecondsPerKm;
      }
    }
    if (fastestPace == double.infinity) fastestPace = 0;

    return {
      'totalActivities': activities.length,
      'totalDistance': totalDistance,
      'totalDistanceKm': totalDistance / 1000,
      'totalDuration': totalDuration,
      'totalDurationFormatted': _formatDuration(totalDuration),
      'totalCalories': totalCalories,
      'totalSteps': totalSteps,
      'totalElevationGain': totalElevationGain,
      'averageDistance': activities.isNotEmpty ? totalDistance / activities.length : 0,
      'averageDuration': activities.isNotEmpty ? totalDuration ~/ activities.length : 0,
      'averagePace': activities.isNotEmpty && totalDistance > 0 
          ? totalDuration / (totalDistance / 1000) 
          : 0,
      'longestActivity': longest,
      'fastestPace': fastestPace,
      'activitiesByType': activitiesByType,
    };
  }

  /// Get weekly statistics
  static Map<String, dynamic> getWeeklyStats() {
    final activities = getWeekActivities();
    
    final totalDistance = activities.fold<double>(0, (sum, a) => sum + a.distanceMeters);
    final totalDuration = activities.fold<int>(0, (sum, a) => sum + a.durationSeconds);
    final totalCalories = activities.fold<double>(0, (sum, a) => sum + (a.caloriesBurned ?? 0));
    final totalElevation = activities.fold<double>(0, (sum, a) => sum + (a.elevationGain ?? 0));

    return {
      'activities': activities,
      'activityCount': activities.length,
      'totalDistance': totalDistance,
      'totalDistanceKm': totalDistance / 1000,
      'totalDuration': totalDuration,
      'totalDurationFormatted': _formatDuration(totalDuration),
      'totalCalories': totalCalories,
      'totalElevation': totalElevation,
      'averageDistance': activities.isNotEmpty ? totalDistance / activities.length : 0,
      'averageDuration': activities.isNotEmpty ? totalDuration ~/ activities.length : 0,
    };
  }

  /// Get monthly statistics
  static Map<String, dynamic> getMonthlyStats() {
    final activities = getMonthActivities();
    
    final totalDistance = activities.fold<double>(0, (sum, a) => sum + a.distanceMeters);
    final totalDuration = activities.fold<int>(0, (sum, a) => sum + a.durationSeconds);
    final totalCalories = activities.fold<double>(0, (sum, a) => sum + (a.caloriesBurned ?? 0));

    return {
      'activities': activities,
      'activityCount': activities.length,
      'totalDistance': totalDistance,
      'totalDistanceKm': totalDistance / 1000,
      'totalDuration': totalDuration,
      'totalDurationFormatted': _formatDuration(totalDuration),
      'totalCalories': totalCalories,
    };
  }

  // ============ SETTINGS ============

  /// Save a setting
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  /// Get a setting
  static T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Delete a setting
  static Future<void> deleteSetting(String key) async {
    await settingsBox.delete(key);
  }

  // ============ UTILITY ============

  /// Export all data as JSON string
  static Future<String> exportData() async {
    final activities = getAllActivities();
    final profile = getUserProfile();
    
    // Convert to JSON-friendly format
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'userProfile': {
        'name': profile.name,
        'weight': profile.weight,
        'height': profile.height,
      },
      'activities': activities.map((a) => {
        'id': a.id,
        'date': a.date.toIso8601String(),
        'durationSeconds': a.durationSeconds,
        'distanceMeters': a.distanceMeters,
        'activityType': a.activityType.name,
        'caloriesBurned': a.caloriesBurned,
        'steps': a.steps,
        'elevationGain': a.elevationGain,
      }).toList(),
    };
    
    return data.toString();
  }

  /// Get streak (consecutive days with activities)
  static int getCurrentStreak() {
    final activities = getAllActivities();
    if (activities.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    // Normalize to start of day
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
    
    while (true) {
      final dayActivities = activities.where((a) {
        final activityDate = DateTime(a.date.year, a.date.month, a.date.day);
        return activityDate.isAtSameMomentAs(checkDate);
      });
      
      if (dayActivities.isNotEmpty) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (streak == 0) {
        // Check yesterday if no activity today yet
        checkDate = checkDate.subtract(const Duration(days: 1));
        final yesterdayActivities = activities.where((a) {
          final activityDate = DateTime(a.date.year, a.date.month, a.date.day);
          return activityDate.isAtSameMomentAs(checkDate);
        });
        if (yesterdayActivities.isEmpty) {
          break;
        }
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Get personal bests
  static Map<String, dynamic> getPersonalBests() {
    final activities = getAllActivities();
    if (activities.isEmpty) return {};

    // Longest distance
    double longestDistance = 0;
    Activity? longestDistanceActivity;
    
    // Fastest pace
    double fastestPace = double.infinity;
    Activity? fastestPaceActivity;
    
    // Longest duration
    int longestDuration = 0;
    Activity? longestDurationActivity;
    
    // Highest elevation
    double highestElevation = 0;
    Activity? highestElevationActivity;

    for (final activity in activities) {
      if (activity.distanceMeters > longestDistance) {
        longestDistance = activity.distanceMeters;
        longestDistanceActivity = activity;
      }
      
      if (activity.averagePaceSecondsPerKm > 0 && 
          activity.averagePaceSecondsPerKm < fastestPace) {
        fastestPace = activity.averagePaceSecondsPerKm;
        fastestPaceActivity = activity;
      }
      
      if (activity.durationSeconds > longestDuration) {
        longestDuration = activity.durationSeconds;
        longestDurationActivity = activity;
      }
      
      if ((activity.elevationGain ?? 0) > highestElevation) {
        highestElevation = activity.elevationGain ?? 0;
        highestElevationActivity = activity;
      }
    }

    return {
      'longestDistance': longestDistance,
      'longestDistanceActivity': longestDistanceActivity,
      'fastestPace': fastestPace == double.infinity ? 0 : fastestPace,
      'fastestPaceActivity': fastestPaceActivity,
      'longestDuration': longestDuration,
      'longestDurationActivity': longestDurationActivity,
      'highestElevation': highestElevation,
      'highestElevationActivity': highestElevationActivity,
    };
  }

  /// Format duration helper
  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Clear all activities (use with caution)
  static Future<void> clearAllActivities() async {
    await activitiesBox.clear();
  }

  /// Close database
  static Future<void> close() async {
    await _activityBox?.close();
    await _userProfileBox?.close();
    await _settingsBox?.close();
  }
}
