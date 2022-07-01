package com.mdinstafbshare.md_insta_fb_share

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import com.facebook.share.model.ShareHashtag
import com.facebook.share.model.ShareMediaContent
import com.facebook.share.model.SharePhoto
import com.facebook.share.model.SharePhotoContent
import com.facebook.share.widget.ShareDialog
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** MdInstaFbSharePlugin */
class MdInstaFbSharePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var activity: Activity
    private lateinit var channel: MethodChannel
    private val kInstagramPackageName: String = "com.instagram.android"
    private val kFacebookPackageName: String = "com.facebook.katana"
    private val kTwitterPackageName: String = "com.twitter.android"



    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "md_insta_fb_share")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "share_insta_story" -> {
                if (checkAppInstalled(kInstagramPackageName)) {
                    val uri = try {
                        getPictureUri(call)
                    } catch (e : Exception) {
                        result.success(2)
                        return
                    }
                    val intent = Intent("com.instagram.share.ADD_TO_STORY")
                    intent.setDataAndType(uri, "image/*")
                    intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION

                    activity.startActivityForResult(intent, 0)
                    result.success(0)
                } else {
                    openMissingAppInPlayStore(kInstagramPackageName)
                    result.success(1)
                }
            }
            "share_insta_feed" -> {
                if (checkAppInstalled(kInstagramPackageName)) {
                    val uri = try {
                        getPictureUri(call)
                    } catch (e : Exception) {
                        result.success(2)
                        return
                    }

                    val intent = Intent("com.instagram.share.ADD_TO_FEED")
                    intent.type = "image/*"
                    intent.putExtra(Intent.EXTRA_STREAM, uri)

                    activity.grantUriPermission(
                            "com.instagram.android", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)

                    activity.startActivityForResult(intent, 0)
                    result.success(0)
                } else {
                    openMissingAppInPlayStore(kInstagramPackageName)
                    result.success(1)
                }
            }

            "share_FB_story" -> {
                if (checkAppInstalled(kFacebookPackageName)) {
                    val uri = try {
                        getPictureUri(call)
                    } catch (e : Exception) {
                        result.success(2)
                        return
                    }

                    val intent = Intent("com.facebook.stories.ADD_TO_STORY")
                    intent.setDataAndType(uri, "image/jpeg")
                    intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                    val metadata = activity.packageManager.getApplicationInfo(activity.packageName, PackageManager.GET_META_DATA).metaData
                    intent.putExtra("com.facebook.platform.extra.APPLICATION_ID", metadata.getString("com.facebook.sdk.ApplicationId"))

                    activity.startActivityForResult(intent, 0)
                    result.success(0)
                } else {
                    openMissingAppInPlayStore(kFacebookPackageName)
                    result.success(1)
                }

            }

            "share_FB_feed" -> {
                if (checkAppInstalled(kFacebookPackageName)) {
                    val uri = try {
                        getPictureUri(call)
                    } catch (e : Exception) {
                        result.success(2)
                        return
                    }

                    lateinit var shareDialog: ShareDialog

                    try {
                        shareDialog  = ShareDialog(activity)
                    }catch (e:Exception){
                        result.success(4)
                        return
                    }

                    val photo = SharePhoto.Builder().setImageUrl(uri).build()
                    val content = ShareMediaContent.Builder()
                        .addMedium(photo)
                        .setShareHashtag(
                            ShareHashtag.Builder()
                                .setHashtag("#Backstage_army")
                                .build()
                        ).build()

                    if (ShareDialog.canShow(SharePhotoContent::class.java)) {
                        shareDialog.show(content)
                        result.success(0)
                    }else{
                        result.success(4)
                    }
                } else {
                    openMissingAppInPlayStore(kFacebookPackageName)
                    result.success(0)
                }
            }

            "share_twitter_feed" -> {
                if (checkAppInstalled(kTwitterPackageName)) {
                    val uri = try {
                        getPictureUri(call)
                    } catch (e : Exception) {
                        result.success(2)
                        return
                    }
                    val captionText = call.argument<String>("captionText") ?: ""


                    val intent = Intent(Intent.ACTION_SEND)
                    intent.putExtra(Intent.EXTRA_TEXT, captionText)
                    intent.type = "text/plain"
                    intent.putExtra(Intent.EXTRA_STREAM, uri)
                    intent.type = "image/*"
                    intent.putExtra(Intent.EXTRA_STREAM, uri)
                    intent.setPackage(kTwitterPackageName)

                    activity.grantUriPermission(
                        kTwitterPackageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    activity.startActivityForResult(intent, 0)

                    result.success(0)
                } else {
                    openMissingAppInPlayStore(kTwitterPackageName)
                    result.success(1)
                }
            }

            "check_insta" -> result.success(checkAppInstalled(kInstagramPackageName))

            "check_FB" -> result.success(checkAppInstalled(kFacebookPackageName))

            "check_twitter" -> result.success(checkAppInstalled(kTwitterPackageName))

            else -> result.notImplemented()
        }
    }

    private fun getPictureUri(call: MethodCall): Uri {
        val path = call.argument<String>("backgroundImage") ?: ""

        return FileProvider.getUriForFile(activity, activity.packageName + ".mdInstaFbShare.provider", File(path))
    }

    private fun checkAppInstalled(packageName: String): Boolean {
        return try {
            activity.packageManager.getApplicationInfo(packageName, 0)

            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun openMissingAppInPlayStore(packageName: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.data = Uri.parse("market://details?id=$packageName")
        activity.startActivity(intent)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}
}
