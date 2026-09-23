/// MedTrack Data Models
///
/// Core domain objects for the Smart Medical Dispenser app.
/// These are plain Dart classes with no UI dependencies — safe to use
/// in any layer (UI, repository, hardware adapter).

enum DoseStatus {
  pending,
  dispensed,
  collected,
  missed;

  String get label {
    switch (this) {
      case DoseStatus.pending:
        return 'Pending';
      case DoseStatus.dispensed:
        return 'Dispensed';
      case DoseStatus.collected:
        return 'Collected';
      case DoseStatus.missed:
        return 'Missed';
    }
  }
}

/// A single recorded dose event for a compartment on a specific date.
class DoseEvent {
  final String id;
  final String compartmentId;
  final DateTime date; // The calendar date this event belongs to (time = midnight)
  DoseStatus status;
  DateTime statusUpdatedAt;

  DoseEvent({
    required this.id,
    required this.compartmentId,
    required this.date,
    required this.status,
    required this.statusUpdatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'compartmentId': compartmentId,
        'date': date.toIso8601String(),
        'status': status.name,
        'statusUpdatedAt': statusUpdatedAt.toIso8601String(),
      };

  factory DoseEvent.fromJson(Map<String, dynamic> json) => DoseEvent(
        id: json['id'] as String,
        compartmentId: json['compartmentId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: DoseStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DoseStatus.pending,
        ),
        statusUpdatedAt: DateTime.parse(json['statusUpdatedAt'] as String),
      );

  DoseEvent copyWith({
    DoseStatus? status,
    DateTime? statusUpdatedAt,
  }) =>
      DoseEvent(
        id: id,
        compartmentId: compartmentId,
        date: date,
        status: status ?? this.status,
        statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      );
}

/// A configured medicine compartment in the physical dispenser.
class Compartment {
  final String id;
  String label; // e.g. "Morning"
  String medicineName;
  int scheduledHour; // 0–23
  int scheduledMinute; // 0–59
  String notes;

  Compartment({
    required this.id,
    required this.label,
    required this.medicineName,
    required this.scheduledHour,
    required this.scheduledMinute,
    this.notes = '',
  });

  /// Formatted scheduled time string (HH:mm).
  String get scheduledTimeString {
    final h = scheduledHour.toString().padLeft(2, '0');
    final m = scheduledMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'medicineName': medicineName,
        'scheduledHour': scheduledHour,
        'scheduledMinute': scheduledMinute,
        'notes': notes,
      };

  factory Compartment.fromJson(Map<String, dynamic> json) => Compartment(
        id: json['id'] as String,
        label: json['label'] as String,
        medicineName: json['medicineName'] as String,
        scheduledHour: json['scheduledHour'] as int,
        scheduledMinute: json['scheduledMinute'] as int,
        notes: (json['notes'] as String?) ?? '',
      );

  Compartment copyWith({
    String? label,
    String? medicineName,
    int? scheduledHour,
    int? scheduledMinute,
    String? notes,
  }) =>
      Compartment(
        id: id,
        label: label ?? this.label,
        medicineName: medicineName ?? this.medicineName,
        scheduledHour: scheduledHour ?? this.scheduledHour,
        scheduledMinute: scheduledMinute ?? this.scheduledMinute,
        notes: notes ?? this.notes,
      );
}
