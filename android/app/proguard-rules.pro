# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter references Play Core split-install internally but this app doesn't use
# deferred components — suppress the missing class warnings to unblock R8
-dontwarn com.google.android.play.core.**

# Supabase / Ktor / OkHttp
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep model classes (JSON serialization)
-keepattributes Signature
-keepattributes *Annotation*
