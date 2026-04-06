import 'dart:math';
import '../models/activity_model.dart';

/// Kalman filter for GPS smoothing
/// Provides high-accuracy position estimation by filtering out GPS noise
class KalmanFilter {
  // Process noise (how much we expect the position to change between updates)
  final double processNoise;
  
  // Measurement noise (how noisy are the GPS readings)
  final double measurementNoise;
  
  // Current estimated position
  double _estimatedLat = 0;
  double _estimatedLng = 0;
  
  // Current estimate error covariance
  double _estimateError = 1;
  
  // Whether filter has been initialized
  bool _isInitialized = false;
  
  KalmanFilter({
    this.processNoise = 0.00001,
    this.measurementNoise = 0.000001,
  });
  
  /// Process a new GPS reading and return filtered coordinate
  Coordinate filter(Coordinate raw) {
    if (!_isInitialized) {
      _estimatedLat = raw.latitude;
      _estimatedLng = raw.longitude;
      _estimateError = 1;
      _isInitialized = true;
      return raw;
    }
    
    // Prediction step
    // We assume the object continues at roughly the same position (simple model)
    final predictedLat = _estimatedLat;
    final predictedLng = _estimatedLng;
    final predictedError = _estimateError + processNoise;
    
    // Kalman gain
    // K = P / (P + R) where P is predicted error, R is measurement noise
    final kalmanGain = predictedError / (predictedError + measurementNoise);
    
    // Update step
    _estimatedLat = predictedLat + kalmanGain * (raw.latitude - predictedLat);
    _estimatedLng = predictedLng + kalmanGain * (raw.longitude - predictedLng);
    
    // Update error covariance
    _estimateError = (1 - kalmanGain) * predictedError;
    
    return Coordinate(
      latitude: _estimatedLat,
      longitude: _estimatedLng,
      timestamp: raw.timestamp,
      altitude: raw.altitude,
      speed: raw.speed,
    );
  }
  
  /// Reset the filter
  void reset() {
    _isInitialized = false;
    _estimatedLat = 0;
    _estimatedLng = 0;
    _estimateError = 1;
  }
  
  /// Check if filter is initialized
  bool get isInitialized => _isInitialized;
}

/// Moving average filter for smoothing coordinates
class MovingAverageFilter {
  final int windowSize;
  final List<Coordinate> _buffer = [];
  
  MovingAverageFilter({this.windowSize = 5});
  
  /// Add a coordinate and get smoothed result
  Coordinate? filter(Coordinate coord) {
    _buffer.add(coord);
    
    if (_buffer.length < windowSize) {
      return null; // Not enough data yet
    }
    
    if (_buffer.length > windowSize) {
      _buffer.removeAt(0);
    }
    
    // Calculate average
    double sumLat = 0;
    double sumLng = 0;
    
    for (final c in _buffer) {
      sumLat += c.latitude;
      sumLng += c.longitude;
    }
    
    return Coordinate(
      latitude: sumLat / _buffer.length,
      longitude: sumLng / _buffer.length,
      timestamp: coord.timestamp,
      altitude: coord.altitude,
      speed: coord.speed,
    );
  }
  
  /// Reset the filter
  void reset() {
    _buffer.clear();
  }
  
  /// Get buffer size
  int get bufferSize => _buffer.length;
}

/// GPS jump detector to filter out unrealistic GPS jumps
class GPSJumpDetector {
  /// Maximum realistic speed in m/s (8 m/s ≈ 28.8 km/h for running)
  static const double maxRealisticSpeed = 8.0;
  
  /// Minimum distance to consider (meters)
  static const double minDistanceThreshold = 2.0;
  
  /// Maximum time gap to consider (seconds)
  static const int maxTimeGap = 30;
  
  /// Previous coordinate
  Coordinate? _previousCoord;
  
  /// Check if new coordinate is a valid jump
  bool isValidJump(Coordinate from, Coordinate to) {
    final distance = _calculateDistance(from, to);
    final timeDiff = to.timestamp.difference(from.timestamp).inSeconds;
    
    // If time gap is too large, reset the detector
    if (timeDiff > maxTimeGap) {
      return true; // Consider it valid but reset
    }
    
    // If distance is too small, it's likely GPS noise
    if (distance < minDistanceThreshold) {
      return false;
    }
    
    // Calculate speed
    final speed = distance / timeDiff;
    
    // If speed is unrealistic, it's a GPS jump
    if (speed > maxRealisticSpeed) {
      return false;
    }
    
    return true;
  }
  
  /// Update previous coordinate
  void update(Coordinate coord) {
    _previousCoord = coord;
  }
  
  /// Get previous coordinate
  Coordinate? get previousCoord => _previousCoord;
  
