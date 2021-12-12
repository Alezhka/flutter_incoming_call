package com.github.alezhka.flutter_incoming_call

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.VibrationEffect
import android.os.Vibrator

class CallPlayer(private val context: Context, var config: PluginConfig) {

    private var mMediaPlayer: MediaPlayer? = null
    private val vibrator: Vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    private val pattern = longArrayOf(0, 1000, 800)
    private var isPlaying = false
    
    private val handler = Handler()

    fun play(callData: CallData) {
        if(isPlaying) {
            stop()
        }

        if(config.vibration) playVibrate()
        if(config.ringtonePath != null) playMusic(callData)
        isPlaying = true
    }

    fun stop() {
        if(!isPlaying) {
            return
        }

        stopMusic()
        stopVibrate()
        isPlaying = false
    }
    
    fun isPlaying(): Boolean {
        return isPlaying
    }

    private fun playMusic(callData: CallData) {
        val ringtonePath = config.ringtonePath ?: return
        val uri = getRingtoneUri(ringtonePath)
        val attribution = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()
        mMediaPlayer = MediaPlayer.create(context, uri).apply {
            isLooping = true
            setAudioAttributes(attribution)
            start()
        }
        cancelWithTimeOut(callData)
    }

    private fun stopMusic() {
        mMediaPlayer?.run {
            stop()
            seekTo(0)
        }
    }

    private fun playVibrate() {
        if(!vibrator.hasVibrator()) {
            return
        }

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            vibrator.vibrate(pattern, 0)
        }
    }

    private fun stopVibrate() {
        vibrator.cancel()
    }

    private fun getRingtoneUri(fileName: String) = try {
        val resId = context.resources.getIdentifier(fileName, "raw", context.packageName)
        if (resId != 0) {
            Uri.parse("android.resource://${context.packageName}/$resId")
        } else {
            Uri.parse("android.resource://${context.packageName}/${R.raw.ringtone}")
        }
    } catch (e: Exception) {
        Uri.parse("android.resource://${context.packageName}/${R.raw.ringtone}")
    }

    private fun cancelWithTimeOut(callData: CallData) {
        handler.postDelayed({
            if (mMediaPlayer?.isPlaying == true) {
                val intent = CallBroadcastReceiver.timeoutIntent(context, callData)
                context.sendBroadcast(intent)
                stop()
            }
        }, config.duration)
    }

}