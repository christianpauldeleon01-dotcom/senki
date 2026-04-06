// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final int typeId = 0;

  @override
  ActivityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityType.running;
      case 1:
        return ActivityType.jogging;
      case 2:
        return ActivityType.walking;
      case 3:
        return ActivityType.cycling;
      default:
        return ActivityType.running;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    switch (obj) {
      case ActivityType.running:
        writer.writeByte(0);
        break;
      case ActivityType.jogging:
        writer.writeByte(1);
        break;
      case ActivityType.walking:
        writer.writeByte(2);
        break;
      case ActivityType.cycling:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CoordinateAdapter extends TypeAdapter<Coordinate> {
  @override
  final int typeId = 1;

  @override
  Coordinate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Coordinate(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      timestamp: fields[2] as DateTime,
      altitude: fields[3] as double?,
      speed: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Coordinate obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.altitude)
      ..writeByte(4)
      ..write(obj.speed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoordinateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityAdapter extends TypeAdapter<Activity> {
  @override
  final int typeId = 2;

  @override
  Activity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // Safely parse durationSeconds (handle NaN/infinity)
    int durationSeconds = 0;
    final durValue = fields[2];
    if (durValue is int) {
      durationSeconds = durValue;
    } else if (durValue is double && durValue.isFinite) {
      durationSeconds = durValue.toInt();
    }
    
    // Safely parse distanceMeters (handle NaN/infinity)
    double distanceMeters = 0.0;
    final distValue = fields[3];
    if (distValue is double && distValue.isFinite) {
      distanceMeters = distValue;
    }
    
    // Safely parse averagePaceSecondsPerKm (handle NaN/infinity)
    double averagePaceSecondsPerKm = 0.0;
    final paceValue = fields[4];
    if (paceValue is double && paceValue.isFinite) {
      averagePaceSecondsPerKm = paceValue;
    }
    
    return Activity(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      averageSpeedMps: _safeParseDouble(fields[5]),
      routeCoordinates: (fields[6] as List).cast<Coordinate>(),
      activityType: fields[7] as ActivityType,
      photoPath: fields[8] as String?,
      caloriesBurned: _safeParseDouble(fields[9]),
      steps: _safeParseInt(fields[10]),
      movingTimeSeconds: _safeParseInt(fields[11]),
      movingDistanceMeters: _safeParseDouble(fields[12]),
    );
  }
  
  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double && value.isFinite) return value;
    if (value is double && (value.isNaN || value.isInfinite)) return null;
    if (value is int) return value.toDouble();
    return null;
  }
  
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double && value.isFinite) return value.toInt();
    return null;
  }

  @override
  void write(BinaryWriter writer, Activity obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.distanceMeters.isFinite ? obj.distanceMeters : 0.0)
      ..writeByte(4)
      ..write(obj.averagePaceSecondsPerKm.isFinite ? obj.averagePaceSecondsPerKm : 0.0)
      ..writeByte(5)
      ..write(obj.averageSpeedMps?.isFinite == true ? obj.averageSpeedMps : null)
      ..writeByte(6)
      ..write(obj.routeCoordinates)
      ..writeByte(7)
      ..write(obj.activityType)
      ..writeByte(8)
      ..write(obj.photoPath)
      ..writeByte(9)
      ..write(obj.caloriesBurned?.isFinite == true ? obj.caloriesBurned : null)
      ..writeByte(10)
      ..write(obj.steps)
      ..writeByte(11)
      ..write(obj.movingTimeSeconds)
      ..writeByte(12)
      ..write(obj.movingDistanceMeters?.isFinite == true ? obj.movingDistanceMeters : null);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