  /// Reset detector
  void reset() {
    _previousCoord = null;
  }
  
  /// Calculate distance between two coordinates using Haversine
  static double _calculateDistance(Coordinate from, Coordinate to) {
    const earthRadius = 6371000.0; // meters
    final lat1Rad = from.latitude * pi / 180;
    final lat2Rad = to.latitude * pi / 180;
    final deltaLat = (to.latitude - from.latitude) * pi / 180;
    final deltaLng = (to.longitude - from.longitude) * pi / 180;
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLng / 2) * sin(deltaLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}

/// Speed filter to smooth out speed values
class SpeedFilter {
  final List<double> _speedBuffer = [];
  final int windowSize;
  
  SpeedFilter({this.windowSize = 5});
  
  /// Filter speed value
  double filter(double speed) {
    // Clamp unrealistic speeds
    if (speed > GPSJumpDetector.maxRealisticSpeed || speed < 0) {
      speed = 0;
    }
    
    _speedBuffer.add(speed);
    
    if (_speedBuffer.length > windowSize) {
      _speedBuffer.removeAt(0);
    }
    
    // Calculate median (more robust than average)
    final sorted = List<double>.from(_speedBuffer)..sort();
    final mid = sorted.length ~/ 2;
    
    if (sorted.length.isOdd) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
  }
  
  /// Reset filter
  void reset() {
    _speedBuffer.clear();
  }
}

/// Combined location filter that applies all filters
class LocationFilterService {
  final KalmanFilter _kalmanFilter = KalmanFilter();
  final MovingAverageFilter _movingAverageFilter = MovingAverageFilter(windowSize: 3);
  final GPSJumpDetector _jumpDetector = GPSJumpDetector();
  final SpeedFilter _speedFilter = SpeedFilter();
  
  /// Filtered coordinates queue
  final List<Coordinate> _filteredCoordinates = [];
  
  /// Maximum number of coordinates to keep
  static const int maxCoordinates = 1000;
  
  /// Process a raw GPS coordinate and return filtered result
  /// Returns null if the coordinate should be ignored (GPS jump)
  Coordinate? processCoordinate(Coordinate raw) {
    // First, apply Kalman filter
    final kalmanFiltered = _kalmanFilter.filter(raw);
    
    // Check for GPS jumps
    if (_jumpDetector.previousCoord != null) {
      if (!_jumpDetector.isValidJump(_jumpDetector.previousCoord!, kalmanFiltered)) {
        // This is a GPS jump - ignore it
        return null;
      }
    }
    _jumpDetector.update(kalmanFiltered);
    
    // Apply moving average filter
    final smoothed = _movingAverageFilter.filter(kalmanFiltered);
    
    // If we don't have enough data for moving average, use Kalman result
    final result = smoothed ?? kalmanFiltered;
    
    // Filter speed
    final filteredSpeed = _speedFilter.filter(raw.speed ?? 0);
    
    // Create filtered coordinate
    final filteredCoord = Coordinate(
      latitude: result.latitude,
      longitude: result.longitude,
      timestamp: result.timestamp,
      altitude: result.altitude,
      speed: filteredSpeed,
    );
    
    // Add to filtered coordinates list
    _filteredCoordinates.add(filteredCoord);
    if (_filteredCoordinates.length > maxCoordinates) {
      _filteredCoordinates.removeAt(0);
    }
    
    return filteredCoord;
  }
  
  /// Get filtered coordinates
  List<Coordinate> get filteredCoordinates => List.unmodifiable(_filteredCoordinates);
  
  /// Get last filtered coordinate
  Coordinate? get lastFilteredCoordinate => 
      _filteredCoordinates.isNotEmpty ? _filteredCoordinates.last : null;
  
  /// Calculate filtered distance
  double calculateFilteredDistance() {
    if (_filteredCoordinates.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 1; i < _filteredCoordinates.length; i++) {
      totalDistance += _calculateHaversineDistance(
        _filteredCoordinates[i - 1],
        _filteredCoordinates[i],
      );
    }
    return totalDistance;
  }
  
  /// Calculate distance using Haversine formula
  static double _calculateHaversineDistance(Coordinate from, Coordinate to) {
    const earthRadius = 6371000.0; // meters
    final lat1Rad = from.latitude * pi / 180;
    final lat2Rad = to.latitude * pi / 180;
    final deltaLat = (to.latitude - from.latitude) * pi / 180;
    final deltaLng = (to.longitude - from.longitude) * pi / 180;
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLng / 2) * sin(deltaLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Reset all filters
  void reset() {
    _kalmanFilter.reset();
    _movingAverageFilter.reset();
    _jumpDetector.reset();
    _speedFilter.reset();
    _filteredCoordinates.clear();
  }
}
