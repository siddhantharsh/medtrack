import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/today_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodayProvider>().loadToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodayProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.teal),
          );
        }

        if (provider.compartments.isEmpty) {
          return _EmptyState();
        }

        return RefreshIndicator(
          color: AppTheme.teal,
          onRefresh: () => provider.loadToday(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: provider.compartments.length,
            itemBuilder: (context, i) {
              final comp = provider.compartments[i];
              final event = provider.eventForCompartment(comp.id);
              if (event == null) return const SizedBox.shrink();
              return _DoseCard(
                compartment: comp,
                event: event,
                countdown: provider.countdownFor(event.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined,
                size: 72, color: AppTheme.teal.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text(
              'No compartments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.nearBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to Schedule to add your first medication compartment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF4A6F72)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  final Compartment compartment;
  final DoseEvent event;
  final CountdownState? countdown;

  const _DoseCard({
    required this.compartment,
    required this.event,
    this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodayProvider>();
    final status = event.status;
    final isCountingDown = countdown != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: label + status pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    compartment.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.nearBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 8),

            // Medicine name
            Row(
              children: [
                const Icon(Icons.medication,
                    size: 16, color: AppTheme.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    compartment.medicineName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2E5055),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Scheduled time
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 16, color: AppTheme.teal),
                const SizedBox(width: 6),
                Text(
                  compartment.scheduledTimeString,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A6F72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Countdown (if dispensed and within collection window)
            if (isCountingDown) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  CountdownRing(
                    remaining: countdown!.remaining,
                    total: countdown!.totalDuration,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collect within window',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.nearBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dose will be marked Missed if not collected.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A6F72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => provider.markCollected(event.id),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark Collected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mint,
                  ),
                ),
              ),
            ],

            // Action button (Simulate Dispense) — only for pending
            if (status == DoseStatus.pending) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => provider.simulateDispense(event.id),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Simulate Dispense'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.teal,
                    side: const BorderSide(color: AppTheme.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
