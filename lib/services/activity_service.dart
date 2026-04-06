import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../database/database_service.dart';
import 'gps_service.dart';

/// Activity state enum
enum ActivityState {
  idle,
  running,
  paused,
  finished,
}

/// Service for managing activity recording
class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final GPSService _gpsService = GPSService();
  final Uuid _uuid = const Uuid();

  // Activity state
  ActivityState _state = ActivityState.idle;
  ActivityState get state => _state;

  // Current activity data
  Activity? _currentActivity;
  Activity? get currentActivity => _currentActivity;

  // Route coordinates
  final List<Coordinate> _coordinates = [];
  List<Coordinate> get coordinates => List.unmodifiable(_coordinates);

  // Timer for duration tracking
  Timer? _durationTimer;
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  // DateTime when activity started
  DateTime? _startTime;
  DateTime? get startTime => _startTime;

  // Stream controllers
  final StreamController<ActivityState> _stateController =
      StreamController<ActivityState>.broadcast();
  final StreamController<int> _durationController =
      StreamController<int>.broadcast();
  final StreamController<Activity> _activityCompletedController =
      StreamController<Activity>.broadcast();

  // Streams
  Stream<ActivityState> get stateStream => _stateController.stream;
  Stream<int> get durationStream => _durationController.stream;
  Stream<Activity> get activityCompletedStream =>
      _activityCompletedController.stream;

  // Subscription for GPS coordinates
  StreamSubscription<Coordinate>? _coordinateSubscription;

  // Activity type
  ActivityType _activityType = ActivityType.running;
  ActivityType get activityType => _activityType;

  /// Set activity type
  void setActivityType(ActivityType type) {
    _activityType = type;
  }

  /// Start a new activity
  Future<bool> startActivity() async {
    if (_state != ActivityState.idle) return false;

    // Clear previous data
    _coordinates.clear();
    _elapsedSeconds = 0;
    _startTime = DateTime.now();

    // Start GPS tracking
    final started = await _gpsService.startTracking();
    if (!started) {
      return false;
    }

    // Listen to GPS coordinates
    _coordinateSubscription = _gpsService.coordinateStream.listen(
      (coordinate) {
        if (_state == ActivityState.running) {
          _coordinates.add(coordinate);
        }
      },
    );

    // Start duration timer
    _startDurationTimer();

    // Update state
    _state = ActivityState.running;
    _stateController.add(_state);

    return true;
  }

  /// Pause the current activity
  void pauseActivity() {
    if (_state != ActivityState.running) return;

    _gpsService.stopTracking();
    _durationTimer?.cancel();

    _state = ActivityState.paused;
    _stateController.add(_state);
  }

  /// Resume the current activity
  Future<bool> resumeActivity() async {
    if (_state != ActivityState.paused) return false;

    // Resume GPS tracking
    final started = await _gpsService.startTracking();
    if (!started) {
      return false;
    }

    // Restart duration timer
    _startDurationTimer();

    _state = ActivityState.running;
    _stateController.add(_state);

    return true;
  }

  /// Stop and save the current activity
  Future<Activity?> stopActivity({
    String? photoPath,
    double weightKg = 70.0,
    String? notes,
    String? mapSnapshotPath,
  }) async {
    if (_state != ActivityState.running && _state != ActivityState.paused) {
      return null;
    }

    // Stop GPS tracking
    _gpsService.stopTracking();
    _durationTimer?.cancel();
    _coordinateSubscription?.cancel();

    // Calculate basic stats
    final distance = GPSService.calculateTotalDistance(_coordinates);
    final pace = GPSService.calculatePace(_coordinates);
    final avgSpeed = GPSService.calculateAverageSpeed(_coordinates);
    final movingDistance = GPSService.calculateMovingDistance(_coordinates);
    final movingTime = GPSService.calculateMovingTime(_coordinates);
    
    // Calculate enhanced stats
    final elevationGain = GPSService.calculateElevationGain(_coordinates);
    final elevationLoss = GPSService.calculateElevationLoss(_coordinates);
    final maxElevation = GPSService.calculateMaxElevation(_coordinates);
    final minElevation = GPSService.calculateMinElevation(_coordinates);
    final calories = GPSService.calculateCalories(
      coordinates: _coordinates,
      activityType: _activityType,
      weightKg: weightKg,
    );
    final steps = GPSService.estimateSteps(_coordinates);
    
    // Calculate max speed
    double maxSpeed = 0;
    for (int i = 1; i < _coordinates.length; i++) {
      final speed = GPSService.calculateSpeed(_coordinates[i - 1], _coordinates[i]);
      if (speed > maxSpeed) {
        maxSpeed = speed;
      }
    }

    // Create activity object with enhanced data
    final activity = Activity(
      id: _uuid.v4(),
      date: _startTime ?? DateTime.now(),
      durationSeconds: _elapsedSeconds,
      distanceMeters: distance,
      averagePaceSecondsPerKm: pace,
      averageSpeedMps: avgSpeed,
      routeCoordinates: List.from(_coordinates),
      activityType: _activityType,
      photoPath: photoPath,
      caloriesBurned: calories,
      steps: steps,
      movingTimeSeconds: movingTime,
      movingDistanceMeters: movingDistance,
      elevationGain: elevationGain,
      elevationLoss: elevationLoss,
      maxElevation: maxElevation,
      minElevation: minElevation,
      maxSpeedMps: maxSpeed,
      notes: notes,
      mapSnapshotPath: mapSnapshotPath,
      weightKg: weightKg,
    );

    // Save to database
    await DatabaseService.saveActivity(activity);

    // Emit completed activity
    _activityCompletedController.add(activity);

    // Reset state
    _reset();

    return activity;
  }

  /// Discard current activity without saving
  void discardActivity() {
    _gpsService.stopTracking();
    _durationTimer?.cancel();
    _coordinateSubscription?.cancel();
    _reset();
  }

  /// Get current distance in meters
  double get currentDistance {
    return GPSService.calculateTotalDistance(_coordinates);
  }

  /// Get current distance in kilometers
  double get currentDistanceKm => currentDistance / 1000;

  /// Get current pace in seconds per km (Strava-style)
  double get currentPace {
    // Use total duration and total distance (Strava-style)
    if (_coordinates.isEmpty) return 0.0;
    
    final totalDistance = GPSService.calculateTotalDistance(_coordinates);
    if (totalDistance <= 0) return 0.0;
    
    // Use elapsed time from the timer
    if (_elapsedSeconds <= 0) return 0.0;
    
    // Convert to km
    final distanceKm = totalDistance / 1000;
    
    // Pace = Total Time ÷ Total Distance (Strava-style)
    return _elapsedSeconds / distanceKm;
  }

  /// Get formatted current pace
  String get formattedCurrentPace {
    // Check for invalid values
    if (currentPace <= 0 || currentPace.isInfinite || currentPace.isNaN) {
      return '--:--';
    }
    
    // Ignore unreasonably slow paces (> 1 hour per km)
    if (currentPace > 3600) {
      return '--:--';
    }
    
    // Use integer division (~/ ) for Strava-style
    int minutes = currentPace ~/ 60;
    int seconds = (currentPace % 60).round();
    
    // Handle case where rounding gives 60 seconds
    if (seconds >= 60) {
      minutes += 1;
      seconds = 0;
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get current speed in m/s (Strava-style using moving time)
  double get currentSpeed {
    return GPSService.calculateMovingAverageSpeed(_coordinates);
  }

  /// Get formatted duration
  String get formattedDuration {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Start duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _durationController.add(_elapsedSeconds);
    });
  }

  /// Reset to idle state
  void _reset() {
    _state = ActivityState.idle;
    _currentActivity = null;
    _coordinates.clear();
    _elapsedSeconds = 0;
    _startTime = null;
    _stateController.add(_state);
  }

  /// Get all saved activities
  List<Activity> getAllActivities() {
    return DatabaseService.getAllActivities();
  }

  /// Get activity by ID
  Activity? getActivity(String id) {
    return DatabaseService.getActivity(id);
  }

  /// Delete an activity
  Future<void> deleteActivity(String id) async {
    await DatabaseService.deleteActivity(id);
  }

  /// Get recent activities (last 7 days)
  List<Activity> getRecentActivities() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return DatabaseService.getActivitiesInRange(weekAgo, now);
  }

  /// Get weekly stats
  Map<String, dynamic> getWeeklyStats() {
    final activities = getRecentActivities();
    final totalDistance = activities.fold<double>(
      0,
      (sum, a) => sum + a.distanceMeters,
    );
    final totalDuration = activities.fold<int>(
      0,
      (sum, a) => sum + a.durationSeconds,
    );
    final totalActivities = activities.length;

    return {
      'totalDistance': totalDistance,
      'totalDistanceKm': totalDistance / 1000,
      'totalDuration': totalDuration,
      'totalActivities': totalActivities,
    };
  }

  /// Dispose resources
  void dispose() {
    _durationTimer?.cancel();
    _coordinateSubscription?.cancel();
    _stateController.close();
    _durationController.close();
    _activityCompletedController.close();
  }
}
