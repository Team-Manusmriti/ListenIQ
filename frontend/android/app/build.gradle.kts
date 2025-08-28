plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // use correct kotlin plugin id
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.listeniq"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.listeniq"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true

        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    buildTypes {
    release {
        isMinifyEnabled = false   // or true in production
        isShrinkResources = false // must use "isShrinkResources"
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}



dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}
}

flutter {
    source = "../.."
}
