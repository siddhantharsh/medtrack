import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadCompartments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.teal));
        }
        return Stack(
          children: [
            if (provider.compartments.isEmpty)
              _EmptyScheduleState()
            else
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: provider.compartments.length,
                itemBuilder: (context, i) {
                  final comp = provider.compartments[i];
                  return _CompartmentTile(
                    compartment: comp,
                    onEdit: () => _openForm(context, comp),
                    onDelete: () => _confirmDelete(context, provider, comp),
                  );
                },
              ),
            Positioned(
              right: 20,
              bottom: 24,
              child: FloatingActionButton.extended(
                onPressed: () => _openForm(context, null),
                backgroundColor: AppTheme.teal,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Compartment'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openForm(BuildContext context, Compartment? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CompartmentForm(existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ScheduleProvider provider,
    Compartment comp,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Compartment'),
        content: Text(
            'Delete "${comp.label}"? All associated dose history will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.missed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteCompartment(comp.id);
    }
  }
}

class _EmptyScheduleState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline,
                size: 72, color: AppTheme.teal.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text(
              'No compartments configured',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.nearBlack),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Add Compartment" to configure your first medication slot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF4A6F72)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompartmentTile extends StatelessWidget {
  final Compartment compartment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompartmentTile({
    required this.compartment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        leading: CircleAvatar(
          backgroundColor: AppTheme.teal.withOpacity(0.12),
          child: const Icon(Icons.medication, color: AppTheme.teal),
        ),
        title: Text(
          compartment.label,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppTheme.nearBlack),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              compartment.medicineName,
              style: const TextStyle(color: Color(0xFF2E5055)),
            ),
            if (compartment.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  compartment.notes,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF7AAAA5)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                compartment.scheduledTimeString,
                style: const TextStyle(
                  color: AppTheme.teal,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AppTheme.missed)),
                ),
              ],
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

/// Bottom sheet form for adding or editing a compartment.
class CompartmentForm extends StatefulWidget {
  final Compartment? existing;

  const CompartmentForm({super.key, this.existing});

  @override
  State<CompartmentForm> createState() => _CompartmentFormState();
}

class _CompartmentFormState extends State<CompartmentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _medicineCtrl;
  late final TextEditingController _notesCtrl;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _labelCtrl = TextEditingController(text: c?.label ?? '');
    _medicineCtrl = TextEditingController(text: c?.medicineName ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _selectedTime = c != null
        ? TimeOfDay(hour: c.scheduledHour, minute: c.scheduledMinute)
        : TimeOfDay.now();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _medicineCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isEdit ? 'Edit Compartment' : 'New Compartment',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.nearBlack,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Compartment Label',
                hintText: 'e.g. Morning',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _medicineCtrl,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'e.g. Metformin 500mg',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            // Time picker row
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppTheme.teal),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.nearBlack,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Take with food',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Save Changes' : 'Add Compartment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppTheme.teal),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ScheduleProvider>();

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        label: _labelCtrl.text.trim(),
        medicineName: _medicineCtrl.text.trim(),
        scheduledHour: _selectedTime.hour,
        scheduledMinute: _selectedTime.minute,
        notes: _notesCtrl.text.trim(),
      );
      await provider.updateCompartment(updated);
    } else {
      await provider.addCompartment(
        label: _labelCtrl.text.trim(),
        medicineName: _medicineCtrl.text.trim(),
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        notes: _notesCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
