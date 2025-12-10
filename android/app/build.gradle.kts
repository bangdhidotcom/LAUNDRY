plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // TAMBAHAN WAJIB: Agar Firebase terbaca
    id("com.google.gms.google-services") 
}

android {
    // PERBAIKAN 1: Samakan dengan Firebase
    namespace = "com.example.laundry3b_user" 
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // PERBAIKAN 2: INI YANG PALING KRUSIAL! Harus sama persis dengan Firebase
        applicationId = "com.example.laundry3b_user" 
        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}