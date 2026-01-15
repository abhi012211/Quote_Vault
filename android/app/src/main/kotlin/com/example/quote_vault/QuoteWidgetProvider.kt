package com.example.quote_vault

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_quote).apply {
                val quote = widgetData.getString("quote_content", "Time for wisdom")
                val author = widgetData.getString("quote_author", "QuoteVault")
                
                setTextViewText(R.id.widget_content, quote)
                setTextViewText(R.id.widget_author, author)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
