# Regras padrão do Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Gotrue / Realtime usam reflection para serializar modelos
-keep class io.github.jan.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Google Play Core (split install / deferred components) - não usado neste app.
# Sem isso o R8 falha porque o Flutter referencia essas classes condicionalmente.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
