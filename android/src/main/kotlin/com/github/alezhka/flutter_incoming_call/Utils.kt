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
import android.os.PowerManager





object Utils {

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