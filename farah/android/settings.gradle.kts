pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    
    // ✅ تم رفع إصدار Android Gradle Plugin (AGP) إلى 9.1.1 لحل مشكلة التوافق
    id("com.android.application") version "9.1.1" apply false
    
    // ✅ تم رفع إصدار Kotlin إلى 2.1.0 ليتوافق مع الـ AGP الجديد
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
