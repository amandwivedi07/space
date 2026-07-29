# App-specific keep rules. Flutter, Firebase and Play Services ship their own
# consumer rules, so this only needs what R8 cannot infer for this app.

# Reflection-based codecs used by the sign-in and messaging SDKs.
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations

# Keep the entry point Flutter looks up by name.
-keep class com.talkinspace.talkinspace.MainActivity { *; }
