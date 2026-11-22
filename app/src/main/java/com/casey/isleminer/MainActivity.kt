package com.casey.isleminer

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.webkit.JavascriptInterface
import android.webkit.WebView

class MainActivity : Activity() {

    private lateinit var web: WebView

    /** Save data lives in SharedPreferences; the game stores a timestamp for offline progress. */
    inner class Bridge {
        private val prefs = getSharedPreferences("isleminer", Context.MODE_PRIVATE)

        @JavascriptInterface
        fun save(json: String) {
            prefs.edit().putString("state", json).apply()
        }

        @JavascriptInterface
        fun load(): String = prefs.getString("state", "") ?: ""
    }

    @Suppress("DEPRECATION")
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        web = WebView(this).apply {
            setBackgroundColor(Color.parseColor("#0B2A3A"))
            settings.javaScriptEnabled = true
            addJavascriptInterface(Bridge(), "Android")
            setOnApplyWindowInsetsListener { v, ins ->
                v.setPadding(
                    ins.systemWindowInsetLeft,
                    ins.systemWindowInsetTop,
                    ins.systemWindowInsetRight,
                    ins.systemWindowInsetBottom
                )
                ins
            }
            loadUrl("file:///android_asset/index.html")
        }
        setContentView(web)
    }

    override fun onPause() {
        web.evaluateJavascript("window.saveNow && saveNow()", null)
        web.onPause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        web.onResume()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        moveTaskToBack(true)
    }
}
