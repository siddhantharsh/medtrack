import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'dose_repository.dart';

/// Concrete local implementation of [DoseRepository] backed by SharedPreferences.
///
/// Data layout in SharedPreferences:
///   medtrack_compartments  → JSON list of Compartment objects
///   medtrack_events        → JSON list of DoseEvent objects
class LocalDoseRepository implements DoseRepository {
  static const _compartmentsKey = 'medtrack_compartments';
  static const _eventsKey = 'medtrack_events';
  final _uuid = const Uuid();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Compartments ─────────────────────────────────────────────────────────

  @override
  Future<List<Compartment>> getCompartments() async {
    final prefs = await _prefsInstance;
    final raw = prefs.getString(_compartmentsKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Compartment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveCompartments(List<Compartment> compartments) async {
    final prefs = await _prefsInstance;
    await prefs.setString(
      _compartmentsKey,
      json.encode(compartments.map((c) => c.toJson()).toList()),
    );
  }

  @override
  Future<void> saveCompartment(Compartment compartment) async {
    final compartments = await getCompartments();
    final idx = compartments.indexWhere((c) => c.id == compartment.id);
    if (idx >= 0) {
      compartments[idx] = compartment;
    } else {
      compartments.add(compartment);
    }
    await _saveCompartments(compartments);
  }

  @override
  Future<void> deleteCompartment(String id) async {
    final compartments = await getCompartments();
    compartments.removeWhere((c) => c.id == id);
    await _saveCompartments(compartments);
    // Also remove associated events
    final events = await _loadAllEvents();
    events.removeWhere((e) => e.compartmentId == id);
    await _saveEvents(events);
  }

  // ── Dose Events ───────────────────────────────────────────────────────────

  Future<List<DoseEvent>> _loadAllEvents() async {
    final prefs = await _prefsInstance;
    final raw = prefs.getString(_eventsKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => DoseEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveEvents(List<DoseEvent> events) async {
    final prefs = await _prefsInstance;
    await prefs.setString(
      _eventsKey,
      json.encode(events.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<DoseEvent>> getEventsForDate(DateTime date) async {
    final dateOnly = _dateOnly(date);
    final compartments = await getCompartments();
    final allEvents = await _loadAllEvents();

    // Find or create an event for each compartment on this date
    final result = <DoseEvent>[];
    bool anyNew = false;

    for (final comp in compartments) {
      final existing = allEvents.firstWhere(
        (e) =>
            e.compartmentId == comp.id &&
            _dateOnly(e.date) == dateOnly,
        orElse: () => DoseEvent(
          id: _uuid.v4(),
          compartmentId: comp.id,
          date: dateOnly,
          status: DoseStatus.pending,
          statusUpdatedAt: DateTime.now(),
        ),
      );

      // Check if we just created it
      final isNew = !allEvents.any(
        (e) =>
            e.compartmentId == comp.id &&
            _dateOnly(e.date) == dateOnly,
      );
      if (isNew) {
        allEvents.add(existing);
        anyNew = true;
      }
      result.add(existing);
    }

    if (anyNew) {
      await _saveEvents(allEvents);
    }

    // Sort by compartment scheduled time
    result.sort((a, b) {
      final compA = compartments.firstWhere((c) => c.id == a.compartmentId,
          orElse: () => compartments.first);
      final compB = compartments.firstWhere((c) => c.id == b.compartmentId,
          orElse: () => compartments.first);
      final timeA = compA.scheduledHour * 60 + compA.scheduledMinute;
      final timeB = compB.scheduledHour * 60 + compB.scheduledMinute;
      return timeA.compareTo(timeB);
    });

    return result;
  }

  @override
  Future<List<DoseEvent>> getAllEvents() async {
    final events = await _loadAllEvents();
    events.sort((a, b) => b.statusUpdatedAt.compareTo(a.statusUpdatedAt));
    return events;
  }

  @override
  Future<void> updateEventStatus(
    String eventId,
    DoseStatus newStatus,
    DateTime updatedAt,
  ) async {
    final events = await _loadAllEvents();
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx < 0) return;
    events[idx] = events[idx].copyWith(
      status: newStatus,
      statusUpdatedAt: updatedAt,
    );
    await _saveEvents(events);
  }

  @override
  Future<double> getAdherenceRate({int days = 7}) async {
    final now = DateTime.now();
    final cutoff = _dateOnly(now.subtract(Duration(days: days)));
    final events = await _loadAllEvents();

    final relevant = events.where((e) {
      final d = _dateOnly(e.date);
      return !d.isBefore(cutoff) && d.isBefore(_dateOnly(now));
    }).toList();

    if (relevant.isEmpty) return 1.0; // No past events = 100% (nothing missed)
    final collected = relevant.where((e) => e.status == DoseStatus.collected).length;
    return collected / relevant.length;
  }

  /// Returns a DateTime with only year/month/day (time stripped to midnight).
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Creates a new compartment with a fresh UUID.
  Compartment createCompartment({
    required String label,
    required String medicineName,
    required int hour,
    required int minute,
    String notes = '',
  }) =>
      Compartment(
        id: _uuid.v4(),
        label: label,
        medicineName: medicineName,
        scheduledHour: hour,
        scheduledMinute: minute,
        notes: notes,
      );
}
