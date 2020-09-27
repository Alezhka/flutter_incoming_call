package com.github.alezhka.flutter_incoming_call

import android.content.Context
import com.google.gson.Gson

class CallPreferences(context: Context) {

    companion object {
        const val name = "flutter_incoming_call_plugin"

        const val PREFS_CONFIG = "PREFS_CONFIG"
    }

    private var gson: Gson = Gson()
    private val prefs = context.getSharedPreferences(name, Context.MODE_PRIVATE);

    var config: PluginConfig?
        get() {
            val raw = prefs.getString(PREFS_CONFIG, null)
            return raw?.let { gson.fromJson(it, PluginConfig::class.java) }
        }
        set(data) {
            prefs.edit().putString("config", gson.toJson(data)).apply()
        }
}