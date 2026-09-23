import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/dose_repository.dart';
import '../services/notification_service.dart';

/// Holds per-event countdown state after a "Simulate dispense" action.
class CountdownState {
  final String eventId;
  final DateTime dispensedAt;
  final Duration totalDuration;
  Duration remaining;
  bool expired;
  Timer? _timer;

  CountdownState({
    required this.eventId,
    required this.dispensedAt,
    required this.totalDuration,
  })  : remaining = totalDuration,
        expired = false;

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Provider for the Today (Home) screen.
///
/// Holds today's compartments, their dose events, and any active countdowns.
class TodayProvider extends ChangeNotifier {
  final DoseRepository _repo;
  final NotificationService _notif;

  List<Compartment> _compartments = [];
  List<DoseEvent> _events = [];
  final Map<String, CountdownState> _countdowns = {};
  bool _loading = true;

  TodayProvider(this._repo, this._notif);

  List<Compartment> get compartments => _compartments;
  List<DoseEvent> get events => _events;
  bool get loading => _loading;
  Map<String, CountdownState> get countdowns => _countdowns;

  DoseEvent? eventForCompartment(String compartmentId) {
    try {
      return _events.firstWhere((e) => e.compartmentId == compartmentId);
    } catch (_) {
      return null;
    }
  }

  CountdownState? countdownFor(String eventId) => _countdowns[eventId];

  Future<void> loadToday() async {
    _loading = true;
    notifyListeners();
    final now = DateTime.now();
    _compartments = await _repo.getCompartments();
    _events = await _repo.getEventsForDate(now);
    _loading = false;
    notifyListeners();
  }

  /// Simulates a hardware dispense event — moves the event to Dispensed
  /// and starts a countdown during which the user can "Mark collected."
  /// If the countdown expires without collection, auto-transitions to Missed.
  Future<void> simulateDispense(
    String eventId, {
    Duration countdownDuration = const Duration(minutes: 2),
  }) async {
    final now = DateTime.now();
    await _repo.updateEventStatus(eventId, DoseStatus.dispensed, now);

    // Update local state immediately
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      _events[idx] = _events[idx].copyWith(
        status: DoseStatus.dispensed,
        statusUpdatedAt: now,
      );
    }

    // Start countdown
    final cs = CountdownState(
      eventId: eventId,
      dispensedAt: now,
      totalDuration: countdownDuration,
    );
    _countdowns[eventId] = cs;

    cs._timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      cs.remaining -= const Duration(seconds: 1);
      if (cs.remaining <= Duration.zero) {
        timer.cancel();
        cs.expired = true;
        _countdowns.remove(eventId);
        await _markMissed(eventId);
      } else {
        notifyListeners();
      }
    });

    notifyListeners();
  }

  Future<void> markCollected(String eventId) async {
    // Cancel any running countdown
    _countdowns[eventId]?.cancel();
    _countdowns.remove(eventId);

    final now = DateTime.now();
    await _repo.updateEventStatus(eventId, DoseStatus.collected, now);

    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      _events[idx] = _events[idx].copyWith(
        status: DoseStatus.collected,
        statusUpdatedAt: now,
      );
    }
    notifyListeners();
  }

  Future<void> _markMissed(String eventId) async {
    final now = DateTime.now();
    await _repo.updateEventStatus(eventId, DoseStatus.missed, now);

    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      _events[idx] = _events[idx].copyWith(
        status: DoseStatus.missed,
        statusUpdatedAt: now,
      );

      // Fire missed notification
      final event = _events[idx];
      final comp = _compartments.firstWhere(
        (c) => c.id == event.compartmentId,
        orElse: () => Compartment(
          id: '',
          label: 'Unknown',
          medicineName: 'Unknown',
          scheduledHour: 0,
          scheduledMinute: 0,
        ),
      );
      await _notif.showMissedDoseNotification(
        id: eventId.hashCode,
        compartmentLabel: comp.label,
        medicineName: comp.medicineName,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final cs in _countdowns.values) {
      cs.cancel();
    }
    super.dispose();
  }
}
