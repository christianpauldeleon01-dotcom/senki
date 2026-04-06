import 'package:intl/intl.dart';

/// Utility functions for the app
class AppUtils {
  /// Format distance in meters to km string
  static String formatDistanceKm(double meters) {
    final km = meters / 1000;
    return km.toStringAsFixed(2);
  }

  /// Format distance with unit
  static String formatDistanceWithUnit(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${formatDistanceKm(meters)} km';
  }

  /// Format duration in seconds to HH:MM:SS or MM:SS
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format pace (seconds per km) to MM:SS/km (Strava-style)
  static String formatPace(double secondsPerKm) {
    // Check for invalid values
    if (secondsPerKm <= 0 || secondsPerKm.isInfinite || secondsPerKm.isNaN) {
      return '--:--';
    }
    
    // Ignore very small distances - Strava shows -- for < 50m
    if (secondsPerKm > 3600) { // More than 1 hour per km = very slow
      return '--:--';
    }
    
    // Use integer division (~/ ) for Strava-style calculation
    int minutes = secondsPerKm ~/ 60;
    int seconds = (secondsPerKm % 60).round();
    
    // Handle case where rounding gives 60 seconds
    if (seconds >= 60) {
      minutes += 1;
      seconds = 0;
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calculate pace from distance and duration (Strava-style)
  /// Distance in meters, duration in seconds
  static String calculateStravaPace(double distanceMeters, int durationSeconds) {
    // Ignore very small distances (< 50m) - Strava shows -- for these
    if (distanceMeters < 50 || distanceMeters <= 0) {
      return '--:--';
    }
    
    // If duration is 0, return --:--
    if (durationSeconds <= 0) {
      return '--:--';
    }
    
    // Convert distance to km
    double distanceKm = distanceMeters / 1000;
    
    // Pace = Total Time ÷ Total Distance (Strava-style)
    double paceSecondsPerKm = durationSeconds / distanceKm;
    
    // Check for invalid paces
    if (paceSecondsPerKm.isInfinite || paceSecondsPerKm.isNaN || paceSecondsPerKm <= 0 || paceSecondsPerKm > 3600) {
      return '--:--';
    }
    
    // Use integer division (~/ ) for Strava-style
    int minutes = paceSecondsPerKm ~/ 60;
    int seconds = (paceSecondsPerKm % 60).round();
    
    // Handle case where rounding gives 60 seconds
    if (seconds >= 60) {
      minutes += 1;
      seconds = 0;
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format pace with unit
  static String formatPaceWithUnit(double secondsPerKm) {
    return '${formatPace(secondsPerKm)}/km';
  }

  /// Format speed (m/s) to km/h
  static String formatSpeedKmh(double metersPerSecond) {
    final kmh = metersPerSecond * 3.6;
    return kmh.toStringAsFixed(1);
  }

  /// Format speed with unit
  static String formatSpeedWithUnit(double metersPerSecond) {
    return '${formatSpeedKmh(metersPerSecond)} km/h';
  }

  /// Format date to readable string
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  /// Format date for activity summary
  static String formatActivityDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// Format time only
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Calculate calories burned (rough estimate)
  /// Based on MET values - running ~10 METs
  static double calculateCalories({
    required double distanceMeters,
    required int durationSeconds,
    double weightKg = 70, // Default weight
  }) {
    // Running MET is approximately 9.8
    // Calories = MET × weight (kg) × time (hours)
    final hours = durationSeconds / 3600;
    final met = 9.8; // Running MET
    return met * weightKg * hours;
  }

  /// Get activity icon name
  static String getActivityIcon(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return '🏃';
      case 'jogging':
        return '🏃‍♂️';
      case 'walking':
        return '🚶';
      case 'cycling':
        return '🚴';
      default:
        return '🏃';
    }
  }

  /// Format number with commas
  static String formatNumber(num number) {
    return NumberFormat('#,##0').format(number);
  }

  /// Get week day name
  static String getWeekDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  /// Get short week day name
  static String getShortWeekDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
