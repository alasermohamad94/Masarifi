package com.example.masarifi

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

object ShareHelper {
    fun shareText(activity: MainActivity, text: String, chooserTitle: String) {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            putExtra(Intent.EXTRA_SUBJECT, "تقرير مصاريفي")
        }
        activity.startActivity(Intent.createChooser(intent, chooserTitle))
    }

    fun shareWhatsApp(activity: MainActivity, text: String) {
        val whatsappIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, text)
            setPackage("com.whatsapp")
        }

        try {
            activity.startActivity(whatsappIntent)
        } catch (_: ActivityNotFoundException) {
            val uri = Uri.parse("whatsapp://send?text=${Uri.encode(text)}")
            try {
                activity.startActivity(Intent(Intent.ACTION_VIEW, uri))
            } catch (_: ActivityNotFoundException) {
                shareText(activity, text, "مشاركة عبر واتساب")
            }
        }
    }

    fun shareCsvFile(
        activity: MainActivity,
        content: String,
        fileName: String,
        chooserTitle: String,
    ) {
        val file = File(activity.cacheDir, fileName)
        file.writeText(content, Charsets.UTF_8)

        val uri: Uri = FileProvider.getUriForFile(
            activity,
            "${activity.packageName}.fileprovider",
            file,
        )

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/csv"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, "تصدير بيانات مصاريفي")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(Intent.createChooser(intent, chooserTitle))
    }
}
