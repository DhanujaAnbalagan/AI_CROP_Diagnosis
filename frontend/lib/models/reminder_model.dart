/// Reminder types for Farm Calendar
enum ReminderType {
  pesticide,
  fertilizer,
  irrigation,
  harvest,
  inspection,
}

extension ReminderTypeExtension on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.pesticide:   return 'Pesticide';
      case ReminderType.fertilizer:  return 'Fertilizer';
      case ReminderType.irrigation:  return 'Irrigation';
      case ReminderType.harvest:     return 'Harvest';
      case ReminderType.inspection:  return 'Inspection';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.pesticide:   return '🧪';
      case ReminderType.fertilizer:  return '🌱';
      case ReminderType.irrigation:  return '💧';
      case ReminderType.harvest:     return '🌾';
      case ReminderType.inspection:  return '🔍';
    }
  }

  int get colorValue {
    switch (this) {
      case ReminderType.pesticide:   return 0xFFEF5350; // red
      case ReminderType.fertilizer:  return 0xFF4CAF50; // green
      case ReminderType.irrigation:  return 0xFF2196F3; // blue
      case ReminderType.harvest:     return 0xFFFF9800; // orange
      case ReminderType.inspection:  return 0xFF9C27B0; // purple
    }
  }

  static ReminderType fromString(String value) {
    return ReminderType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReminderType.inspection,
    );
  }
}

/// Data model for a farm reminder/event.
class ReminderModel {
  final String id;
  final String title;
  final String cropName;
  final DateTime scheduledDate;
  final String scheduledTime; // "HH:mm"
  final ReminderType reminderType;
  final bool isCompleted;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.cropName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.reminderType,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'cropName': cropName,
    'scheduledDate': scheduledDate.toIso8601String(),
    'scheduledTime': scheduledTime,
    'reminderType': reminderType.name,
    'isCompleted': isCompleted ? 1 : 0,
  };

  factory ReminderModel.fromMap(Map<String, dynamic> map) => ReminderModel(
    id: map['id'] as String,
    title: map['title'] as String,
    cropName: map['cropName'] as String,
    scheduledDate: DateTime.parse(map['scheduledDate'] as String),
    scheduledTime: map['scheduledTime'] as String,
    reminderType: ReminderTypeExtension.fromString(map['reminderType'] as String),
    isCompleted: (map['isCompleted'] as int) == 1,
  );

  ReminderModel copyWith({bool? isCompleted}) => ReminderModel(
    id: id,
    title: title,
    cropName: cropName,
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
    reminderType: reminderType,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}
