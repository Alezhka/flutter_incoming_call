package com.github.alezhka.flutter_incoming_call

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.VibrationEffect
import android.os.Vibrator

class CallPlayer private constructor(private val mContext: Context) {

    companion object {

        @Volatile private var INSTANCE: CallPlayer? = null

        fun getInstance(context: Context): CallPlayer =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: CallPlayer(context).also { INSTANCE = it }
            }

    }

    private var mMediaPlayer: MediaPlayer? = null
    private val vibrator: Vibrator = mContext.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    private val pattern = longArrayOf(0, 1000, 800)
    private var isPlaying = false
    
    private val handler = Handler()

    fun play(callData: CallData) {
        if(callData.vibration) playVibrate()
        if(callData.ringtone) playMusic(callData)
        isPlaying = true
    }

    fun stop() {
        stopMusic()
        stopVibrate()
        isPlaying = false
    }
    
    fun isPlaying(): Boolean {
        return isPlaying
    }

    private fun playMusic(callData: CallData) {
        val uri = getRingtoneUri(callData.ringtonePath)
        val attribution = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()
        mMediaPlayer = MediaPlayer.create(mContext, uri).apply {
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
        val resId = mContext.resources.getIdentifier(fileName, "raw", mContext.packageName)
        if (resId != 0) {
            Uri.parse("android.resource://${mContext.packageName}/$resId")
        } else {
            Uri.parse("android.resource://${mContext.packageName}/${R.raw.ringtone}")
        }
    } catch (e: Exception) {
        Uri.parse("android.resource://${mContext.packageName}/${R.raw.ringtone}")
    }

    private fun cancelWithTimeOut(callData: CallData) {
        handler.postDelayed({
            if (mMediaPlayer?.isPlaying == true) {
                val intent = CallBroadcastReceiver.timeoutIntent(mContext, callData)
                mContext.sendBroadcast(intent)
                stop()
            }
        }, callData.duration)
    }

}