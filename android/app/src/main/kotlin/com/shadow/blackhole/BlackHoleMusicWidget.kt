package com.qbits.shuno

import MainActivity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Implementation of App Widget functionality.
 */
class shunoMusicWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }
}

internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, widgetData: SharedPreferences) {
    val views = RemoteViews(context.packageName, R.layout.black_hole_music_widget).apply {
    // Open App on Widget Click
    val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java)
    setOnClickPendingIntent(R.id.widget_container, pendingIntent)

    setTextViewText(R.id.widget_title_text, widgetData.getString("title", null)
            ?: "Title")
    setTextViewText(R.id.widget_subtitle_text, widgetData.getString("message", null)
            ?: "Subtitle")

    val skipNextIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("shuno://controls/skipNext")
    )
    setOnClickPendingIntent(R.id.widget_button_next, skipNextIntent)

    val skipPreviousIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("shuno://controls/skipPrevious")
    )
    setOnClickPendingIntent(R.id.widget_button_prev, skipPreviousIntent)

    val playPauseIntent = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("shuno://controls/playPause")
    )
    setOnClickPendingIntent(R.id.widget_button_play_pause, playPauseIntent)

    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}