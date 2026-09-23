import '../models/models.dart';

/// Abstract repository interface for dose/compartment data.
///
/// The UI and providers depend ONLY on this interface.
/// Swap implementations (LocalDoseRepository, HardwareDoseRepository, etc.)
/// without touching any UI code.
abstract class DoseRepository {
  // ── Compartments ─────────────────────────────────────────────────────────

  Future<List<Compartment>> getCompartments();

  Future<void> saveCompartment(Compartment compartment);

  Future<void> deleteCompartment(String id);

  // ── Dose Events ───────────────────────────────────────────────────────────

  /// Returns dose events for the given calendar date, creating pending ones if absent.
  Future<List<DoseEvent>> getEventsForDate(DateTime date);

  /// All dose events, newest first.
  Future<List<DoseEvent>> getAllEvents();

  Future<void> updateEventStatus(
    String eventId,
    DoseStatus newStatus,
    DateTime updatedAt,
  );

  /// Returns adherence ratio (0.0–1.0) of collected doses over the last [days] days.
  Future<double> getAdherenceRate({int days = 7});
}
