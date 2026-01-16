package com.example.quote_vault

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val quote = widgetData.getString("quote_content", "Time for wisdom")
                val author = widgetData.getString("quote_author", "QuoteVault")
                val quoteId = widgetData.getString("quote_id", null)

                setTextViewText(R.id.widget_content, quote)
                setTextViewText(R.id.widget_author, "- $author")

                // Open App Intent
                val intent = android.content.Intent(context, MainActivity::class.java).apply {
                    action = android.content.Intent.ACTION_VIEW
                    data = android.net.Uri.parse("io.supabase.quotevault://explore?query=${java.net.URLEncoder.encode(quote, "UTF-8")}") 
                    // Using query for now as robust deep linking to ID requires fetch.
                    // Or we can link to /explore and pass parameters.
                }
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
