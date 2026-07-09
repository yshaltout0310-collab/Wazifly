# R8 / ProGuard keep rules for the release build.
#
# Dart code is compiled AOT and tree-shaken by the Flutter toolchain, so these
# rules only cover the thin Android/Kotlin layer and its plugins. Most Firebase
# and Flutter plugins ship their own consumer rules; the entries below are
# defensive keeps + suppressions for classes R8 can't resolve at build time.

# --- Flutter embedding ------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Flutter's deferred-components loader references Play Core, which isn't bundled
# unless deferred components are used. Suppress the missing-class warnings.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# --- Firebase (Auth / Firestore / Storage / Messaging / Analytics /
#     Crashlytics / Performance / App Check / AI Logic) -----------------------
# Firebase ships consumer ProGuard rules; keep annotations + model constructors
# used reflectively, and don't warn on optional integrations.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics: keep source-file + line-number info for readable stack traces.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# --- Kotlin -----------------------------------------------------------------
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**

# --- App entry point --------------------------------------------------------
-keep class com.careerbridge.careerbridge.** { *; }
