package com.talkinspace.talkinspace

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createCardChannel()
    }

    /**
     * The server posts every card notification to the "space_talk_cards"
     * channel. On Android 8+ a channel must exist before anything can be shown
     * on it — otherwise FCM quietly falls back to a low-importance
     * "Miscellaneous" channel, which raises no heads-up banner. It is created
     * here because opening this screen is the only route to signing in, so the
     * channel always exists before the account can be pushed to.
     */
    private fun createCardChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CARD_CHANNEL_ID,
            "Messages",
            // HIGH, not DEFAULT: a card fades, so a notice the reader does not
            // see until they next unlock is worth very little.
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Someone is waiting on Space"
        }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }

    private companion object {
        // Must match push.Message.ChannelID on the server and the
        // default_notification_channel_id meta-data in the manifest.
        const val CARD_CHANNEL_ID = "space_talk_cards"
    }
}
