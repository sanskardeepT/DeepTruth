# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class org.chromium.** { *; }

# Hive / Binary Serializers
-keep class io.hive.** { *; }
-keep class * extends io.hive.HiveObject { *; }

# AdMob (Google Mobile Ads)
-keep public class com.google.android.gms.ads.** { public *; }
-keep public class com.google.ads.** { public *; }

# Firebase / Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Support Library/AndroidX / Jetpack
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.**

# Keep generic signature information for reflection
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod
