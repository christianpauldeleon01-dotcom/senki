import 'package:hive/hive.dart';

part 'activity_model.g.dart';

/// Activity type enum
@HiveType(typeId: 0)
enum ActivityType {
  @HiveField(0)
  running,
  @HiveField(1)
  jogging,
  @HiveField(2)
  walking,
  @HiveField(3)
  cycling,
}

/// Coordinate model for storing GPS points
@HiveType(typeId: 1)
class Coordinate extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double? altitude;

  @HiveField(4)
  final double? speed;

  Coordinate({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.speed,
  });

  /// Convert to list for storage
  List<dynamic> toList() {
    return [
      latitude,
      longitude,
      timestamp.toIso8601String(),
      altitude,
      speed,
    ];
  }

  /// Create from list
  factory Coordinate.fromList(List<dynamic> list) {
    return Coordinate(
      latitude: list[0] as double,
      longitude: list[1] as double,
      timestamp: DateTime.parse(list[2] as String),
      altitude: list[3] as double?,
      speed: list[4] as double?,
    );
  }

  @override
  String toString() {
    return 'Coordinate(lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}

/// Main Activity model for storing workout data
@HiveType(typeId: 2)
class Activity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final double distanceMeters;

  @HiveField(4)
  final double averagePaceSecondsPerKm;

  @HiveField(5)
  final double? averageSpeedMps;

  @HiveField(6)
  final List<Coordinate> routeCoordinates;

  @HiveField(7)
  final ActivityType activityType;

  @HiveField(8)
  final String? photoPath;

  @HiveField(9)
  final double? caloriesBurned;

  @HiveField(10)
  final int? steps;

  @HiveField(11)
  final int? movingTimeSeconds;

  @HiveField(12)
  final double? movingDistanceMeters;

  // New enhanced fields
  @HiveField(13)
  final double? elevationGain;

  @HiveField(14)
  final double? elevationLoss;

  @HiveField(15)
  final double? maxElevation;

  @HiveField(16)
  final double? minElevation;

  @HiveField(17)
  final double? averageGrade;

  @HiveField(18)
  final double? maxSpeedMps;

  @HiveField(19)
  final double? totalAscent;

  @HiveField(20)
  final double? totalDescent;

  @HiveField(21)
  final double? gradeAdjustedPace;

  @HiveField(22)
  final String? mapSnapshotPath;

  @HiveField(23)
  final String? notes;

  @HiveField(24)
  final double? weightKg;

  Activity({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.averagePaceSecondsPerKm,
    this.averageSpeedMps,
    required this.routeCoordinates,
    required this.activityType,
    this.photoPath,
    this.caloriesBurned,
    this.steps,
    this.movingTimeSeconds,
    this.movingDistanceMeters,
    this.elevationGain,
    this.elevationLoss,
    this.maxElevation,
    this.minElevation,
    this.averageGrade,
    this.maxSpeedMps,
    this.totalAscent,
    this.totalDescent,
    this.gradeAdjustedPace,
    this.mapSnapshotPath,
    this.notes,
    this.weightKg,
  });

  /// Get distance in kilometers
  double get distanceKm => distanceMeters / 1000;

  /// Get duration as Duration object
  Duration get duration => Duration(seconds: durationSeconds);

  /// Get formatted duration string (HH:MM:SS)
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted pace (min/km) - Strava-style
  String get formattedPace {
    // Always calculate pace from stored distance and duration
    // This ensures pace is always shown regardless of GPS quality
    if (distanceMeters > 0 && durationSeconds > 0) {
      // Convert distance to km
      final distanceKm = distanceMeters / 1000;
      
      // Pace = Total Time ÷ Total Distance (Strava-style)
      final pace = durationSeconds / distanceKm;
      
      // Check for invalid paces
      if (pace.isInfinite || pace.isNaN || pace <= 0 || pace > 3600) {
        return '--:--';
      }
      
      // Use integer division (~/ ) for Strava-style
      int minutes = pace ~/ 60;
      int seconds = (pace % 60).round();
      
      // Handle case where rounding gives 60 seconds
      if (seconds >= 60) {
        minutes += 1;
        seconds = 0;
      }
      
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    
    // Fall back to stored pace
    if (averagePaceSecondsPerKm == 0 || averagePaceSecondsPerKm.isInfinite || averagePaceSecondsPerKm.isNaN) {
      return '--:--';
    }
    
    // Use integer division (~/ ) for Strava-style
    int minutes = averagePaceSecondsPerKm ~/ 60;
    int seconds = (averagePaceSecondsPerKm % 60).round();
    
    // Handle case where rounding gives 60 seconds
    if (seconds >= 60) {
      minutes += 1;
      seconds = 0;
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get moving duration as Duration object
  Duration? get movingDuration {
    if (movingTimeSeconds == null) return null;
    return Duration(seconds: movingTimeSeconds!);
  }

  /// Get formatted moving duration string (HH:MM:SS)
  String get formattedMovingDuration {
    if (movingTimeSeconds == null || movingTimeSeconds == 0) return '--:--';
    final hours = movingTimeSeconds! ~/ 3600;
    final minutes = (movingTimeSeconds! % 3600) ~/ 60;
    final seconds = movingTimeSeconds! % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get moving distance in km
  double? get movingDistanceKm {
    if (movingDistanceMeters == null) return null;
    return movingDistanceMeters! / 1000;
  }

  /// Get elevation gain in meters
  double get elevationGainMeters => elevationGain ?? 0.0;

  /// Get elevation gain in km
  double get elevationGainKm => elevationGainMeters / 1000;

  /// Get elevation loss in meters
  double get elevationLossMeters => elevationLoss ?? 0.0;

  /// Get elevation loss in km
  double get elevationLossKm => elevationLossMeters / 1000;

  /// Get max elevation in km
  double? get maxElevationKm => maxElevation != null ? maxElevation! / 1000 : null;

  /// Get min elevation in km
  double? get minElevationKm => minElevation != null ? minElevation! / 1000 : null;

  /// Get formatted elevation gain
  String get formattedElevationGain {
    if (elevationGain == null || elevationGain == 0) return '--';
    return '${elevationGain!.toStringAsFixed(0)}m';
  }

  /// Get formatted elevation loss
  String get formattedElevationLoss {
    if (elevationLoss == null || elevationLoss == 0) return '--';
    return '${elevationLoss!.toStringAsFixed(0)}m';
  }

  /// Get formatted calories
  String get formattedCalories {
    if (caloriesBurned == null || caloriesBurned == 0) return '--';
    return '${caloriesBurned!.toStringAsFixed(0)} kcal';
  }

  /// Get formatted steps
  String get formattedSteps {
    if (steps == null || steps == 0) return '--';
    return '${steps!}';
  }

  /// Get max speed in km/h
  double? get maxSpeedKmh => maxSpeedMps != null ? maxSpeedMps! * 3.6 : null;

  /// Get formatted max speed
  String get formattedMaxSpeed {
    if (maxSpeedKmh == null) return '--';
    return '${maxSpeedKmh!.toStringAsFixed(1)} km/h';
  }

  /// Get average speed in km/h
  double get averageSpeedKmh => (averageSpeedMps ?? 0) * 3.6;

  /// Get formatted average speed
  String get formattedAverageSpeed {
    if (averageSpeedKmh == 0) return '--';
    return '${averageSpeedKmh.toStringAsFixed(1)} km/h';
  }

  /// Get activity type as string
  String get activityTypeString {
    switch (activityType) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.jogging:
        return 'Jogging';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.cycling:
        return 'Cycling';
    }
  }

  /// Get activity type emoji
  String get activityTypeEmoji {
    switch (activityType) {
      case ActivityType.running:
        return '🏃';
      case ActivityType.jogging:
        return '🏃‍♂️';
      case ActivityType.walking:
        return '🚶';
      case ActivityType.cycling:
        return '🚴';
    }
  }

  /// Get activity type icon
  String get activityTypeIconName {
    switch (activityType) {
      case ActivityType.running:
        return 'figure.run';
      case ActivityType.jogging:
        return 'figure.jog';
      case ActivityType.walking:
        return 'figure.walk';
      case ActivityType.cycling:
        return 'bicycle';
    }
  }

  /// Create a copy with updated fields
  Activity copyWith({
    String? id,
    DateTime? date,
    int? durationSeconds,
    double? distanceMeters,
    double? averagePaceSecondsPerKm,
    double? averageSpeedMps,
    List<Coordinate>? routeCoordinates,
    ActivityType? activityType,
    String? photoPath,
    double? caloriesBurned,
    int? steps,
    int? movingTimeSeconds,
    double? movingDistanceMeters,
    double? elevationGain,
    double? elevationLoss,
    double? maxElevation,
    double? minElevation,
    double? averageGrade,
    double? maxSpeedMps,
    double? totalAscent,
    double? totalDescent,
    double? gradeAdjustedPace,
    String? mapSnapshotPath,
    String? notes,
    double? weightKg,
  }) {
    return Activity(
      id: id ?? this.id,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm ?? this.averagePaceSecondsPerKm,
      averageSpeedMps: averageSpeedMps ?? this.averageSpeedMps,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      activityType: activityType ?? this.activityType,
      photoPath: photoPath ?? this.photoPath,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      steps: steps ?? this.steps,
      movingTimeSeconds: movingTimeSeconds ?? this.movingTimeSeconds,
      movingDistanceMeters: movingDistanceMeters ?? this.movingDistanceMeters,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      maxElevation: maxElevation ?? this.maxElevation,
      minElevation: minElevation ?? this.minElevation,
      averageGrade: averageGrade ?? this.averageGrade,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      totalAscent: totalAscent ?? this.totalAscent,
      totalDescent: totalDescent ?? this.totalDescent,
      gradeAdjustedPace: gradeAdjustedPace ?? this.gradeAdjustedPace,
      mapSnapshotPath: mapSnapshotPath ?? this.mapSnapshotPath,
      notes: notes ?? this.notes,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  @override
  String toString() {
    return 'Activity(id: $id, type: $activityTypeString, distance: ${distanceKm.toStringAsFixed(2)}km, duration: $formattedDuration)';
  }
}
