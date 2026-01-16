import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quote_vault/core/constants/app_constants.dart';
import 'package:quote_vault/data/services/widget_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize Supabase for Background Task
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );

      final supabase = Supabase.instance.client;

      // Fetch a random quote for the widget
      final response = await supabase.from('quotes').select().limit(50);
      final List<dynamic> data = response as List<dynamic>;

      if (data.isNotEmpty) {
        final randomData = (data..shuffle()).first;

        await WidgetService.updateWidget(
          randomData['content'],
          randomData['author'],
          randomData['id'],
        );
      }

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    await Workmanager().registerPeriodicTask(
      "daily_quote_task",
      "fetchDailyQuote",
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
