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

# Standard Flutter rules
-dontwarn io.flutter.embedding.**
