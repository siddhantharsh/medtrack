import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loadingNotifState = true;

  @override
  void initState() {
    super.initState();
    _loadNotifState();
  }

  Future<void> _loadNotifState() async {
    final svc = context.read<NotificationService>();
    final enabled = await svc.isEnabled;
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _loadingNotifState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── Notifications ───────────────────────────────────────────
        _SectionHeader(title: 'Notifications'),
        Card(
          child: SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: const Text(
              'Local Notifications',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.nearBlack),
            ),
            subtitle: const Text(
              'Alerts for due doses and missed collections',
              style: TextStyle(fontSize: 13, color: Color(0xFF4A6F72)),
            ),
            value: _notificationsEnabled,
            activeColor: AppTheme.teal,
            onChanged: _loadingNotifState
                ? null
                : (v) async {
                    setState(() => _notificationsEnabled = v);
                    final svc = context.read<NotificationService>();
                    await svc.setEnabled(v);
                  },
          ),
        ),

        const SizedBox(height: 20),

        // ── Hardware Sync (disabled placeholder) ─────────────────────
        _SectionHeader(title: 'Hardware Sync'),
        Opacity(
          opacity: 0.45,
          child: Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.bluetooth_outlined,
                      color: AppTheme.teal),
                  title: const Text(
                    'Bluetooth / Cloud Sync',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.nearBlack),
                  ),
                  subtitle: const Text(
                    'Sync with the Arduino dispenser over BLE or MQTT',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4A6F72)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.wifi_outlined, color: AppTheme.teal),
                  title: const Text(
                    'WiFi / MQTT Bridge',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.nearBlack),
                  ),
                  subtitle: const Text(
                    'Connect via ESP8266 MQTT bridge for remote monitoring',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4A6F72)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hardware sync will be enabled once the Bluetooth/MQTT layer is implemented.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── About ─────────────────────────────────────────────────────
        _SectionHeader(title: 'About'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MedTrack',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.nearBlack,
                          ),
                        ),
                        Text(
                          'Smart Medical Dispenser Companion',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A6F72),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'MedTrack is the caregiver/patient-facing companion app for the Smart Medical Dispenser IoT project. '
                  'The physical dispenser uses an Arduino Uno with servo motors to dispense medicine from labelled '
                  'compartments on a timed schedule. This app tracks doses, shows history, and will sync with the '
                  'hardware once the Bluetooth/MQTT layer is complete.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E5055),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _AboutRow(
                    icon: Icons.build_outlined, label: 'Version', value: '1.0.0'),
                const SizedBox(height: 8),
                _AboutRow(
                    icon: Icons.storage_outlined,
                    label: 'Storage',
                    value: 'Local (SharedPreferences)'),
                const SizedBox(height: 8),
                _AboutRow(
                    icon: Icons.cloud_off_outlined,
                    label: 'Network',
                    value: 'None — fully offline'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppTheme.teal,
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.teal),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.nearBlack),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4A6F72)),
        ),
      ],
    );
  }
}
