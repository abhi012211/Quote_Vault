import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId =
      'group.quote_vault'; // Ensure this matches iOS group if implemented
  static const String androidWidgetName = 'QuoteWidgetProvider';

  static Future<void> updateWidget(String quote, String author) async {
    try {
      await HomeWidget.saveWidgetData<String>('quote_content', quote);
      await HomeWidget.saveWidgetData<String>('quote_author', "- $author");

      await HomeWidget.updateWidget(name: androidWidgetName);
    } catch (e) {
      // Handle or log error
      print('Error updating widget: $e');
    }
  }
}
