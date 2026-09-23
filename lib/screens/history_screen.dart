import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final compartments =
          context.read<ScheduleProvider>().compartments;
      context.read<HistoryProvider>().load(compartments);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.teal));
        }

        if (provider.groups.isEmpty) {
          return _EmptyHistory();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: _totalItems(provider),
          itemBuilder: (context, index) =>
              _buildItem(context, provider, index),
        );
      },
    );
  }

  int _totalItems(HistoryProvider provider) {
    // adherence card + (date header + entries per group)
    int count = 1; // adherence
    for (final g in provider.groups) {
      count += 1 + g.entries.length; // header + entries
    }
    return count;
  }

  Widget _buildItem(
      BuildContext context, HistoryProvider provider, int index) {
    if (index == 0) {
      return AdherenceCard(rate: provider.adherenceRate);
    }

    int cursor = 1;
    for (final group in provider.groups) {
      if (index == cursor) {
        return DateHeader(date: group.date);
      }
      cursor++;
      for (final entry in group.entries) {
        if (index == cursor) {
          return _EventRow(entry: entry);
        }
        cursor++;
      }
    }
    return const SizedBox.shrink();
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history,
                size: 72, color: AppTheme.teal.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text(
              'No dose history yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.nearBlack),
            ),
            const SizedBox(height: 8),
            const Text(
              'History will appear here after you simulate dispenses on the Today tab.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF4A6F72)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final EventWithCompartment entry;

  const _EventRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final event = entry.event;
    final comp = entry.compartment;
    final time = _formatTime(event.statusUpdatedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Status indicator dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.statusColor(event.status),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comp.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.nearBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comp.medicineName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A6F72),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(status: event.status),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8AADAC),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
