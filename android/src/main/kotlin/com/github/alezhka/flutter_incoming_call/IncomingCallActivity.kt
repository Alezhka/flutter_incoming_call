package com.github.alezhka.flutter_incoming_call

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DataSource
import com.bumptech.glide.load.engine.GlideException
import com.bumptech.glide.request.RequestListener
import com.bumptech.glide.request.target.Target


class IncomingCallActivity : AppCompatActivity() {

    companion object {

        private const val ACTION_INCOMING_CALL = "com.github.alezhka.flutter_incoming_call.activity.ACTION_INCOMING_CALL"
        private const val EXTRA_CALL_DATA = "EXTRA_CALL_DATA"
        
        private var fa: IncomingCallActivity? = null

        fun start(callData: CallData) = Intent(ACTION_INCOMING_CALL).apply {
            putExtra(EXTRA_CALL_DATA, callData)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }

        fun dismissIncoming(uuid: String?) {
            fa?.let {
                if(uuid == null || uuid == it.callData.uuid) {
                    FlutterIncomingCallPlugin.ringtonePlayer?.stop()
                    it.finish()
                }
            }
        }
    }

    private val tvName by lazy { findViewById<TextView>(R.id.tv_name) }
    private val tvNumber by lazy { findViewById<TextView>(R.id.tv_number) }
    private val ivAvatar by lazy { findViewById<ImageView>(R.id.iv_avatar) }

    private lateinit var callData: CallData

    override fun onCreate(savedInstanceState: Bundle?) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        }
        super.onCreate(savedInstanceState)

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
            setTurnScreenOn(true)
            setShowWhenLocked(true)

            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        }

        fa = this
        setContentView(R.layout.activity_incoming_call)
        val data = intent.extras?.getParcelable<CallData>(EXTRA_CALL_DATA)
        if(data == null) {
            finish()
            return
        }
        
        callData = data
        tvName.text = callData.name
        tvNumber.text = callData.handle

        if (callData.avatar != null) {
            Glide
                    .with(this)
                    .load(callData.avatar)
                    .circleCrop()
                    .listener(object: RequestListener<Drawable> {
                        override fun onLoadFailed(e: GlideException?, model: Any?, target: Target<Drawable>?, isFirstResource: Boolean): Boolean {
                            return false
                        }

                        override fun onResourceReady(resource: Drawable?, model: Any?, target: Target<Drawable>?, dataSource: DataSource?, isFirstResource: Boolean): Boolean {
                            ivAvatar.visibility = View.VISIBLE
                            return false
                        }
                    })
                    .into(ivAvatar)
        }

        val acceptCallBtn = findViewById<ImageView>(R.id.ivAcceptCall)
        acceptCallBtn.setOnClickListener {
            FlutterIncomingCallPlugin.ringtonePlayer?.stop()
            acceptDialing()
        }
        val rejectCallBtn = findViewById<ImageView>(R.id.ivDeclineCall)
        rejectCallBtn.setOnClickListener {
            FlutterIncomingCallPlugin.ringtonePlayer?.stop()
            declineDialing()
        }

        val callPrefs = CallPreferences(this)
        val config = FlutterIncomingCallPlugin.config ?: callPrefs.config ?: FactoryModels.defaultConfig()
        if(FlutterIncomingCallPlugin.ringtonePlayer == null) {
            FlutterIncomingCallPlugin.ringtonePlayer = CallPlayer(this, config)
        }

        FlutterIncomingCallPlugin.ringtonePlayer?.let {
            if(!it.isPlaying()) it.play(callData)
        }
    }

    override fun onBackPressed() {
        // Don't back
    }

    private fun acceptDialing() {
        val intent = CallBroadcastReceiver.acceptIntent(this, callData)
        sendBroadcast(intent)

        finish()
    }

    private fun declineDialing() {
        val intent = CallBroadcastReceiver.declineIntent(this, callData)
        sendBroadcast(intent)

        finish()
    }

}