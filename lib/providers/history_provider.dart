import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/dose_repository.dart';

class HistoryGroup {
  final DateTime date;
  final List<_EventWithCompartment> entries;
  HistoryGroup({required this.date, required this.entries});
}

class _EventWithCompartment {
  final DoseEvent event;
  final Compartment compartment;
  _EventWithCompartment({required this.event, required this.compartment});
}

typedef EventWithCompartment = _EventWithCompartment;

/// Provider for the History screen.
class HistoryProvider extends ChangeNotifier {
  final DoseRepository _repo;

  List<HistoryGroup> _groups = [];
  double _adherenceRate = 1.0;
  bool _loading = true;

  HistoryProvider(this._repo);

  List<HistoryGroup> get groups => _groups;
  double get adherenceRate => _adherenceRate;
  bool get loading => _loading;

  Future<void> load(List<Compartment> compartments) async {
    _loading = true;
    notifyListeners();

    final events = await _repo.getAllEvents();
    _adherenceRate = await _repo.getAdherenceRate(days: 7);

    // Group events by date
    final Map<String, List<EventWithCompartment>> byDate = {};
    for (final event in events) {
      final key = _dateKey(event.date);
      byDate.putIfAbsent(key, () => []);
      final comp = compartments.firstWhere(
        (c) => c.id == event.compartmentId,
        orElse: () => Compartment(
          id: event.compartmentId,
          label: 'Deleted',
          medicineName: '',
          scheduledHour: 0,
          scheduledMinute: 0,
        ),
      );
      byDate[key]!.add(EventWithCompartment(event: event, compartment: comp));
    }

    // Sort groups newest first
    final sortedKeys = byDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    _groups = sortedKeys.map((k) {
      final parts = k.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return HistoryGroup(date: date, entries: byDate[k]!);
    }).toList();

    _loading = false;
    notifyListeners();
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
