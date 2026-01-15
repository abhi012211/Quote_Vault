import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// Keys
const String kThemeModeKey = 'theme_mode';
const String kNotificationsEnabledKey = 'notifications_enabled';
const String kNotificationTimeKey = 'notification_time'; // Store as "HH:mm"

class SettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final TimeOfDay notificationTime;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.notificationTime = const TimeOfDay(hour: 8, minute: 0),
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    TimeOfDay? notificationTime,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  late final SharedPreferences _prefs;
  late final NotificationService _notificationService;

  @override
  SettingsState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _notificationService = ref.watch(notificationServiceProvider);

    // Load initial state synchronously if possible, or assume defaults and load async?
    // Since prefs are async, they are injected. If they are already ready (overridden in main), we can use them.
    // The previous implementation did _loadSettings() in constructor.
    // Here we can just do:
    return _calculateInitialState();
  }

  SettingsState _calculateInitialState() {
    final themeIndex = _prefs.getInt(kThemeModeKey);
    final notificationsEnabled =
        _prefs.getBool(kNotificationsEnabledKey) ?? true;
    final timeString = _prefs.getString(kNotificationTimeKey);

    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        time = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    final newState = SettingsState(
      themeMode: themeIndex != null
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system,
      notificationsEnabled: notificationsEnabled,
      notificationTime: time,
    );

    // Side effect: Ensure schedule is correct.
    // We shouldn't do side effects in build usually, but this is migration.
    // Better to use a listener or init method.
    // For now, let's keep it simple.
    if (notificationsEnabled) {
      // Don't await in build.
      _notificationService.scheduleDailyQuoteNotification(
        hour: time.hour,
        minute: time.minute,
      );
    }

    return newState;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(kThemeModeKey, mode.index);
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _prefs.setBool(kNotificationsEnabledKey, enabled);
    if (enabled) {
      await _notificationService.scheduleDailyQuoteNotification(
        hour: state.notificationTime.hour,
        minute: state.notificationTime.minute,
      );
    } else {
      await _notificationService.cancelDailyNotification();
    }
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    state = state.copyWith(notificationTime: time);
    await _prefs.setString(kNotificationTimeKey, '${time.hour}:${time.minute}');
    if (state.notificationsEnabled) {
      await _notificationService.scheduleDailyQuoteNotification(
        hour: time.hour,
        minute: time.minute,
      );
    }
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in main');
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
