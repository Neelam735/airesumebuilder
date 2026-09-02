# Google Play Billing — keep entry points used reflectively
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.gms.** { *; }

# in_app_purchase plugin
-keep class io.flutter.plugins.inapppurchase.** { *; }

# pdf / printing — keep PDF reflection
-keep class com.itextpdf.** { *; }
-dontwarn com.itextpdf.**

# Syncfusion PDF
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Razorpay checkout — the SDK calls these reflectively and drives the payment
# sheet through a JavaScript bridge, so they must survive minification or the
# checkout crashes in release builds.
-keepattributes *Annotation*
-keepattributes JavascriptInterface
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
-optimizations !method/inlining/*

# Standard Flutter rules
-dontwarn io.flutter.embedding.**
