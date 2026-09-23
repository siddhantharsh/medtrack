import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../repositories/dose_repository.dart';

/// Provider for the Schedule screen.
class ScheduleProvider extends ChangeNotifier {
  final DoseRepository _repo;
  final _uuid = const Uuid();

  List<Compartment> _compartments = [];
  bool _loading = true;

  ScheduleProvider(this._repo);

  List<Compartment> get compartments => _compartments;
  bool get loading => _loading;

  Future<void> loadCompartments() async {
    _loading = true;
    notifyListeners();
    _compartments = await _repo.getCompartments();
    _loading = false;
    notifyListeners();
  }

  Future<void> addCompartment({
    required String label,
    required String medicineName,
    required int hour,
    required int minute,
    String notes = '',
  }) async {
    final comp = Compartment(
      id: _uuid.v4(),
      label: label,
      medicineName: medicineName,
      scheduledHour: hour,
      scheduledMinute: minute,
      notes: notes,
    );
    await _repo.saveCompartment(comp);
    _compartments = await _repo.getCompartments();
    notifyListeners();
  }

  Future<void> updateCompartment(Compartment compartment) async {
    await _repo.saveCompartment(compartment);
    final idx = _compartments.indexWhere((c) => c.id == compartment.id);
    if (idx >= 0) {
      _compartments[idx] = compartment;
    } else {
      _compartments.add(compartment);
    }
    notifyListeners();
  }

  Future<void> deleteCompartment(String id) async {
    await _repo.deleteCompartment(id);
    _compartments.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
