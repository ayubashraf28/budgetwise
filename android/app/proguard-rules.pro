# Flutter-specific ProGuard rules

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Supabase/GoTrue classes (for auth callbacks)
-keep class com.google.android.gms.** { *; }

# Keep Google Sign-In classes
-keep class com.google.android.gms.auth.** { *; }

# Prevent obfuscation of model classes used with JSON serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Keep notification receiver classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
