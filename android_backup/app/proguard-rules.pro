# WorkManager / Room 関連のクラスを難読化・削除から保護
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase
-keepclassmembers class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class *
-keep @androidx.room.Dao class *

# AndroidX Startup(InitializationProvider)関連
-keep class androidx.startup.** { *; }

# Google Mobile Ads SDK
-keep class com.google.android.gms.ads.** { *; }