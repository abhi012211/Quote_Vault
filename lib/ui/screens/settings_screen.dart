import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(settings.themeMode.toString().split('.').last),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  notifier.setThemeMode(newValue);
                }
              },
              items: ThemeMode.values.map((ThemeMode classType) {
                return DropdownMenuItem<ThemeMode>(
                  value: classType,
                  child: Text(classType.toString().split('.').last),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Daily Quote Notification'),
            value: settings.notificationsEnabled,
            onChanged: (bool value) {
              notifier.toggleNotifications(value);
            },
          ),
          ListTile(
            title: const Text('Notification Time'),
            subtitle: Text(settings.notificationTime.format(context)),
            enabled: settings.notificationsEnabled,
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: settings.notificationTime,
              );
              if (picked != null && picked != settings.notificationTime) {
                notifier.setNotificationTime(picked);
              }
            },
          ),
        ],
      ),
    );
  }
}
