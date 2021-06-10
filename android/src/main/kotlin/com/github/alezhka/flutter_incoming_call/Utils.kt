package com.github.alezhka.flutter_incoming_call

import android.annotation.TargetApi
import android.app.Activity
import android.app.KeyguardManager
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager


object Utils {

    fun isDeviceScreenLocked(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            isDeviceLocked(context)
        } else {
            isPatternSet(context) || isPassOrPinSet(context)
        }
    }

    /**
     * @return true if pattern set, false if not (or if an issue when checking)
     */
    private fun isPatternSet(context: Context): Boolean {
        val cr: ContentResolver = context.contentResolver
        return try {
            val lockPatternEnable: Int = Settings.Secure.getInt(cr, Settings.Secure.LOCK_PATTERN_ENABLED)
            lockPatternEnable == 1
        } catch (e: Settings.SettingNotFoundException) {
            false
        }
    }

    /**
     * @return true if pass or pin set
     */
    private fun isPassOrPinSet(context: Context): Boolean {
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager //api 16+
        return keyguardManager.isKeyguardSecure
    }

    /**
     * @return true if pass or pin or pattern locks screen
     */
    @TargetApi(Build.VERSION_CODES.M)
    private fun isDeviceLocked(context: Context): Boolean {
        val telMgr = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val simState = telMgr.simState
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager //api 23+
        return keyguardManager.isDeviceSecure && simState != TelephonyManager.SIM_STATE_ABSENT
    }

    /**
     * @return Main activity class. 
     */
    fun getMainActivityClass(context: Context): Class<*>? {
        val packageName = context.packageName
        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
        val className = launchIntent?.component?.className
        return try {
            className?.let{ Class.forName(it) }
        } catch (e: ClassNotFoundException) {
            e.printStackTrace()
            null
        }
    }

    /**
     * Back main activity to foreground.
     */
    fun backToForeground(applicationContext: Context, activity: Activity?) {
        /*
        val mainActivityIntent = Intent(context, getMainActivityClass(context)).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(mainActivityIntent)
        */

        val packageName = applicationContext.packageName
        val focusIntent = applicationContext.packageManager.getLaunchIntentForPackage(packageName)!!.cloneFilter()

        focusIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)

        if (activity != null) {
            activity.startActivity(focusIntent)
        } else {
            focusIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            applicationContext.startActivity(focusIntent)
        }

    }
}